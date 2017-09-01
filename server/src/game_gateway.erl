%%%--------------------------------------
%%% @Module  : game_gateway
%%% @Author  : sm
%%% @Created : 2010.09.18 
%%% @Description: 游戏网关
%%%--------------------------------------
-module(game_gateway).
-behaviour(gen_server).
-export([start_link/1,server_stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, 
		 chk_max_allow/0, set_max_allow/1]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-define(SIGN_EXPIRE_TIME, 20*60). %% 有效期默认为20分钟

-record(gatewayinit, {
	id = 1,				  	
	init_time = 0,
	async_time = 0,
	max_allow = 50000
    }).	
  
%%开启网关
%%Node:节点
%%Port:端口
start_link(Port) ->
	misc:write_system_info(self(), tcp_listener, {"", Port, now()}),	
    gen_server:start_link(?MODULE, [Port], []).

init([Port]) ->
	misc:write_monitor_pid(self(),?MODULE, {}),
    F = fun(Sock) -> handoff(Sock) end,
    game_gateway_server:stop(Port),  
    game_gateway_server:start_raw_server(Port, F, ?ALL_SERVER_PLAYERS),
	Now = unixtime(),
	Async_time = 
		case config:get_gateway_async_time() of
			undefined -> 0;
			Second -> Second
		end,
	ets:new(?ETS_ZIP_PROTO, [named_table, public, set,{read_concurrency,true}]),%%压缩协议ets表
	ets:new(gatewayinit, [{keypos, #gatewayinit.id}, named_table, public, set]), 
	ets:insert(gatewayinit,#gatewayinit{id = 1,init_time = Now,async_time = Async_time}),

	error_logger:info_msg("~s The center gateway is OK! . ~n", [misc:time_format(now())]),
%% 	%%开始统计进程
%% 	{ok, _Pid} = mod_statistics:start(),
    {ok, true}.

%%关闭服务器过程禁止刷进游戏
server_stop()-> 
	Now = unixtime(),
	ets:insert(gatewayinit,#gatewayinit{id = 1,init_time = Now,async_time = 100}).

handle_cast(_Rec, Status) ->
    {noreply, Status}.

handle_call(_Rec, _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Info, Status) ->
    {noreply, Status}.

terminate(normal, Status) ->
	misc:delete_monitor_pid(self()),
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
	{ok, Status}.

%%发送要连接的IP和port到客户端，并关闭连接
handoff(Socket) ->
    case gen_tcp:recv(Socket, ?HEADER_LENGTH) of
        {ok, <<Len:16, 60000:16>>} ->
            ?TRACE("~s get_msg_60000 ~n",[misc:time_format(now())]),
			%%延时允许客户端连接
			[{_,_,InitTime,AsyncTime,_MaxAllow}] = ets:match_object(gatewayinit,#gatewayinit{id =1 ,_='_'}),
			Now = unixtime(),

			BodyLen = Len - ?HEADER_LENGTH,
			case gen_tcp:recv(Socket, BodyLen, 3000) of
                {ok, <<Bin/binary>>} ->
					{ok, [_DomainId,Accid,Tstamp,Accname, StrKey]} = pt_60:read(60000, Bin),
					if
						Now - AsyncTime > InitTime  ->
							{ok, Data} = 
								case check_accid_legal(Accid, Tstamp, StrKey) of
									true ->
										List = mod_disperse:get_server_list(Accid,Accname),
										Pid = mod_disperse:get_mod_disperse_pid(),
										BusinessInfo = gen_server:call(Pid, get_content),
										if 
											BusinessInfo == undefined ->
												NewContent = "";
											true ->
												{BeginTime,EndTime,Content} = BusinessInfo,
												if
													Now >= BeginTime andalso Now =< EndTime ->
														NewContent = Content;
													true ->
														NewContent = ""
												end
										end,
										
			            				{ok, Data1} = pt_60:write(60000, [1, NewContent, List]);
									false ->
										{ok, Data2} = pt_60:write(60000, 0)  
								end,
							gen_tcp:send(Socket, Data),
		            		gen_tcp:close(Socket);
						true ->
							gen_tcp:close(Socket)
					end ;
                 _ ->
                    gen_tcp:close(Socket)
            end;
			
        {ok, <<Len:16, 60001:16>>} ->
            BodyLen = Len - ?HEADER_LENGTH,
            case gen_tcp:recv(Socket, BodyLen, 3000) of
                {ok, <<Bin/binary>>} ->
                    {Accname, _} = pt:read_string(Bin),
                    {ok, Data} = pt_60:write(60001, is_create(Accname)),
                    gen_tcp:send(Socket, Data),
                    handoff(Socket);
                 _ ->
                    gen_tcp:close(Socket)
            end;
        {ok, Packet} ->
            ?TRACE("~s get_msg: ~p ~n",[misc:time_format(now()),Packet]),
			P = tool:to_list(Packet),
			P1 = string:left(P, 4),
			if (P1 == "GET " orelse P1 == "POST") ->
				   P2 = string:right(P, length(P) - 4),
					misc_admin:treat_http_request(Socket, P2),
           		    gen_tcp:close(Socket);
				true ->
					gen_tcp:close(Socket)
			end;
        _Reason ->
            gen_tcp:close(Socket)	
    end.

%% 是否创建角色
is_create(Accname) ->  
    case db_agent:is_create(Accname) of
        [] ->
            0;
        _R ->
            1
    end.

%%查询服务器当前最大人数设置
chk_max_allow() ->
	[{_,_,_InitTime,_AsyncTime,MaxAllow}] = ets:match_object(gatewayinit,#gatewayinit{id =1 ,_='_'}),
	MaxAllow.

%%设置服务器当前最大人数设置
set_max_allow(Num)->
	[{_,_,InitTime,AsyncTime,_MaxAllow}] = ets:match_object(gatewayinit,#gatewayinit{id =1 ,_='_'}),
	ets:insert(gatewayinit,#gatewayinit{id = 1,
										init_time = InitTime,
										async_time = AsyncTime,
										max_allow = Num}).

unixtime()->
	{M, S, _} = erlang:now(),
    M * 1000000 + S.

%% 校验平台账号合法性
check_accid_legal(Accid, Tstamp, StrKey) ->
	?TRACE("Accid:~p, Tstamp:~p, StrKey:~p ~n", [Accid, Tstamp, StrKey]),
	case Tstamp < (unixtime() - ?SIGN_EXPIRE_TIME) of
		true -> false;
		false ->
			PlatformKey = config:get_platform_key(gateway),
			StrMd5Key = lists:concat([Accid, '&', Tstamp, '&', PlatformKey]),
%% 			?TRACE("StrMd5Key:~p ~n", [StrMd5Key]),
			StrMd5Val = util:md5(StrMd5Key),
%% 			?TRACE("key:~p signkey:~p ~n", [StrMd5Val, StrKey]),
			StrMd5Val =:= StrKey
	end.