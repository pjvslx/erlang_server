%%%-----------------------------------
%%% @Module  : pt
%%% @Author  : smxx_game
%%% @Created : 2010.10.05
%%% @Description: 协议公共函数
%%%-----------------------------------
-module(pt).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-export([read_string/1,pack/2, pack_string/1]).
%%读取字符串
read_string(Bin) ->
    case Bin of
        <<Len:16, Bin1/binary>> ->
            case Bin1 of
                <<Str:Len/binary-unit:8, Rest/binary>> ->
                    {binary_to_list(Str), Rest};
                _R1 ->
                    {[],<<>>}
            end;
        _R1 ->
            {[],<<>>}
    end.

pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

%% 打包信息，添加消息头 
pack(Cmd, Data) ->
%%	pack_stat(Cmd), 
	L = byte_size(Data) + 4,
	%pack_stat(Cmd), 发包统计 暂时注销
	%% 选择压缩的协议 
	IsListMem = check_is_compress(Cmd), 
	if 
		IsListMem =:= true -> %% 需要进行压缩		   
		   NewData = zlib:compress(Data),   
		   NL = byte_size(NewData) + 4,
		  % ?TRACE("Cmd ~p L:~p NL:~p ~n", [Cmd,L,NL]), 
		   <<NL:16, Cmd:16, NewData/binary>>;
	   true -> 
		   <<L:16, Cmd:16, Data/binary>>
	end.

check_is_compress(Cmd)->
	Flag = ets:lookup(?ETS_ZIP_PROTO, Cmd),
	Flag =/=[].

%% 统计输出数据包 
pack_stat(Cmd) ->  
	NewCount = case ets:lookup(proto_stat, Cmd) of
				   [{_, OldCount}] ->
					   OldCount+1;
				   _ ->
					   1
			   end,	
	ets:insert(proto_stat, {Cmd,NewCount}).
