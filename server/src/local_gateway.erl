%% Author: Administrator
%% Created: 2013-4-8
%% Description: TODO: Add description to local_gateway
-module(local_gateway).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-define(MAX_ACCEPT_NUM, 10). % 最大连接数
-define(NO_RIGTH_CODE, <<"no_right">>).			% 没有权利

%%开启本地网关
%%Node:节点
%%Port:端口
start_link(Port) ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [Port], []).

init([Port]) -> 
	misc:write_system_info(self(), ?MODULE, {"", Port, now()}),
	F = fun(Sock) -> handoff(Sock) end,
    local_gateway_server:stop(Port), 
    local_gateway_server:start_raw_server(Port, F, ?MAX_ACCEPT_NUM),
	ets:new(config_info, [named_table, public, set]), 
	record_config_info(), 
    {ok, true}.

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
		{ok, Packet} ->
			case http_util:check_ip(Socket) of
				true ->
					P = tool:to_list(Packet),
					P1 = string:left(P, 4), 
					if (P1 == "GET " orelse P1 == "POST") ->
						   P2 = string:right(P, length(P) - 4),
						   lib_charge:do_respone(Socket, P2),
						   gen_tcp:close(Socket);
					   true ->
						   gen_tcp:close(Socket)
					end;
				false -> 
					io:format("ip check fail ~n"),
					gen_tcp:send(Socket, ?NO_RIGTH_CODE),
					gen_tcp:close(Socket)
			end;
		_Reason ->
			gen_tcp:close(Socket)
	end.
%%记录配置信息
record_config_info()->
	case config:get_server_node(?MODULE) of
		''->
			skip;
		Node -> 
			ets:insert(config_info, {game_server_node,Node})
	end, 
	case config:get_charge_key(?MODULE) of
		''->
			skip;
		Key -> 
			ets:insert(config_info, {charge_key,Key})
	end .
			