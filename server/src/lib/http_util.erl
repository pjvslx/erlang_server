%% Author: Administrator
%% Created: 2013-4-10
%% Description: TODO: Add description to http_util
-module(http_util).

-include("common.hrl").

-define(CONST_GM_KEY, testKey). % 验证码

%%
%% Exported Functions
%%
-export([check_ip/1, get_cmd_parm/1, get_param/2,get_param_lists/1]).

%%
%% API Functions
%%
%% 加入http来源IP验证 
check_ip(Socket) ->  
	MyIp = misc:get_ip(Socket),
	lists:any(fun(Ip) ->
			tool:to_binary(MyIp)=:=tool:to_binary(Ip) end,config:get_http_ips(local_gateway)).

get_cmd_parm(Packet) ->
%% 	Packet_list = string:to_lower(tool:to_list(Packet)),
	Packet_list = tool:to_list(Packet),
	try
		case string:str(Packet_list, " ") of
			0 -> no_cmd;
			N -> 
				CM = string:substr(Packet_list,2,N-2),
				case string:str(CM, "?") of
					0 -> [CM, ""];
					N1 -> 
						Cmd = string:substr(CM,1,N1-1),
						Param = string:substr(CM, N1+1),				 		
						KeyValue= key_value_list(Param),
						Md5Str	= get_params_string(KeyValue),
						{Cmd, KeyValue, Md5Str}
				end
		end
	catch
		_:_ -> no_cmd
	end.

%%获取所有请求参数列表
get_param_lists(Packet)->
	Packet_list = tool:to_list(Packet),
	try
		case string:str(Packet_list, " ") of
			0 -> no_cmd;
			N -> 	
				CM = string:substr(Packet_list,2,N-2),
				case string:str(CM, "?") of
					0 -> [];
					N1 -> 
						Param = string:substr(CM, N1+1),				 		
						key_value_list(Param)
				end
		end
	catch
		_:_ -> []
	end.

get_param(Key, KvList) ->
	case lists:keyfind(Key, 1, KvList) of
		false -> "";
		{Key, Val} -> http_lib:url_decode(Val)
	end.

%%
%% Local Functions
%%
%% 集合参数，凑出校验串
get_params_string(KvList) ->
	NewKvList = lists:usort(KvList),
	List2 = [begin lists:concat([Key, Value]) end || {Key, Value} <- NewKvList, Key /= "flag"],
	lists:concat(List2 ++ [config:get_md5_key(local_gateway)]).

%% 获取全部参数 Key-Value列表
key_value_list(Param) ->
    List = string:tokens(Param, "&"),
    [begin Data = string:tokens(X, "="),
           case Data of
               [Key] ->
                   {Key, ""};
               [Key, Value] ->
%% 				   ?INFO_MSG("key_value_list ~ts ~ts ~n", [Key, Value]),
%%  				   ?INFO_MSG("key_value_list ~ts ~ts ~n", [Key, http_lib:url_decode(Value)]),
				   {Key, Value}
           end
     end || X <- List]. 