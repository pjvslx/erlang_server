%% Author: Administrator
%% Created: 2013-4-8
%% Description: TODO: Add description to local_gateway_app
-module(local_gateway_app).

-behaviour(application).
-export([start/2, stop/1]).   
-include("common.hrl"). 

start(_Type, _Args) ->	
	[Port, _Acceptor_num, _Max_connections] = config:get_tcp_listener(local_gateway),
	LogPath = config:get_log_path(local_gateway),  
	LogLevel = config:get_log_level(local_gateway), 
	loglevel:set(tool:to_integer(LogLevel)),
	LogFile = lists:concat([LogPath, "/log"]),
	GameSvrNode = config:get_server_node(local_gateway),
	Md5Key = config:get_md5_key(local_gateway),
	case filelib:is_dir(LogPath) of
		true -> skip;
		false ->	file:make_dir(LogPath)
	end,
	
    local_gateway_sup:start_link([tool:to_integer(Port), LogFile, tool:to_integer(LogLevel)]).
 
stop(_State) ->   
    void.
