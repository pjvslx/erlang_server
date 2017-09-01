%%% -------------------------------------------------------------------
%%% Author:     SMXX
%%% Description : 机器人
%%% Created :
%%% -------------------------------------------------------------------
-module(robot).
-behaviour(gen_server).
-include("robot.hrl").

-compile(export_all).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(START_ROBOT_GOODS, false).

%%%  
%%% API
  
start()->  
    start([1,1500, ?SERVER_PORT, ?SERVER_ADD]), % 默认端口 IP 
    ok. 

%%StartId 起始AccountID
%%Num int 数量
%%Mod 跑步模式 1 ,2 指定端口和ip  
start([StartId0, Num0, Port0, IP0]) ->  
   
    io:format("--Start"),
	StartId = list_to_integer(atom_to_list(StartId0)),
	Num = list_to_integer(atom_to_list(Num0)),
	Port = list_to_integer(atom_to_list(Port0)),
	IP = atom_to_list(IP0),
    %io:format("--StartId:~p, Num:~p, Port:~p, IP:~p ~n",[StartId, Num, Port, IP]),
	ets:new(?ETS_ZIP_PROTO, [named_table, public, set,{read_concurrency,true}]),		%%压缩协议ets表
	ets:new(player_mon_info, [named_table, public, set,{read_concurrency,true}]),		%%压缩协议ets表
	ets:new(off_line_static, [named_table, public, set,{read_concurrency,true}]),
	ets:insert(off_line_static,{1,0}),
	ets:insert(off_line_static,{2,0}),
	io:format("--StartId:~p, Num:~p, Port:~p, IP:~p ~n",[StartId, Num, Port, IP]),
    sleep(500),
    F=fun(N)->
         io:format("start robot-~p~n",[N]),
         sleep(150),
         robot:start_link(N, Port, IP)
         %io:format("----start robot-~p end ~n",[N])
    end,
    MaxNum = Num+StartId,
    for(StartId,MaxNum,F),
	[{_,NUM}]=ets:lookup(off_line_static,2),
	io:format("start finish total attr ~p ~n",[NUM]),
    keep_alive().

keep_alive()->
	   sleep(100000),
	   keep_alive().
 
%%创建 一个ROBOT 进程
start_link(N, Port, IP)->
    io:format("--N:~p, Port:~p, IP:~p ~n",[ N, Port, IP]),
    case gen_server:start(?MODULE,[N, Port, IP],[]) of
        {ok, Pid}->
            io:format("--robot~p start finish!-~n",[N]),
			case ?START_ROBOT_GOODS of
				true ->
					gen_server:cast(Pid, {startGoodsTest});
				_ ->
					ok
			end,
            %gen_server:cast(Pid, {start_action});
			Pid,
			ok;
        _->
            io:format("--robot error!-~n"),
            fail
    end.

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
%%初始化玩家数据  
init([N, Port, IP]) ->
	io:format("**********200130916 001 robot init N=~p,Port=~p,IP=~p ~n", [N,Port,IP]),
    process_flag(trap_exit,true),
    Pid = self(),
	case login(N, Pid, Port, IP) of   
		{ok, Socket}->		
			random:seed(erlang:now()),
			Flag = random:uniform(2),  
			io:format("--robot init ~p start finish! runing ~p -~n",[N,Flag>1]) , 
			if Flag >1 ->
				   [{_,NUM}]=ets:lookup(off_line_static,2),
				   ets:insert(off_line_static, {2,NUM+1}),
				   Act = run;
			   true ->
				   Act = other
			end,
			Scene = 10101,
            Robot= #robot{socket = Socket, 
                          login = 0,
                          acid = N, 
                          id = 0, 
                          pid = Pid,
                          act = chat,%%任务压测
                          status = none,
                          scene = Scene,
                          dstScene = Scene,  
                          tox = rand(1,40),
                          toy = rand(1,20),
                          orig_n = N,
                          step = 0,
                          guild = 0,
                          guild_post = 0, 
                          frda = [], %% 好友信息
                          bkda = [], %% 黑名单信息,
                          sgda = []  %% 陌生人信息  
                         },
            %%登陆成功后开始动作
			io:format("**********200130916 002 robot init finish ~n"),
			case ?START_ROBOT_GOODS of
				true ->
					NewRobot = Robot#robot{act = test_goods};
				_ ->
					NewRobot = Robot
			end,
			{ok,NewRobot};
        _Error ->
			?TRACE("init: error, reason: ~p~n",[_Error]),
			{stop, normal, {}}
	end.

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
handle_call({get_state},_From,State)->
    {reply,State,State};

%%更新玩家的任务列表信息（模拟前端）
handle_call({upgrade_state_30006,TaskList},_From,State) ->
    io:format("VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV:::~p~n",[TaskList]),
	NewState = State#robot{task_list=TaskList},
    {reply,State,NewState};

%%处理模块发到某个模块的消息
handle_call({Mod, Msg}, _From, State) ->
    case lists:member(Mod, ?RANDOM_MODULE) of
        true ->
            Module = list_to_atom(lists:concat(["robot_", Mod])),
            case catch Module:handle_call(State, Msg) of
                {reply, Reply, NewState} when is_record(NewState, robot) ->
                    {reply, Reply, NewState};
                _  -> 
                    {reply, noreply, State}
           end;
        false ->
           ?TRACE("Error cast call: Mod:~p Msg: ~p~n", [Mod, Msg]),
           {reply, error, State}
    end;

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({login_ok, _Code}, State) ->
    ?TRACE("login successful~n"),
    NewState = State#robot{login = 1},
    {noreply, NewState};

handle_cast(login_failed, State)->
    ?TRACE("login failed~n"),
    {stop, normal, State};

handle_cast(startGoodsTest, State) ->
	io:format("******20130916 robot handle_cast startGoodsTest socket = ~p~n ~n", [State#robot.socket]),
	Pid= self() ,
	spawn_link(fun()-> ai(Pid) end), 
    {noreply, State};

handle_cast(enter_ok, State)-> 
	io:format("========enter_ok:~p ~p~n", [State#robot.act,State#robot.status]) , 
    robot_task:handle(get_task,{},State#robot.socket),%%获取任务列表
	gen_tcp:send(State#robot.socket, pack(21000, <<>>)),
    gen_server:cast(self(), {start_action}),
    {noreply, State};

handle_cast({playerid, Id}, State)->
    NewState = State#robot{id = Id},
    {noreply, NewState};

handle_cast({after_fight,Len,TargetBin}, State)->
    DataList = get_robot_status(Len,TargetBin,[]) ,
    case lists:keyfind(State#robot.id, 1, DataList) of
        {_,CurHp} ->
            case CurHp > 0 of
                true ->
                    NewState = State ;
                false ->
                    NewState = State#robot{status = dead}
            end ;
        _ ->
            NewState = State
    end ,
    {noreply, NewState};

handle_cast({start_action}, State)->
    if is_port(State#robot.socket) ->
        %%心跳进程
        spawn_link(fun()->handle(heart, a , State#robot.socket) end),
        Pid= self() ,
        spawn_link(fun()-> ai(Pid) end), 
        if ?INITIAL_GM >= 1 ->
            spawn(fun() -> robot_gm:handle(State) end);
        true -> skip end,
        erlang:send_after(1000, Pid, {random}), 
        {noreply, State};
    true -> 
        ?TRACE("start_action  stop_1: /~p/,~n",[State]),
        {stop, normal, State}
    end;

handle_cast({upgrade_state, NewState},_State) ->
	%%io:format("====upgrade_state ~p~n",[NewState#robot.status]) ,
    {noreply,NewState};

handle_cast({get_state_13001},State) ->
    handle(get_self_info, a,State#robot.socket),
    {noreply, State};

handle_cast({init_skill_list,SkillList_ABin},_State)->
	NewSkillList =robot_battle:make_skill_list(SkillList_ABin,[]),  
	 {noreply, _State#robot{skill_list = NewSkillList}};

handle_cast({upgrade_state_13001, [Scene, X, Y,Hp]},State) ->
	random:seed(erlang:now()),
	EnterX = 20 + random:uniform(10) - 5,
	EnterY = 10 + random:uniform(10) - 5,
	case Hp =< 0 of
		true ->
			NewState = State#robot{x=EnterX, y=EnterY,scene=Scene,hp = Hp,  status = dead} ;
			%%NewState = State#robot{x=X, y=Y,scene=Scene,hp = Hp, act = run, status = dead} ;
		false ->
			NewState = State#robot{x=EnterX, y=EnterY,scene=Scene,hp = Hp, status = standing}
			%%NewState = State#robot{x=X, y=Y,scene=Scene,hp = Hp, act = %%run, status = standing}
	end ,
%% 	io:format("========upgrade_state_13001 enter scene:~p , ~p , ~p , ~p ~n", [Scene,Hp,NewState#robot.act,NewState#robot.status]) ,
    handle(enter_scene, [Scene,EnterX,EnterY] ,NewState#robot.socket),
    %%handle(enter_scene, [Scene,X,Y] ,NewState#robot.socket),
    {noreply, NewState};

handle_cast({upgrade_state_revive, [NewSceneId,ReviveX,ReviveY]},State) ->
    NewState = State#robot{status = standing, x=ReviveX, y=ReviveY},
	handle(enter_scene,[NewSceneId,ReviveX,ReviveY], State#robot.socket) ,
    {noreply, NewState};
  
handle_cast({upgrade_state_13099, [IdLists]},State) ->
    IdLists1 = [[State#robot.id] | IdLists],  
    NewState = State#robot{frda=IdLists1},
    {noreply, NewState};

handle_cast({run}, State)->
    State2=State#robot{act=run},
    {noreply,State2};

handle_cast({stop}, State)->
    State2=State#robot{act=undefined},
    {noreply,State2};

handle_cast({stop, _Reason},State)->
    ?TRACE("~s_quit_2: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),    
    {stop, normal, State};

handle_cast({get_bag_list, [Location]},State) ->
	io:format("*********20130916 robot handle_cast get_bag_list Location = ~p~n", [Location]),
    {noreply, State};

%%处理模块发到某个模块的消息
handle_cast({Mod, Msg}, State) ->
    case lists:member(Mod, ?RANDOM_MODULE) of
        true ->
            Module = list_to_atom(lists:concat(["robot_", Mod])),
            case catch Module:handle_cast(Msg, State) of
                {noreply, NewState} when is_record(NewState, robot) ->
                    NewState;
                _  -> 
                    State
           end;
        false ->
           ?TRACE("Error cast call: Mod:~p Msg: ~p~n", [Mod, Msg]),
           State
    end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({random}, State) ->
  NewState = handle_action_random(State),
  erlang:send_after(?RANDOM_INTERVAL, self(), {random}), 
  {noreply,NewState};

handle_info({stop, _Reason},State)->
    ?TRACE("~s ------ robot stop: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),
    {stop, normal, State};

handle_info(close, State)->
    gen_tcp:close(State#robot.socket),
    {noreply,State};

%%处理模块发到某个模块的消息
handle_info({Mod, Msg}, State) ->
    case lists:member(Mod, ?RANDOM_MODULE) of
        true ->
            Module = list_to_atom(lists:concat(["robot_", Mod])),
            case catch Module:handle_info(Msg, State) of
                {noreply, NewState} when is_record(NewState, robot) ->
                    NewState;
                _  -> 
                    State
           end;
       false ->
           ?TRACE("Error msg call: Mod:~p Msg: ~p~n", [Mod, Msg]),
           State
    end,
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
    ?TRACE(" ----------terminate-----------~s_quit_4: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),
    if is_port(State#robot.socket) ->
        gen_tcp:close(State#robot.socket);
        true -> no_socket
    end,
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=========================================================================
%% 业务处理函数
%%=========================================================================
%%登录游戏服务器
login(N, Pid, Port, IP)->
    case connect_server(IP, Port) of
        {ok, Socket}->
              ?TRACE("~s ---connect to IP:~p Port: ~p  ok...~n",[misc:time_format(now()), IP, Port]),
              Accid = N,  
              AccName = "ROBOT" ++ integer_to_list(Accid),
              handle(login, {Accid, AccName}, Socket),
              spawn_link(fun() -> do_parse_packet(Socket, Pid) end),
              {ok, Socket};
        _Reason2 ->
             ?TRACE("Connect to server failed: ~p~n", [_Reason2]),
             error
   end.

%%连接服务端
connect_server(Ip, Port)->
    gen_tcp:connect(Ip, Port, ?TCP_OPTS, 10000).

%% 接受信息
async_recv(Sock, Length, Timeout) when is_port(Sock) ->
    case prim_inet:async_recv(Sock, Length, Timeout) of
        {error, Reason} ->  throw({Reason});
        {ok, Res}       ->  Res;
        Res             ->  Res
    end.

%%接收来自服务器的数据 - 登陆后进入游戏逻辑
%%Socket：socket id
%%Client: client记录
do_parse_packet(Socket, Pid) ->
	Ref = async_recv(Socket, ?HEADER_LENGTH, ?HEART_TIMEOUT),
	receive
		{inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
			?TRACE("receive command:  ~p, length: ~p~n", [Cmd, Len]),
			BodyLen = Len - ?HEADER_LENGTH,
			RecvData = 
				case BodyLen > 0 of
					true ->
						Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
						receive
							{inet_async, Socket, Ref1, {ok, Binary}} ->
								{ok, Binary};
							Other ->
								?TRACE("Data recv Error:  ~p~n", [Other]),
								{fail, Other}
						end;
					false ->
						{ok, <<>>}
				end,
			case RecvData of
				{ok, BinData} ->
					case Cmd of
						10000 -> 
							<<Code:8, _Bin1/binary>> = BinData,
							case Code of
								0 ->
									gen_server:cast(Pid, {login_ok, 0}),
									<<_:32, PlayerId:64, _Bin2/binary>> = _Bin1,
									handle(enter_player, {PlayerId}, Socket),
									ok;
								1 ->
									<<Accid:32, _Bin2/binary>> = _Bin1,
									gen_server:cast(Pid, {login_ok, 1}),
									handle(select_role, Accid, Socket),
									ok;
								_ ->
									gen_server:cast(Pid, login_failed),
									?TRACE("login failed: Code: ~p~n", [Code]),
									failed
							end;
						10003 ->
							<<Code:8, PlayerId:64, _Bin/binary>> = BinData,
							?TRACE("10003: Code: ~p PlayerId~p~n", [Code, PlayerId]),
							if Code =:= 1 ->
								   handle(enter_player, {PlayerId}, Socket),
								   gen_server:cast(Pid, {playerid, PlayerId});
							   true ->
								   gen_server:cast(Pid, {stop})
							end;
						10004 ->
							<<Code:8, _Bin/binary>> = BinData,
							if 
								Code =/= 0 ->
									%% 选择玩家信息以进入场景
									gen_server:cast(Pid, {get_state_13001}) ;
								true ->
									gen_server:cast(Pid, {stop})
							end;
						13001 ->
							?TRACE("hahhaha ~n",[]),
							NewData = zlib:uncompress(BinData),
							<<_Uid:64,_Gender:8,_Level:8,_Career:8,_Speed:8,SceneId:16,X:8,Y:8,Hp:32,_Other/binary>> = NewData,
							%%更新信息
							
							gen_server:cast(Pid,{upgrade_state_13001, [SceneId,X,Y,Hp]}),
							ok;
						12001 ->
							<<SceneId:16, _Other/binary>> = BinData,
							%% 							io:format("========receive 12001:~p ~n", [SceneId]) ,
							if
								SceneId > 0 ->
									gen_tcp:send(Socket, pack(12005, <<>>)),
									%% 在场景中走路
									gen_server:cast(Pid,enter_ok); 
								true ->
									gen_server:cast(Pid, {stop})
							end ,
							ok ;
						12002 ->	%% 更新场景怪物
							NewData = zlib:uncompress(BinData), 
							State=gen_server:call(Pid,{get_state}),
							robot_battle:reflesh_monster(State#robot.acid,NewData);
						20003 ->     %%人物被攻击
							?TRACE("==20003 ~p~n",[BinData]) ,
							<<_Id1:32, _Hp1:32, _Mp1:32, _Sid1:32, _Slv1:8, _X1:8, _Y1:8,_:32, DLen:16,TarBin/binary>> = BinData,
							gen_server:cast(Pid,{after_fight,DLen,TarBin}) ,
							ok ; 
						21000 ->
							?TRACE("==21000 ~p~n",[BinData]) ,
							NewData = zlib:uncompress(BinData) ,
							<<_:16, SkillList_ABin/binary>> = NewData,
							gen_server:cast(Pid,{init_skill_list,SkillList_ABin}) ;
						12021 ->
							<<Code:8, NewSceneId:16,ReviveX:8,ReviveY:8,_Other/binary>> = BinData ,
							case Code of
								1 ->
									gen_server:cast(Pid,{upgrade_state_revive, [NewSceneId,ReviveX,ReviveY]}) ;
								_ ->
									gen_server:cast(Pid, {stop})
							end ,
							ok ;
						10007 ->
							<<_Code:8>> = BinData,
							?TRACE("==10007 ~p~n",[_Code]) ,
							ok;
                        30006 ->
                            NewData = zlib:uncompress(BinData),
							<<DataLen:16,Data/binary>> = NewData,
							TaskList = robot_task:parse_task_data(Data,[]),
                            gen_server:call(Pid,{upgrade_state_30006,TaskList}),
							ok;

						_Chat when _Chat >= 11000 andalso _Chat < 12000 ->
							skip;
						%%                             robot_chat:do_parse_packet(Socket, Pid, Cmd, BinData);
						_Guild when _Guild >= 40000 andalso _Guild < 41000 ->
                            ?TRACE("==_Guild= ~p~n",[_Guild]) ,
							robot_guild:do_parse_packet(Socket, Pid, Cmd, BinData);
                            %no_action
                        13021 ->%%修改机器人帮派属性
                            <<GuildId:32, _GuildName_RestBin/binary>> = BinData ,
                            {GuildName, _GuildName_DoneBin} = pt:read_string(_GuildName_RestBin),
                             <<Position:8>> = _GuildName_DoneBin,
                            gen_server:cast(Pid,{refresh_robot_guild_state, [GuildId,Position]}) ;

						15002 ->
							io:format("******20130916 robot recv 15002 ~n"),
							gen_server:cast(Pid,{get_bag_list, [0]});
						_ -> 
							no_action
					end,
					do_parse_packet(Socket, Pid);
				{fail, _} ->
					[{1,Num}] = ets:lookup(off_line_static, 1),
					NewNum = Num+1,
					ets:insert(off_line_static, {1,NewNum}),
					?TRACE("do_parse_packet total off ~p recv data failed:/~p/~p/~n~p~n",[NewNum,Socket, Pid, RecvData]),   
					gen_tcp:close(Socket),
					gen_server:cast(Pid,{stop, socket_error_1})
			end;
		%%超时处理
		{inet_async, Socket, Ref, {error,timeout}} ->
			io:format("do_parse_packet timeout:/~p/~p/~n",[Socket, Pid]),
			do_parse_packet(Socket, Pid);
		%%用户断开连接或出错
		Reason ->
			[{1,Num}] = ets:lookup(off_line_static, 1),
			NewNum = Num+1,
			ets:insert(off_line_static, {1,NewNum}),
			io:format("do_parse_packet: total off ~p Error Reason:/~p/~p/~n",[NewNum,Socket, Reason]),            
			gen_tcp:close(Socket),
			gen_server:cast(Pid,{stop, socket_error_3})
	end.

%% 随机事件处理
handle_action_random(State) ->
    Actions = ?RANDOM_MODULE, 
    if Actions =/= [] ->
        Action = lists:nth(random:uniform(length(Actions)), Actions),
        Module = list_to_atom(lists:concat(["robot_",Action])),
        case catch Module:handle(State) of
            NewState when is_record(NewState, robot) ->
                NewState;
            _Error  -> 
                io:format("ERROR: ~p~n", [_Error]),
                State
        end;
    true ->
        State
    end.
    
%%游戏相关操作%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%心跳包
handle(heart, _, Socket) ->
    case gen_tcp:send(Socket, pack(10006, <<>>)) of
        ok ->
            sleep(24*1000),
            handle(heart, a, Socket);
        _ ->
            error
    end;

%%登陆
handle(login, {Accid, AccName}, Socket) ->
    ?TRACE("sending login request entry socket: ~p  ~p  ~p~n", [Accid, AccName, Socket]),
    AccStamp = 1273027133,
    Tick = integer_to_list(Accid) ++ AccName ++ integer_to_list(AccStamp) ++ ?TICKET,
    TickMd5 = util:md5(Tick),
    TickMd5Bin = list_to_binary(TickMd5),
    TLen = byte_size(TickMd5Bin),
    AccNameLen = byte_size(list_to_binary(AccName)),
    AccNameBin = list_to_binary(AccName),
    Data = <<9999:16, Accid:32, AccStamp:32, AccNameLen:16, AccNameBin/binary, TLen:16, TickMd5Bin/binary>>,
    ?TRACE("sending login request: ~p  ~p~n", [Accid, AccName]),
    gen_tcp:send(Socket, pack(10000, Data)),
    ok;

%%选择角色进入
handle(select_role, Accid, Socket) ->
    NickName = "GUEST" ++ integer_to_list(Accid),
    NameBin = list_to_binary(NickName),
    TLen = byte_size(NameBin),
	random:seed(erlang:now()),
    Gender = random:uniform(2),
    Career = random:uniform(3), 
	StrOsVersion = pt:pack_string("2.3.4"),
	Device = pt:pack_string("test"),
	Screen = pt:pack_string("test"),
    gen_tcp:send(Socket, pack(10003, <<9999:16, Career:8, Gender:8, TLen:16, NameBin/binary,0:8,StrOsVersion/binary,Device/binary,0:8,0:8,0:8,Screen/binary>>)),    
    ok;
  
 
%%选择角色进入
handle(enter_player, {PlayerId}, Socket) -> 
	StrOsVersion = pt:pack_string("2.3.4"),
	Device = pt:pack_string("test"),
	Screen = pt:pack_string("test"),
	%0:8,StrOsVersion/binary,Device/binary,0:8,Screen/binary,0:8,0:8
    gen_tcp:send(Socket, pack(10004, <<9999:16, PlayerId:64, 30:8, 20:8,0:8,StrOsVersion/binary,Device/binary,0:8,0:8,0:8,Screen/binary>>)),    
    ok;

%%跑步
handle(run,{DestX,DestY},Socket)->
    gen_tcp:send(Socket, pack(12011, <<DestX:16,DestY:16>>));

%%跑步
handle(broad_path,{DestX,DestY,Path},Socket)->
    Len = length(Path) ,
    Fun = fun({X,Y}) ->
                  <<X:16,Y:16>> 
          end ,
    MoveBin  = tool:to_binary([Fun(M) || M <- Path]),
    gen_tcp:send(Socket, pack(12010, <<DestX:16,DestY:16,Len:16,MoveBin/binary>>));

%% %%ai模式跑步
%% handle(run, {X,Y, SX, SY}, Socket) ->
%%     ?TRACE("----running:[~p][~p]~n",[X,Y]),
%%     gen_tcp:send(Socket,  pack(12001, <<X:8, Y:8, SX:8, SY:8>>));

%%进入场景
handle(enter_scene,[SceneId,Posx,Posy], Socket) ->
%%     Posx = random:uniform(30) ,
%%     Posy = random:uniform(20) ,
	%%io:format("========handle(enter_scene:~p ~n", [SceneId]) ,
    gen_tcp:send(Socket,  pack(12001, <<SceneId:16,Posx:16,Posy:16>>)) ;

%%静止
handle(undefined,a,_Socket)->
    ok;

%%获取其他玩家信息
handle(get_player_info,Id,Socket)->
    gen_tcp:send(Socket,  pack(13004, <<Id:16>>));

%%获取自己信息
handle(get_self_info, _ ,Socket)->
    ?TRACE("get_self_info: sending 13001~n"),
    gen_tcp:send(Socket,  pack(13001, <<>>));

%%原地复活
handle(revive, _, Socket)->
%%     gen_tcp:send(Socket, pack(20004, <<3:8>>)),
%%     Action = tool:to_binary("-加血 100000"),
%%     ActionLen= byte_size(Action),
%%     Data = <<ActionLen:16, Action/binary>>,
%%     Packet =  pack(11020, Data),    
%%     gen_tcp:send(Socket, Packet);
	   io:format("====handle(revive ~p~n",[revive]) ,
       gen_tcp:send(Socket, pack(12021, <<0:16>>)) ;

handle(_Handle, _Data, Socket) ->
    ?TRACE("handle error: /~p/~p/~n", [_Handle, _Data]),
    {reply, handle_no_match, Socket}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%辅助函数
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

random_sleep(T) ->
    N = random:uniform(T),
    timer:sleep(N * 100).


sleep(T) ->
    receive
    after T -> ok
    end.

for(Max, Max, _F) ->
    [];
for(Min, Max, F) ->
    [F(Min) | for(Min+1, Max, F)].

for(Max, Max, _F, X) ->
    X;
for(Min, Max, F, X) ->
    F(X),
    for(Min+1, Max, F, X).

sleep_send({T, S}) ->
    receive
    after T -> handle(run, a, S)
    end.

get_pid(Name)->
    case whereis(Name) of
        undefined ->
            err;
        Pid->Pid
    end.

ping(Node)->
    case net_adm:ping(Node) of
        pang ->
            ?TRACE("ping ~p error.~n",[Node]);
        pong ->
            ?TRACE("ping ~p success.~n",[Node]);
        _Error->
            ?TRACE("error: ~p ~n",[_Error])
    end.

get_robot_status(0,_TargetBin,DataList) ->
    DataList ;
get_robot_status(Len,TargetBin,DataList) ->
    <<_:8,UId:64,CurHp:32,_:32,_:32,_:32,_:8,OtherBin/binary>> = TargetBin ,
    NewDataList = DataList ++ [{UId,CurHp}] , 
    get_robot_status(Len-1,OtherBin,NewDataList) . 
    

%%根据机器人状态进行动作
ai(Pid)->
    %%更新信息
%%     gen_server:cast(Pid,{get_state_13001}),
    Random_interval = random:uniform(1000)+100,
    sleep(Random_interval),    
    State=gen_server:call(Pid,{get_state}),
 	io:format("========ai(Pid):~p ~p~n", [State#robot.act,State#robot.status]) ,
    case State#robot.act of
        run ->
            case State#robot.status of
                standing ->
					io:format("====ai(Pid)standing ~p~n",[standing]) ,
				 	State2 = robot_battle:stand_call_back(State), 
                    gen_server:cast(State2#robot.pid,{upgrade_state,State2}) ,
					sleep(800);
                running ->
					io:format("====ai(Pid)running ~p~n",[running]) ,
                    if State#robot.step =/= [] ->    %%当前坐标不等于目的坐标
                           [{NextX,NextY}|LeftPath] = State#robot.step ,
                           handle(run,{NextX,NextY},State#robot.socket) ,  
                           State2=State#robot{x=NextX,y=NextY,step=LeftPath,status=running} ,
                           gen_server:cast(State#robot.pid,{upgrade_state,State2}) ;
                       true ->
                           State2=State#robot{status=standing},                        %%到达目的地, 换个状态为站
                           gen_server:cast(State#robot.pid,{upgrade_state,State2})    %%更新机器人状态
                    end;
                dead ->
					%io:format("====ai(Pid)dead ~p~n",[dead]) ,
                    handle(revive,a,State#robot.socket) ;    %%让其复活
				fighting ->
						%io:format("====ai(Pid)fighting ~p~n",[fighting]) ,
					robot_battle:begin_attrack(State),
					sleep(800);
                _->
                    ?TRACE("robot status error!~n")
            end ,
    		ai(Pid);
		test_goods ->
			case ?START_ROBOT_GOODS of
				true ->
				   io:format("***********20130916 test_goods ~n"),
				   robot_goods:start_robot_test(State),
				   sleep(800),
				   ai(Pid);
				_ ->
					ok
			end;
        do_task ->
            TargetTask = robot_task:get_rand_taskPid(State#robot.task_list),
            %%RandTid = rand(1,?MAX_TASK_NUM),
            if
                is_record(TargetTask,task_list) ->
                    RandAction = rand(1,4),
                    if
                        RandAction =:= 1 ->
                            robot_task:accept_task(State#robot.socket,TargetTask#task_list.id);
                        RandAction =:= 2 ->
                            robot_task:finish_task(State#robot.socket,rand(1,?MAX_TASK_NUM));
                        RandAction =:= 3 ->
                            robot_task:submit_task(State#robot.socket,TargetTask#task_list.id);
                        true ->
                            robot_task:handle(get_task,{},State#robot.socket)%%获取任务列表
                    end;
                true ->
                    skip
            end,
            ai(Pid);            
		chat ->
			{X,Y,Z} = erlang:now(),
			LastChatTime = get(last_chat_time),
			if
				LastChatTime == undefined ->
					IsHandle = true;
				true ->
					io:format("Y = ~p LastChatTime = ~p~n",[Y,LastChatTime]),
					if
						Y - LastChatTime > 5 ->
							IsHandle = true;
						true ->
							IsHandle = false
					end
			end,
			
			if
				IsHandle == true ->
					robot_chat:handle(State),
					put(last_chat_time,Y);
				true ->
					skip
			end,
			ai(Pid);
		mail ->
			robot_mail:handle(State),
			ai(Pid);
		mount ->
			skip,
			ai(Pid);
		openfunc ->
			skip,
			ai(Pid);
		newbie ->
			skip,
			ai(Pid);
        _ ->
            ok
    end.

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.


rand(Same, Same) -> Same;
rand(Min, Max) ->
    M = Min - 1,
    if
        Max - M =< 0 ->
            0;
        true ->
            random:uniform(Max - M) + M
    end.


%%@spec 获取怪物追击路径
make_move_path(StartX,StartY,EndX,EndY,Path) ->
    if
        StartX =:= EndX andalso StartY =:= EndY ->
            Path ;
        StartX =:= EndX ->
            NextX = StartX ,
            NextY = make_next_step(StartY,EndY) ,
            NewPath = Path ++ [{NextX,NextY}] ,
            make_move_path(NextX,NextY,EndX,EndY,NewPath) ;
        StartY =:= EndY ->
            NextX = make_next_step(StartX,EndX) ,
            NextY = EndY ,
            NewPath = Path ++ [{NextX,NextY}] ,
            make_move_path(NextX,NextY,EndX,EndY,NewPath) ;
        true ->
            NextX = make_next_step(StartX,EndX) ,
            NextY = make_next_step(StartY,EndY)  ,
            NewPath = Path ++ [{NextX,NextY}] ,
            make_move_path(NextX,NextY,EndX,EndY,NewPath) 
    end .
make_next_step(Current,Target) ->
    if Current > Target ->
           if Current - Target > 1 ->
                  Current - 1;
              true ->
                  Target
           end;
       true ->
           if Target - Current > 1 ->
                  Current + 1;
              true ->
                  Target
           end
    end.

rand(Min) when Min =< 0 ->
    0;
rand(Max) ->
    case get("rand_seed") of
        undefined ->
           RandSeed = now(),
           random:seed(RandSeed),
           put("rand_seed", RandSeed);
        _ -> skip
    end,
    random:uniform(Max).

