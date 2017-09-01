%%%-----------------------------------
%%% @Module  : game_server_app
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 游戏服务器应用启动
%%%-----------------------------------
-module(game_server_app).
-behaviour(application).
-export([start/2, stop/1]).
-include("common.hrl").
-include("record.hrl").

start(normal, []) ->    
    ping_gateway(),
    
    ets:new(?ETS_SYSTEM_INFO, [set, public, named_table]),
    ets:new(?ETS_MONITOR_PID, [set, public, named_table]),
    ets:new(?ETS_STAT_SOCKET, [set, public, named_table]),
    ets:new(?ETS_STAT_DB, [set, public, named_table]),
    
    [Port, _Acceptor_num, _Max_connections] = config:get_tcp_listener(server),
    [Ip] = config:get_tcp_listener_ip(server),
	LogPath = config:get_log_path(server),
    LogLevel = config:get_log_level(server),
	Gateways = config:get_gateway_node(server),
	ServerNum = config:get_server_num(),  
	DbLogPath = config:get_db_log_path(),
	loglevel:set(tool:to_integer(LogLevel)),    
    {ok, SupPid} = game_server_sup:start_link(),
    game_timer:start(game_server_sup),
    game_server:start(
                  [Ip, tool:to_integer(Port), tool:to_integer(ServerNum),Gateways, LogPath, tool:to_integer(LogLevel),DbLogPath]
                ),
    {ok, SupPid}.

stop(_State) ->   
    void. 

ping_gateway()->
    case config:get_gateway_node(server) of
        undefined -> no_action;
        DataList ->    
			Fun = fun(GatewayNode) ->
						  catch net_adm:ping(GatewayNode)
				  end ,
			lists:foreach(Fun, DataList)
    end.



