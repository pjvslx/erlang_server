%%%------------------------------------
%%% @Module  : mod_disperse
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 游戏服务器路由器
%%%------------------------------------
-module(mod_disperse).
-behaviour(gen_server).
-compile(export_all).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, get_mod_disperse_pid/0]).
-include("common.hrl").
-include("record.hrl").
-define(ONLINE_STATIS_TIMER, 5*60*1000).
-define(FRESH_SERVER_TIMER, 1*60*1000).   %%5分钟加载一下数据
-define(SERVER_STATE_HOT,2) .
-define(SERVER_STATE_RECOM,3) .
-define(SERVER_STATE_MAINT,4) .
-define(DOMAIN_NUM,200).
%% ====================================================================
%% 对外函数
%% ====================================================================

start_link(Ip, Port, Node_id,Gateways) ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [Ip, Port, Node_id,Gateways], []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Ip, Port, ServeId, Gateways]) ->
    State = #server{id = ServeId, ip = Ip, port = Port, node = node(), state = ?SERVER_STATE_HOT, stop_access = 0} ,
	case ServeId =:= 0 of  
		true ->		
			net_kernel:monitor_nodes(true) , 
			ets:new(?ETS_SERVER, [{keypos, #server.id}, named_table, public, set]),
			ets:new(config_server,[{keypos, #config_server.id}, named_table, public, set]) ,
			lists:foreach(fun(D) ->
								  ets:new(misc:create_atom(server_player, [D]), [{keypos, #server_player.uid}, named_table, public, set]) 
						  end, lists:seq(1, ?DOMAIN_NUM)) ,  %% 200个大区够用了吧
			load_server_config() ,
			load_server_nodes() ,
			load_latest_business_announce(),%%查询出最新的公告消息 添加到进程字典
			erlang:send_after(5 * ?FRESH_SERVER_TIMER , self(), {event, load_server}) ,
			erlang:send_after(?FRESH_SERVER_TIMER, self(), {event, refresh_server_player}) ;
		false ->	
			statis_server_load(State,Gateways) ,
			erlang:send_after(?ONLINE_STATIS_TIMER, self(), {fetch_node_load,Gateways})
	end ,
    misc:write_monitor_pid(self(),?MODULE, {}),
    {ok, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({update_server_state, Server} , State) ->
	case ets:lookup(?ETS_SERVER, Server#server.id) of
		[OldServer|_] when is_record(OldServer,server) ->
			NewServer = OldServer#server{num = Server#server.num, state = Server#server.state} ;
		_ ->
			NewServer = Server#server{num = Server#server.num} 
	end ,
	ets:insert(?ETS_SERVER, NewServer) ,
	spawn(fun() -> db_agent:add_server(NewServer) end ) ,
    {noreply, State};


handle_cast({update_server_player, ServPlayer} , State) ->
	EtsName = misc:create_atom(server_player, [ServPlayer#server_player.domain]) ,
	case ets:lookup(EtsName, ServPlayer#server_player.uid) of
		[Player|_] when is_record(Player,server_player) ->
			NewPlayer = Player#server_player{last_login = ServPlayer#server_player.last_login ,
											 career = ServPlayer#server_player.career ,
											 sex = ServPlayer#server_player.sex ,
											 lv = ServPlayer#server_player.lv } ,
			spawn(fun() ->db_agent:update_server_player(NewPlayer) end) ;
		_ ->
			NewPlayer = ServPlayer ,
			spawn(fun() ->db_agent:add_server_player(NewPlayer) end) 
	end ,
	ets:insert(EtsName, NewPlayer) ,
	{noreply, State} ;



handle_cast(_R , State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call('get_server_list',_From,State) ->
    {reply,ok,State};

handle_call(get_content,_From,State) ->
	Content = get(business_content),
	{reply,Content,State};

handle_call(_R , _FROM, State) ->
    {reply, ok, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({event, load_server}, State) ->
	load_server_config() ,
    load_server_nodes(),
	erlang:send_after(?FRESH_SERVER_TIMER , self(), {event, load_server}) ,
    {noreply, State};


handle_info({event, refresh_server_player}, State) ->
	%%load_server_config() ,
    %%load_server(State),
	load_server_player() ,
    {noreply, State}; 


handle_info({fetch_node_load,Gateways},State) ->
	statis_server_load(State,Gateways) ,
    erlang:send_after(?ONLINE_STATIS_TIMER, self(), {fetch_node_load}),
    {noreply,State};


handle_info({nodedown, Node}, State) ->
	case ets:match_object(?ETS_SERVER, #server{node = Node, _ = '_'}) of
		[Server|_] ->
			case net_adm:ping(Server#server.node) of
				pong ->
					skip ;
				pang ->
					NewServer = Server#server{state = ?SERVER_STATE_MAINT} ,
					ets:insert(?ETS_SERVER, NewServer) ,
					spawn(fun() -> db_agent:add_server(NewServer) end ) 
			end ;
		_ ->
			skip
	end ,
	{noreply, State};


handle_info(_Reason, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_R, State) ->
    misc:delete_monitor_pid(self()),
    {ok, State}.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra)->
    {ok, State}.


%% ----------------------- 私有函数 ---------------------------------
server_list() ->
    ets:tab2list(?ETS_SERVER).

update_server_state(Server) ->
	gen_server:cast(?MODULE, {update_server_state, Server}) . 
	
update_server_player(ServPlayer) ->
	gen_server:cast(?MODULE, {update_server_player, ServPlayer}) . 

load_server_nodes() ->
	case db_agent:select_all_server() of
		[] ->
			[];
		ServerList ->
			F = fun(Server) ->
						case net_adm:ping(Server#server.node) of
							pong ->
								case Server#server.stop_access =:= 0 andalso Server#server.state > ?SERVER_STATE_RECOM of
									true ->
										NewServer = Server#server{ state = ?SERVER_STATE_RECOM } ;
									false ->
										NewServer = Server
								end ,
								case Server#server.id /= 0 of
									true ->
										ets:insert(?ETS_SERVER, NewServer) ;
									false ->
										ok
								end ;
							pang ->
								case Server#server.stop_access =:= 2 of
									true ->
										db_agent:del_server(Server#server.id) ;
									false ->
										ets:insert(?ETS_SERVER, Server) 
								end 
						end 
				end,
			[F(S) || S <- ServerList]
	end .


load_server_config() ->
	case db_agent:select_config_server() of
		[] ->
			skip ;
		DataList ->
			Fun = fun(ScRcd) ->
						  ets:insert(config_server, ScRcd) 
				  end ,
			lists:foreach(Fun, DataList)
	end .


load_server_player() ->
	case db_agent:select_server_player() of
		[] ->
			skip ;
		DataList ->
			Fun = fun(ServPlayer) ->
						  EtsName = misc:create_atom(server_player, [ServPlayer#server_player.domain]) ,
						  ets:insert(EtsName, ServPlayer) 
				  end ,
			lists:foreach(Fun, DataList)
	end .


statis_server_load(State,Gateways) ->
	PlayerNum = ets:info(?ETS_ONLINE,size) ,
	if
		PlayerNum > 1000 ->
			SvrSts = ?SERVER_STATE_HOT ;
		true ->
			SvrSts = ?SERVER_STATE_RECOM 
	end ,
	OpenTime = config:get_opening_time() ,
	Domain = config:get_domain() ,
	Server = State#server{num = PlayerNum, domain = Domain, start_time = OpenTime , state = SvrSts , stop_access = 0 } ,
	upload_to_gateway(Server,Gateways) .



get_server_list(AccId,_AccName) ->  
	ServList = ets:tab2list(?ETS_SERVER) ,
	RServList = get_server_list(AccId,ServList,0,[],[]) ,
	lists:reverse(lists:keysort(1, RServList)) .

get_server_list(_AccId,[],_PreDomain,RServList,_ServPlayerList) ->
	RServList ;
get_server_list(AccId,[Server|LeftServerList],PreDomain,ServList,PlayerList) ->
	Name = get_server_name(Server#server.id) ,
	case Server#server.domain =/= PreDomain of
		true ->
			NewDomain = Server#server.domain ,
			EtsName = misc:create_atom(server_player, [Server#server.domain]) ,
			NewPlayerList = ets:match_object(EtsName, #server_player{accid = AccId, _='_'}) ;
		false ->
			NewDomain = PreDomain ,
			NewPlayerList = PlayerList
	end ,
	case NewPlayerList of
		[] ->
			[Career,Sex,Level,Nick] = [0,0,0,[]] ;
		_ ->
			ServPlayerList = 
				[{SP#server_player.career,SP#server_player.sex,SP#server_player.lv,SP#server_player.nick} 
				 || SP <- NewPlayerList , SP#server_player.accid =:= AccId , SP#server_player.serv_id =:= Server#server.id] ,
			case ServPlayerList of
				[] ->
					[Career,Sex,Level,Nick] = [0,0,0,[]] ;
				_ ->
					[{Career,Sex,Level,Nick}|_] = ServPlayerList
			end 
	end ,
	NewServList = [{Server#server.id,Server#server.domain,Name,Server#server.ip,Server#server.port,Server#server.state,Career,Sex,Level,Nick}|ServList] ,
	get_server_list(AccId,LeftServerList,NewDomain,NewServList,NewPlayerList) .
	
get_server_name(ServId) ->
	case ets:lookup(config_server, ServId) of
		[SCRcd|_] when is_record(SCRcd,config_server) ->
			SCRcd#config_server.name ;
		_ ->
			[]
	end .


%% 获取服务器的负载
get_nodes_cmq(Type)->
	A = lists:foldl( 
		  fun(P, Acc0) -> 
				  case Type of
					  1 ->
						  [{P, 
							erlang:process_info(P), 
							erlang:process_info(P, reductions) }
							   | Acc0] ;
					  2 ->
						  [{P,
							erlang:process_info(P, registered_name), 
							erlang:process_info(P, memory)}
							   | Acc0] ;
					  3 ->
						  [{P, 
							erlang:process_info(P, registered_name), 
							erlang:process_info(P, message_queue_len)} 
							   | Acc0] 
				  end
		  end, 
		  [], 
		  erlang:processes()
				   ),
	%%B = io_lib:format("~p", [A]),
	A .

%%本服务器尝试解析获取进程信息
get_process_info(Pid_list) ->
	try
		Pid = list_to_pid(Pid_list),
		Pinfo = process_info(Pid),
		%%file:write_file("info.txt", io_lib:format("~p", Pinfo)),
		Pinfo
	catch
		_:E ->
			E
	end.


upload_to_gateway(Server,Gateways)  ->
	Fun = fun(Gateway) ->
				  case net_adm:ping(Gateway) of
					  pong ->
						  rpc:cast(Gateway, ?MODULE, update_server_state, [Server]) ;
					  pang ->
						  skip
				  end 
		  end ,
	lists:foreach(Fun, Gateways) .
	

stop_server(ServId) ->
	case ets:match_object(?ETS_SERVER, #server{node = node(), _ = '_'}) of
		[_GWNode|_] ->
			skip ;
		_ ->
			case ets:lookup(ets_server, ServId) of
				[Server|_] when is_record(Server,server) ->
					case net_adm:ping(Server#server.node) of
						pong ->
							rpc:cast(Server#server.node, misc_admin, safe_quit, []) ;
						pang ->
							skip
					end ;
				_ ->
					skip
			end 
	end .


stop_access(ServId) ->
	case ets:match_object(?ETS_SERVER, #server{node = node(), _ = '_'}) of
		[_GWNode|_] ->
			skip ;
		_ ->
			case ets:lookup(ets_server, ServId) of
				[Server|_] when is_record(Server,server) ->
					NewServer = Server#server{stop_access = 1} ,
					update_server_state(NewServer) ;
				_ ->
					skip
			end 
	end .
	

start_access(ServId) ->
	case ets:match_object(?ETS_SERVER, #server{node = node(), _ = '_'}) of
		[_GWNode|_] ->
			skip ;
		_ ->
			case ets:lookup(ets_server, ServId) of
				[Server|_] when is_record(Server,server) ->
					NewServer = Server#server{stop_access = 0} ,
					update_server_state(NewServer) ;
				_ ->
					skip
			end 
	end .


sync_player_to_gateway(Status) ->
	Gateways = config:get_gateway_node(server) ,
	ServNum = config:get_server_num() ,
	Domain = config:get_domain() ,
	Fun = fun(Gateway) ->
				  case net_adm:ping(Gateway) of
					  pong ->
						  ServPlayer = #server_player{uid = Status#player.id ,
													  accid = Status#player.account_id ,
													  serv_id = ServNum ,
													  domain = Domain ,
													  acc_name = Status#player.account_name ,
													  nick = Status#player.nick ,
													  sex = Status#player.gender ,
													  career = Status#player.career ,
													  lv = Status#player.level ,
													  icon = Status#player.icon ,
													  last_login = util:unixtime()
													  } ,
						  rpc:cast(Gateway, ?MODULE, update_server_player, [ServPlayer]) ;
					  pang ->
						  skip
				  end 
		  end ,
	lists:foreach(Fun, Gateways) .

load_latest_business_announce() ->
	BusinessInfo = db_agent:select_latest_business_announce(),
	if
		BusinessInfo == [] ->
			skip;
		true ->
			put(business_content,{BusinessInfo#business_announce.begin_time,BusinessInfo#business_announce.end_time,BusinessInfo#business_announce.content})
	end.
get_mod_disperse_pid() ->
  misc:whereis_name({local,mod_disperse}).


%% get_latest_business_announce() ->
%% 	BusinessInfo = ets:l(?ETS_BUSINESS_ANNOUNCE),
%% 	BusinessInfo.

	








