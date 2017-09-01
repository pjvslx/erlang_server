%%% -------------------------------------------------------------------
%%% Author:     SMXX
%%% Description : 机器人
%%% Created :
%%% -------------------------------------------------------------------
-module(robot_gateway).
-behaviour(gen_server).
-include("robot.hrl").

-compile(export_all).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%%
%%% API

start()->
    start(20000, 10000),
    ok.
 
%%StartId 起始AccountID
%%Num int 数量
%%Mod 跑步模式 1 ,2
start(StartId, Num)->
    sleep(100),
    F=fun(N)->
         io:format("start robot-~p~n",[N]),
         sleep(200),
         start_link(StartId + N)
    end,
    for(0,Num,F),
    ok.

 
%%创建 一个ROBOT 进程
start_link(N)->
    case gen_server:start(?MODULE,[N],[]) of
        {ok, _Pid}->
            io:format("--robot~p start finish!-~n",[N]);
            %gen_server:cast(Pid, {start_action});
        _->
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
init([N]) ->
	process_flag(trap_exit,true),
	Pid = self(),
	Robot= #robot{login = 0,
				  acid = N, 
				  id = 0, 
				  pid = Pid
				 } ,
	erlang:send_after(10, self(), {'action'}) , 
	%%登陆成功后开始动作
	{ok,Robot} .


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
           io:format("Error cast call: Mod:~p Msg: ~p~n", [Mod, Msg]),
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
handle_cast({gateway_fallback}, State)->
 	io:format("====gateway_fallback: ~p~n", [State#robot.pid]) ,
	gen_tcp:close(State#robot.socket),
	exit(State#robot.rpid,nomal) ,
	erlang:send_after(1000, self(), {'action'}) ,
	{noreply, State#robot{socket=[]}};

handle_cast(login_failed, State)->
    io:format("login failed~n"),
    {stop, normal, State};

handle_cast({playerid, Id}, State)->
    NewState = State#robot{id = Id},
    {noreply, NewState};

handle_cast(enter_ok, State)->
    NewState = State#robot{act = run, status = standing},
    gen_server:cast(self(), {start_action}),
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


handle_cast({upgrade_state, NewState},_State) ->
    {noreply,NewState};

handle_cast({get_state_13001},State) ->
    handle(get_self_info, a,State#robot.socket),
    {noreply, State};
    
handle_cast({upgrade_state_13001, [Scene, X, Y]},State) ->
    NewState = State#robot{x=X, y=Y,scene=Scene},
    handle(enter_scene, [Scene] ,State#robot.socket),
    {noreply, NewState};

handle_cast({upgrade_state_revive, []},State) ->
    NewState = State#robot{status = standing},
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
    io:format("~s_quit_2: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),    
    {stop, normal, State};

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
           io:format("Error cast call: Mod:~p Msg: ~p~n", [Mod, Msg]),
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
handle_info({'action'}, State) ->
	case connect_server(?GATEWAY_ADD, ?GATEWAY_PORT) of
		{ok, Socket}->
			Accid = State#robot.acid ,  
			AccName = "ROBOT" ++ integer_to_list(Accid),
			handle(login_gateway, {Accid, AccName}, Socket) ,
			RPid = spawn_link(fun() -> do_parse_packet(Socket, State#robot.pid) end) ,
			NewState = State#robot{socket = Socket,rpid = RPid} ,
			{ok, Socket} ;
		_Reason2 ->
			NewState = State ,
			io:format("Connect to server failed: ~p~n", [_Reason2]),
			error
	end ,
	{noreply,NewState};



handle_info({random}, State) ->
  NewState = handle_action_random(State),
  erlang:send_after(?RANDOM_INTERVAL, self(), {random}), 
  {noreply,NewState};

handle_info({stop, _Reason},State)->
    io:format("~s ------ robot stop: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),
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
           io:format("Error msg call: Mod:~p Msg: ~p~n", [Mod, Msg]),
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
    io:format(" ----------terminate-----------~s_quit_4: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, _Reason]),
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
login(N, Pid)->
	case connect_server(?GATEWAY_ADD, ?GATEWAY_PORT) of
		{ok, Socket}->
			Accid = N,  
			AccName = "ROBOT" ++ integer_to_list(Accid),
			handle(login_gateway, {Accid, AccName}, Socket),
			spawn_link(fun() -> do_parse_packet(Socket, Pid) end),
			{ok, Socket};
		_Reason2 ->
			io:format("Connect to server failed: ~p~n", [_Reason2]),
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
			BodyLen = Len - ?HEADER_LENGTH,
			RecvData = 
				case BodyLen > 0 of
					true ->
						Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
						receive
							{inet_async, Socket, Ref1, {ok, Binary}} ->
								{ok, Binary};
							Other ->
								io:format("Data recv Error:  ~p~n", [Other]),
								{fail, Other}
						end;
					false ->
						{ok, <<>>}
				end,
			case RecvData of
				{ok, _BinData} ->
					case Cmd of
						60000 -> 
                            gen_server:cast(Pid,{gateway_fallback}) ;
						_ ->
							io:format("do_parse_packet recv data failed:/~p/~p/~n~p~n",[Socket, Pid, RecvData])
					end ;

				{fail, _} ->
					io:format("do_parse_packet recv data failed:/~p/~p/~n~p~n",[Socket, Pid, RecvData]),                        
					gen_tcp:close(Socket),
					gen_server:cast(Pid,{stop, socket_error_1})
			end;
		%%超时处理
		{inet_async, Socket, Ref, {error,timeout}} ->
			io:format("do_parse_packet timeout:/~p/~p/~n",[Socket, Pid]),
			do_parse_packet(Socket, Pid);
		%%用户断开连接或出错
		Reason ->
			io:format("do_parse_packet: Error Reason:/~p/~p/~n",[Socket, Reason]),            
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


%%连接网关
handle(login_gateway, {Accid, AccName}, Socket) ->
	io:format("======sending login_gateway : ~p    ~p~n", [Accid, Socket]),
	StrBin = tool:to_binary(AccName),
	Len = byte_size(StrBin),
    Data = <<Accid:32, 123456789:32, Len:16,StrBin/binary>> ,
    gen_tcp:send(Socket, pack(60000, Data)),
    ok ;



%%选择角色进入
handle(select_role, Accid, Socket) ->
    NickName = "GUEST" ++ integer_to_list(Accid),
    NameBin = list_to_binary(NickName),
    TLen = byte_size(NameBin),
    Gender = random:uniform(2),
    Career = random:uniform(3),
    gen_tcp:send(Socket, pack(10003, <<9999:16, Career:8, Gender:8, TLen:16, NameBin/binary>>)),    
    ok;

%%选择角色进入
handle(enter_player, {PlayerId}, Socket) ->
%%     Posx = random:uniform(30) ,
%%     Posy = random:uniform(20) ,
    gen_tcp:send(Socket, pack(10004, <<9999:16, PlayerId:64, 30:8, 20:8>>)),    
    ok;

%%跑步
handle(run,{DestX,DestY},Socket)->
    gen_tcp:send(Socket, pack(12011, <<DestX:8,DestY:8>>));

%%跑步
handle(broad_path,{DestX,DestY,Path},Socket)->
    Len = length(Path) ,
    Fun = fun({X,Y}) ->
                  <<X:8,Y:8>> 
          end ,
    MoveBin  = tool:to_binary([Fun(M) || M <- Path]),
    gen_tcp:send(Socket, pack(12010, <<DestX:8,DestY:8,Len:16,MoveBin/binary>>));

%%ai模式跑步
handle(run, {X,Y, SX, SY}, Socket) ->
    io:format("----running:[~p][~p]~n",[X,Y]),
    gen_tcp:send(Socket,  pack(12001, <<X:8, Y:8, SX:8, SY:8>>));

%%进入场景
handle(enter_scene,[SceneId], Socket) ->
    Posx = random:uniform(30) ,
    Posy = random:uniform(20) ,
    gen_tcp:send(Socket,  pack(12001, <<SceneId:16,Posx:8,Posy:8>>)) ;

%%静止
handle(undefined,a,_Socket)->
    ok;

%%获取其他玩家信息
handle(get_player_info,Id,Socket)->
    gen_tcp:send(Socket,  pack(13004, <<Id:16>>));

%%获取自己信息
handle(get_self_info, _ ,Socket)->
    io:format("get_self_info: sending 13001~n"),
    gen_tcp:send(Socket,  pack(13001, <<>>));

%%原地复活
handle(revive, _, Socket)->
%%     gen_tcp:send(Socket, pack(20004, <<3:8>>)),
%%     Action = tool:to_binary("-加血 100000"),
%%     ActionLen= byte_size(Action),
%%     Data = <<ActionLen:16, Action/binary>>,
%%     Packet =  pack(11020, Data),    
%%     gen_tcp:send(Socket, Packet);
       gen_tcp:send(Socket, pack(12020, <<>>)) ;

handle(_Handle, _Data, Socket) ->
    io:format("handle error: /~p/~p/~n", [_Handle, _Data]),
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
            io:format("ping ~p error.~n",[Node]);
        pong ->
            io:format("ping ~p success.~n",[Node]);
        _Error->
            io:format("error: ~p ~n",[_Error])
    end.

get_robot_status(0,_TargetBin,DataList) ->
    DataList ;
get_robot_status(Len,TargetBin,DataList) ->
    <<_:8,UId:64,CurHp:32,_:32,_:32,_:32,_:8,OtherBin/binary>> = TargetBin ,
    NewDataList = DataList ++ [{UId,CurHp}] , 
    get_robot_status(Len-1,OtherBin,NewDataList) . 
    


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

