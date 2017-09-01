-module(config). 
-include("record.hrl").
-include("common.hrl").
-include_lib("stdlib/include/ms_transform.hrl"). 

-compile(export_all).

%% 获取 .config里的配置信息
get_log_path(App) ->
    case application:get_env(App, log_path) of
	{ok, LogPath} -> LogPath;
	_ -> "logs"
    end.

%% 获取 .config里的配置信息
get_log_level(App) ->
    case application:get_env(App, log_level) of
	{ok, LogLevel} -> LogLevel;
	_ -> 3
    end.

%% 获取 .config里的配置信息
get_server_node(App) ->
    case application:get_env(App, game_server_node) of
	{ok, Node} -> Node;
	_ -> ''
    end.
%% 获取平台重置的key
get_charge_key(App) ->
    case application:get_env(App, charge_key) of
	{ok, Node} -> Node;
	_ -> ''
    end.

%% 获取 .config里的配置信息
get_md5_key(App) ->
    case application:get_env(App, md5_key) of
	{ok, Node} -> Node;
	_ -> ''
    end.

%% 获取 .config里的配置信息
get_platform_key(App) ->
	 case application:get_env(App, platform_key) of
	{ok, Node} -> Node;
	_ -> ''
    end.

get_infant_ctrl(App) ->
%% 防沉迷开关读取
    case application:get_env(App, infant_ctrl) of
	{ok, Mode} -> tool:to_integer(Mode);
	_ -> 0
    end.

get_tcp_listener(App) ->
    case application:get_env(App, tcp_listener) of
 	{ok, false} -> throw(undefined);
	{ok, Tcp_listener} -> 
		try
			{_, Port} = lists:keyfind(port, 1, Tcp_listener),
			{_, Acceptor_num} = lists:keyfind(acceptor_num, 1, Tcp_listener),
			{_, Max_connections} = lists:keyfind(max_connections, 1, Tcp_listener),
			[Port, Acceptor_num, Max_connections]
		catch
		 	_:_ -> exit({bad_config, {server, {tcp_listener, config_error}}})
		end;
 	undefined -> throw(undefined)
    end.

get_tcp_listener_ip(App) ->
    case application:get_env(App, tcp_listener_ip) of
 	{ok, false} -> throw(undefined);
	{ok, Tcp_listener_ip} -> 
		try
			{_, Ip} = lists:keyfind(ip, 1, Tcp_listener_ip),
			[Ip]
		catch
		 	_:_ -> exit({bad_config, {server, {tcp_listener, config_error}}})
		end;
 	undefined -> throw(undefined)
    end.

get_mysql_config(App) ->
    case application:get_env(App, mysql_config) of
 	{ok, false} -> throw(undefined);
	{ok, Mysql_config} -> 
					{_, Host} = lists:keyfind(host, 1, Mysql_config),
					{_, Port} = lists:keyfind(port, 1, Mysql_config),
					{_, User} = lists:keyfind(user, 1, Mysql_config),
					{_, Password} = lists:keyfind(password, 1, Mysql_config),
					{_, DB} = lists:keyfind(db, 1, Mysql_config),
					{_, Encode} = lists:keyfind(encode, 1, Mysql_config),
					{_, Conns} = lists:keyfind(conns, 1, Mysql_config),
					[Host, Port, User, Password, DB, Encode,Conns];		
 	undefined -> throw(undefined)
    end.

get_mysql_log_config(App) ->
    case application:get_env(App, mysql_log_config) of
 	{ok, false} -> throw(undefined);
	{ok, Mysql_config} -> 
					{_, Host} = lists:keyfind(host, 1, Mysql_config),
					{_, Port} = lists:keyfind(port, 1, Mysql_config),
					{_, User} = lists:keyfind(user, 1, Mysql_config),
					{_, Password} = lists:keyfind(password, 1, Mysql_config),
					{_, DB} = lists:keyfind(db, 1, Mysql_config),
					{_, Encode} = lists:keyfind(encode, 1, Mysql_config),
					{_, Conns} = lists:keyfind(conns, 1, Mysql_config),
					[Host, Port, User, Password, DB, Encode,Conns];		
 	undefined -> throw(undefined)
    end.

get_mongo_config(App) ->
    case application:get_env(App, emongo_config) of
 	{ok, false} -> throw(undefined);
	{ok,Emongo_config} -> 
					{_, PoolId} = lists:keyfind(poolId, 1, Emongo_config),
					{_, EmongoSize} = lists:keyfind(emongoSize, 1, Emongo_config),
					{_, EmongoHost} = lists:keyfind(emongoHost, 1, Emongo_config),
					{_, EmongoPort} = lists:keyfind(emongoPort, 1, Emongo_config),
					{_, EmongoDatabase} = lists:keyfind(emongoDatabase, 1, Emongo_config),
					[PoolId, EmongoHost, EmongoPort, EmongoDatabase, EmongoSize];		
 	undefined -> throw(undefined)
    end.

get_slave_mongo_config(App) ->
    case application:get_env(App, slave_emongo_config) of
 	{ok, false} -> throw(undefined);
	{ok,Emongo_config} -> 
					{_, PoolId} = lists:keyfind(poolId, 1, Emongo_config),
					{_, EmongoSize} = lists:keyfind(emongoSize, 1, Emongo_config),
					{_, EmongoHost} = lists:keyfind(emongoHost, 1, Emongo_config),
					{_, EmongoPort} = lists:keyfind(emongoPort, 1, Emongo_config),
					{_, EmongoDatabase} = lists:keyfind(emongoDatabase, 1, Emongo_config),
					[PoolId, EmongoHost, EmongoPort, EmongoDatabase, EmongoSize];		
 	undefined -> get_mongo_config(App)
    end.

has_slave_mongo_config() ->
	case application:get_env(server, slave_emongo_config) of
		{ok, false} -> false;
		{ok, _Emongo_config} -> true
	end.

get_read_data_mode(App) ->
    case application:get_env(App, base_data_from_db) of
	{ok, Mode} -> tool:to_integer(Mode);
	_ -> 0
    end.

get_gateway_node(App) ->
    case application:get_env(App, gateway_node) of
	{ok, Gateway_node} -> Gateway_node;
	_ -> undefined
    end.

get_gateway_async_time() ->
	case application:get_env(gateway,gateway_async_time) of
	{ok,Async_time} ->Async_time;
		_ ->undefined
	end.


get_scene_here(App) ->
    case application:get_env(App, scene_here) of
		undefined -> [];
		{ok, all} -> 
   			MS = ets:fun2ms(fun(S) when S#temp_scene.type =< 3 ->  S#temp_scene.sid end),
   			ets:select(?ETS_TEMP_SCENE, MS);
		{ok, SL} when is_list(SL) -> 
			SL1 = lists:filter(fun(SId) ->
    						case ets:lookup(?ETS_TEMP_SCENE, SId) of
        						[] ->	false;
        						[S] ->
            						if S#temp_scene.type =< 3 ->
										   true;
									   true -> 
										   false
									end
							end
						end,
						SL),
			SL1;
		_ -> []
    end.

get_guest_account_url(App) ->
    case application:get_env(App, guest_account_url) of
			{ok, Guest_account_url} -> Guest_account_url;
	_ -> ""
    end.	
 
%% GM指令开关读取
get_can_gmcmd() ->
	case application:get_env(server, can_gmcmd) of
		{ok, Mode} -> tool:to_integer(Mode);
		_ -> throw(undefined)
    end.

get_strict_md5(App) ->
    case application:get_env(App, strict_md5) of
			{ok, Strict_md5} -> Strict_md5;
	_ -> 1
    end.  	

get_http_ips(App) ->
    case application:get_env(App, http_ips) of
			{ok, Http_ips} -> Http_ips;
	_ -> []
    end.  	
  
%% 获取 .config里的配置信息
get_server_number(App) ->
    case application:get_env(App, server_number) of
	{ok, Server_number} -> 
		case is_integer(Server_number) == true of
			false -> 0;
			true -> Server_number
		end;
	_ -> 0
    end.

%% 获取 .config里的配置信息
get_max_id(App) ->
    case application:get_env(App, max_id) of
	{ok, Max_id} -> 
		case is_integer(Max_id) == true of
			false -> 0;
			true -> Max_id
		end;
	_ -> 0
    end.

%% 获取平台名称
get_platform_name() ->
	case application:get_env(server,platform) of
		{ok,Name} ->
			Name;
		_ ->
			undefined
	end.
%% 获取加密串号
get_card_key()	->
	case application:get_env(server,card_key) of
		{ok,Crypto} ->
			Crypto;
		_ ->
			undefined
	end.

%% 获取服号
get_server_num()->
	case application:get_env(server,server_num) of
		{ok,N} ->
			N;
		_ ->
			undefined
	end.

%%获取数据库日志路径
get_db_log_path()->
	case application:get_env(server,db_log_path) of
		{ok,N} ->
			N;
		_ ->
			undefined
	end.

%%获取开服时间
get_opening_time()->
	case application:get_env(server,open_time) of
		{ok,N}->
			N;
		_ ->
			0
	end.


%%获取节点1的id
get_domain()->
	case application:get_env(server,domain) of
		{ok,N}->
			N;
		_ ->
			1
	end.


%%获取节点2的id
get_node_id_2()->
	case application:get_env(server,node_id_2) of
		{ok,N}->
			N;
		_ ->
			2
	end.

%%获取客户端操作系统
get_client_os(Os)->
	case Os of
		1->
			<<"Android">>;
		2->
			<<"iphone">>;
		_->
			<<"未知">>
	end.
%%获取客户端设备类型
get_client_device_type(DeviceType)->
	case DeviceType of
		1-><<"Android">>;
		2-><<"iphone">>;
		3-><<"ipad">>;
		_-><<"未知">>
	end.
%%获取客户端移动网络类型
get_client_isp(Isp)->
	case Isp of
		1-><<"中国移动">>;
		2-><<"中国电信">>;
		3-><<"中国联通">>;
		_->"未知"
	end.
%%获取客户端上网方式
get_client_net_type(Net)->
	case Net of
		1-><<"3G">>;
		2-><<"WIFI">>;
		3-><<"2G">>;
		_-><<"未知">>
	end.