%%% -------------------------------------------------------------------
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.01.13
%%% -------------------------------------------------------------------
-module(new_robot).

-behaviour(gen_server).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-define(CONFIG_FILE, "../config/gateway.config").

%% 连接网关端口，不读取gateway配置
-define(GATEWAY_ADD,"127.0.0.1"). 
%% -define(GATEWAY_ADD,"192.168.51.131"). 
-define(GATEWAY_PORT,7777).

-define(ACTION_SPEED_CONTROL, 10).
-define(ACTION_INTERVAL, ?ACTION_SPEED_CONTROL*1000).  % 自动行为最大时间间隔
-define(ACTION_MIN, 3000).    % 自动行为最小时间间隔

-define(TCP_OPTS, [
        binary,
        {packet, 0}, % no packaging
        {reuseaddr, true}, % allow rebind without waiting
        {nodelay, false},
        {delay_send, true},
        {active, false},
        {exit_on_close, false}
    ]).

-define(ETS_ROBOT, ets_robot).

-define(CHECK_ROBOT_STATUS, 1*60*1000).

%% -define(debug,1).
%% 断言以及打印调试信息宏
-ifdef(debug).
    -define(TRACE(Str), io:format(Str)).
    -define(TRACE(Str, Args), io:format(Str, Args)).
    % unicode版
    -define(TRACE_W(Str), io:format("~ts", [list_to_binary(io_lib:format(Str, []))])).
    -define(TRACE_W(Str, Args), io:format("~ts", [list_to_binary(io_lib:format(Str, Args))])).
-else.
    -define(TRACE(Str), void).
    -define(TRACE(Str, Args), void).

    -define(TRACE_W(Str), void).
    -define(TRACE_W(Str, Args), void).
-endif.

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(robot, {
        orig_n,    
        login,
        acid,      %%account id
        socket,    %%socket
        socket2,
        socket3,
        pid,    %%process id
        x ,        %%x坐标
        y ,        %%y坐标
        scene,
        tox,
        toy,
        hp,
        id,     %% id
        act,    %% 动作
        status, %% 当前状态
        dstScene,
        step,
        frda, %% 好友信息
        bkda, %% 黑名单信息,
        sgda %% 陌生人信息         
    }).
%%%
%%% API

start()-> 
    start(30000, 1),
    ok.


%%StartId 起始AccountID
%%Num int 数量
%%Mod 跑步模式 1 ,2
start(StartId, Num)->
    sleep(100),
    F=fun(N)->
         ?TRACE("start robot-~p~n",[N]), 
         sleep(100),
         ?MODULE:start_link(StartId + N)
    end,
    for(0,Num,F),
    ok.

%%创建 一个ROBOT 进程
start_link(N)->
    case gen_server:start(?MODULE,[N],[]) of
        {ok, _Pid}->
            ?TRACE("--robot~p start finish!-~n",[N]);
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
    case login(N, Pid) of
        {ok, Socket}->
            Scene = 10101,
            Robot= #robot{socket = Socket, 
                          login = 0,
                          acid = N, 
                          id = 0, 
                          pid = Pid,
                          act = none,
                          status = none,
                          scene = Scene,
                          dstScene = Scene,
                          tox = rand(1,40),
                          toy = rand(1,20),
                          orig_n = N,
                          step = 0,
                          frda = [], %% 好友信息
                          bkda = [], %% 黑名单信息,
                          sgda = []%% 陌生人信息    
                         },
            %%登陆成功后开始动作 
%% 		%%旧协议收邮件
%%      	mail_script:call(19004,{1,1},Socket),
   			%%旧协议收附件
%%    		mail_script:call(19006,{1},Socket),
%%     		chat_script:call(11010,{<<"11">>},Socket), 
%%  		chat_script:call(11070,{1,<<"11">>},Socket), 
%% 			task_script:call(30003,1,Socket),
%% 			task_script:call(30003,2,Socket),
            {ok,Robot};
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
handle_call({act},_From,State)->
    %%act有跑步run或者静止undefined
    handle(State#robot.act, a, State#robot.socket),
    {reply,ok,State};

handle_call({get_state},_From,State)->
    {reply,State,State};

handle_call({get_socket},_From,State)->
    Reply=State#robot.socket,
    {reply,Reply,State};

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

handle_cast({playerid, Id}, State)->
    NewState = State#robot{id = Id},
    {noreply, NewState};

handle_cast(enter_ok, State)->
    NewState = State#robot{act = run, status = standing},
    gen_server:cast(self(), {start_action}),
    {noreply, NewState};
    
handle_cast({start_action}, State)->
    if is_port(State#robot.socket) ->
        %%心跳进程
        spawn_link(fun()->handle(heart, a , State#robot.socket) end),
        %%Pid= self(),
        %%获取个人信息
        handle(get_self_info, 0 ,State#robot.socket),
        %handle(chat,"-加经验 1000000",State#robot.socket),
        %handle(chat,"-全功能",State#robot.socket),
        {noreply, State};
    true -> 
        ?TRACE("start_action  stop_1: /~p/,~n",[State]),
        {stop, normal, State}
    end;

handle_cast({add_child_socket,N,Socket},State)->
    NewState = 
    if
        is_pid(State#robot.pid) andalso is_port(Socket) ->
            case N of
                2 -> State#robot{socket2 = Socket};
                3 -> State#robot{socket3 = Socket};
                _ -> State
            end;
        true ->
            ?TRACE(" start_child_socket err : /~p/,~n",[State]),
            State
    end,
    {noreply,NewState};

handle_cast({upgrade_state, NewState},_State) ->
    {noreply,NewState};

handle_cast({get_state_13001},State) ->
    handle(get_self_info, a,State#robot.socket),
    {noreply, State};
    
handle_cast({upgrade_state_13001, [Scene, X, Y, Hp]},State) ->
    NewState = State#robot{x=X, y=Y, hp=Hp, scene=Scene},
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

handle_cast({stop, Reason},State)->
    ?TRACE("~s_quit_2: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, Reason]),    
    {stop, normal, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({stop, Reason},State)->
    ?TRACE("~s ------ robot stop: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, Reason]),
    {stop, normal, State};

handle_info({event, action_random, PlayerId, Socket},State) ->
    Random_interval = random:uniform(?ACTION_INTERVAL * 2) + ?ACTION_MIN * 6,
%% ?TRACE("~s_action_random: ~p~n", [misc:time_format(now()), Random_interval]),
    handle_action_random(PlayerId, Socket),
    %% 好友机器人测试
    NewState = handle_action_friend(State),
    erlang:send_after(Random_interval, self(), {event, action_random, PlayerId, Socket}),
    {noreply,NewState};

handle_info(close, State)->
    gen_tcp:close(State#robot.socket),
    {noreply,State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?TRACE(" ----------terminate-----------~s_quit_4: /~p/~p/~p/,~n",[misc:time_format(now()), State#robot.acid, State#robot.id, Reason]),
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
    case get_game_server() of
        {Ip, Port} ->
             case connect_server(Ip, Port) of
                 {ok, Socket}->
                      ?TRACE("~s ---connect to IP:~p Port: ~p  ok...~n",[misc:time_format(now()), Ip, Port]),
                       Accid = N,  
                       AccName = "Guest" ++ integer_to_list(Accid),
                       handle(login, {Accid, AccName}, Socket),
                       spawn_link(fun() -> do_parse_packet(Socket, Pid) end),
                       {ok, Socket};
                 _Reason2 ->
                      ?TRACE("Connect to server failed: ~p~n", [_Reason2]),
                      error
             end;
        _Reason1 ->    
             ?TRACE("get server failed: ~p~n", [_Reason1]),
             error_110
    end.

%% 获取网关服务器参数
get_gateway_config(Config_file)->
    try
        {ok,[L]} = file:consult(Config_file),
        {_, C} = lists:keyfind(gateway, 1, L),
        {_, Mysql_config} = lists:keyfind(tcp_listener, 1, C),
        {_, Ip} = lists:keyfind(ip, 1, Mysql_config),
        {_, Port} = lists:keyfind(port, 1, Mysql_config),
        [Ip, Port]        
    catch
        _:_ -> [?GATEWAY_ADD,?GATEWAY_PORT]
    end.

%%连接网关服务器
get_game_server()->
    [Gateway_Ip, Gateway_Port] = [?GATEWAY_ADD,?GATEWAY_PORT] ,
    case gen_tcp:connect(Gateway_Ip, Gateway_Port, ?TCP_OPTS, 10000) of
        {ok, Socket}->
            ?TRACE("get_game_server connected to gateway: Ip:~p, Port: ~p ~n",[Gateway_Ip, Gateway_Port]),
            Data = pack(60000, <<>>),
            gen_tcp:send(Socket, Data),
            try
            case gen_tcp:recv(Socket, ?HEADER_LENGTH) of
                {ok, <<Len:16, 60000:16>>} ->
                    BodyLen = Len - ?HEADER_LENGTH,
                    case gen_tcp:recv(Socket, BodyLen, 3000) of
                        {ok, <<Bin/binary>>} ->
                            <<Rlen:16, RB/binary>> = Bin,
                            case Rlen of
                                1 ->
                                    <<Bin1/binary>> = RB,
                                    {IP, Bin2} = pt:read_string(Bin1),
                                    <<Port:16, _Num:8>> = Bin2,
                                    ?TRACE("get_game_server IP, Port:  /~p/~p/~n",[IP, Port]),
                                    {IP, Port};
                                _Len -> 
                                    ?TRACE("recv 60000: Unknown Len: ~p~n", [_Len]),
                                    no_gameserver
                            end;
                         _Reason1 ->
                            gen_tcp:close(Socket),
                            ?TRACE("error when recv 60000: Reason:~p ~n", [_Reason1]),
                            error_10
                    end;
                {error, _Reason2} ->
                    ?TRACE("get_game_server error:~p/~n",[_Reason2]),
                    gen_tcp:close(Socket),
                    error_20
            end
            catch
                _:_ -> gen_tcp:close(Socket),
                       error_30
            end;
        {error,_Reason3}->
            ?TRACE("get_game_server--------------error:~p/~n",[_Reason3]),
            error_40
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
            ?TRACE("receive command:  ~p, length: ~p", [Cmd, Len]),
            BodyLen = Len - ?HEADER_LENGTH,
            RecvData = 
            case BodyLen > 0 of
                true ->
                    Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                    receive
                       {inet_async, Socket, Ref1, {ok, Binary}} ->
                            ?TRACE("Data:  ~p~n", [Binary]),
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
                            ?TRACE("10004: Code: ~p ~n", [Code]),
                            if Code =/= 0 ->
                                gen_server:cast(Pid, enter_ok);
                            true ->
                                gen_server:cast(Pid, {stop})
                            end;
                        13001 ->
                            <<Uid:64, Gender:8, Level:8, Speed:8, Scene:16,  X:8, Y:8, Hp:32, _Other/binary>> = BinData,
                            ?TRACE("13001: Uid:~p, Gender ~p, Level ~p, Speed ~p, Scene ~p,  X ~p, Y ~p, Hp ~p~n", [Uid, Gender, Level, Speed, Scene,  X, Y, Hp]),
                            %%更新信息
                            gen_server:cast(Pid,{upgrade_state_13001, [Scene, X, Y, Hp]}),
 							{ok,Data} = ptr_30:write(30003,[4]),
							gen_tcp:send(Socket,Data) ,
							ok;
                        10007 ->
                            <<_Code:16>> = BinData,
                            ok;
						30501->
							Result =  ptr_30:read(30501,BinData),
							?TRACE("~p : ~p",[30501,Result]),
						    {ok,List} = Result,
						lists:foreach(fun(Tid)->
									 {ok,Data} = ptr_30:write(30004,[Tid]),
									 gen_tcp:send(Socket,Data)
							 end,
							  List) ;
						 O->
							Result =  ptr_30:read(O,BinData),
							?TRACE("~p : ~p",[O,Result]) 
                    end,
                    do_parse_packet(Socket, Pid);
                {fail, _} ->
                    ?TRACE("do_parse_packet recv data failed:/~p/~p/~n~p~n",[Socket, Pid, RecvData]),                        
                    gen_tcp:close(Socket),
                    gen_server:cast(Pid,{stop, socket_error_1})
            end;
         %%超时处理
         {inet_async, Socket, Ref, {error,timeout}} ->
             ?TRACE("do_parse_packet timeout:/~p/~p/~n",[Socket, Pid]),
             do_parse_packet(Socket, Pid);
        %%用户断开连接或出错
        Reason ->
            ?TRACE("do_parse_packet: Error Reason:/~p/~p/~n",[Socket, Reason]),            
            gen_tcp:close(Socket),
            gen_server:cast(Pid,{stop, socket_error_3})
    end.

%% 随机事件处理
handle_action_random(PlayerId, Socket) ->
    Actions = [chat],
    Action = lists:nth(random:uniform(length(Actions)), Actions),
    Module = list_to_atom(lists:concat(["robot_",Action])),
    catch Module:handle(PlayerId, Socket),
    ok.

handle_action_friend(State) ->
    Socket = State#robot.socket,
    Friend = State#robot.frda,
    
    case Friend of
        [] -> 
            gen_tcp:send(Socket,  pack(13099, <<40:8, 200:8>>)),
            State;
        _ ->
            Index = random:uniform(length(Friend)),
            PlayerId = lists:nth(Index, Friend),
            Fri = lists:delete(PlayerId, Friend),
            Actions = [friend],
            Action = lists:nth(random:uniform(length(Actions)), Actions),
            Module = list_to_atom(lists:concat(["robot_",Action])),
            catch Module:handle(PlayerId, Socket),
            State#robot{frda = Fri}
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

%%子socket链接
handle(start_child_socket,{State,N},_) ->
    sleep(5000),
    case get_game_server() of
        {Ip, Port} ->
                case connect_server(Ip, Port-N*100) of
                {ok, Socket}->
                    Accid = State#robot.acid,
                    Pid = State#robot.pid,
                    Data = pack(10008, <<9999:16,Accid:32,N:8>>),
                    gen_tcp:send(Socket, Data),    
                    try
                        Ref = async_recv(Socket, ?HEADER_LENGTH, ?TCP_TIMEOUT),
                    receive
                        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
                            %%?TRACE("--------------------------cmd:~p~n",[Cmd]),
                            BodyLen = Len - ?HEADER_LENGTH,
                            case BodyLen > 0 of
                                true ->
                                       Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                                    receive
                                           {inet_async, Socket, Ref1, {ok, Binary}} when Cmd =:= 10008 ->
                                            %%?TRACE("----------------------rev--10008~n",[]),
                                            <<Code:16,N:8>> = Binary,
                                                %%?TRACE("----------------------rev--10008:~p~n",[Code]),
                                                if
                                                    Code == 1 ->
                                                        %%spawn_link(fun()->do_parse_packet(Socket, Pid) end),
                                                        gen_server:cast(Pid,{add_child_socket,N,Socket}),
                                                        {ok, N};
                                                    true ->
                                                        error_50
                                            end;
                                        Other ->
                                            ?TRACE("---------------child-----------cmd--other:~p~n",[Other]),
                                            gen_tcp:close(Socket),
                                            error_60
                                    end;
                                false ->
                                    error_70
                            end;                       
                        %%用户断开连接或出错
                        Other ->
                            ?TRACE("---------------------child------------other-----err---------~p~n",[Other]),
                            gen_tcp:close(Socket),
                            error_80
                    end
                    catch
                        _:_ -> gen_tcp:close(Socket),
                                  error_90
                    end;
                _ ->
                    error_100
            end;
        _->    error_110
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

%%玩家列表
handle(list_player, _, Socket) ->
    gen_tcp:send(Socket, pack(10002, <<1:16>>)),
    ok;

%%选择角色进入
handle(select_role, Accid, Socket) ->
    NickName = "GUEST-" ++ integer_to_list(Accid),
    NameBin = list_to_binary(NickName),
    TLen = byte_size(NameBin),
    gen_tcp:send(Socket, pack(10003, <<9999:16, 1:8, 1:8, TLen:16, NameBin/binary>>)),    
    ok;

%%选择角色进入
handle(enter_player, {PlayerId}, Socket) ->
    gen_tcp:send(Socket, pack(10004, <<9999:16, PlayerId:64, 30:8, 20:8>>)),    
    ok;

%%跑步
handle(run,a,Socket)->
    X=util:rand(15,45),
    Y=util:rand(15,45),
    gen_tcp:send(Socket, pack(12001, <<X:16,Y:16>>));

%%ai模式跑步
handle(run, {X,Y, SX, SY}, Socket) ->
    ?TRACE("----running:[~p][~p]~n",[X,Y]),
    gen_tcp:send(Socket,  pack(12001, <<X:8, Y:8, SX:8, SY:8>>));

%%进入场景
handle(enter_scene,Sid, Socket) ->
    gen_tcp:send(Socket,  pack(12005, <<Sid:32>>)),
    gen_tcp:send(Socket, pack(12002, <<>>));                %%换场景还要发送12002加载场景, 不然看不到角色的。

%% 聊天模块
handle(chat1, PlayerId, Socket) ->
    Actions = [chat],
    Action = lists:nth(random:uniform(length(Actions)), Actions),
    Module = list_to_atom(lists:concat(["robot_",Action])),
    catch Module:handle(PlayerId, Socket),
    ok;

%%聊天
handle(chat,Data,Socket)->
    Bin=list_to_binary(Data),
    L = byte_size(Bin),
    gen_tcp:send(Socket,  pack(11010, <<L:16,Bin/binary>>));

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

%%复活
handle(revive, _, Socket)->
    gen_tcp:send(Socket, pack(20004, <<3:8>>)),
    Action = tool:to_binary("-加血 100000"),
    ActionLen= byte_size(Action),
    Data = <<ActionLen:16, Action/binary>>,
    Packet =  pack(11020, Data),    
    gen_tcp:send(Socket, Packet);

handle(Handle, Data, Socket) ->
    ?TRACE("handle error: /~p/~p/~n", [Handle, Data]),
    {reply, handle_no_match, Socket}.

%%玩家列表
read(<<L:32, 10002:16, Num:16, Bin/binary>>) ->
    ?TRACE("client read: ~p ~p ~p~n", [L, 10002, Num]),
    F = fun(Bin1) ->
        <<Id:32, S:16, C:16, Sex:16, Lv:16, Bin2/binary>> = Bin1,
        {Name, Rest} = read_string(Bin2),
        ?TRACE("player list: Id=~p Status=~p Pro=~p Sex=~p Lv=~p Name=~p~n", [Id, S, C, Sex, Lv, Name]),
        Rest
    end,
    for(0, Num, F, Bin),
    ?TRACE("player list end.~n");

read(<<L:32, Cmd:16>>) ->
    ?TRACE("client read: ~p ~p~n", [L, Cmd]);
read(<<L:32, Cmd:16, Status:16>>) ->
    ?TRACE("client read: ~p ~p ~p~n", [L, Cmd, Status]);
read(<<L:32, Cmd:16, Bin/binary>>) ->
    ?TRACE("client read: ~p ~p ~p~n", [L, Cmd, Bin]);
read(Bin) ->
    ?TRACE("client rec: ~p~n", [Bin]).


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
        Error->
            ?TRACE("error: ~p ~n",[Error])
    end.

do_act(Pid)->
    State=gen_server:call(Pid,{get_state}),
    handle(State#robot.act,a,State#robot.socket),
    sleep(2000),
    do_act(Pid).

%%根据机器人状态进行动作
%%根据机器人状态进行动作
ai(Pid)->
    %%?TRACE("start ai  ~p.~n",[Pid]),
    %%更新信息
    gen_server:cast(Pid,{get_state_13001}),
    Random_interval = random:uniform(6000)+3000,
    sleep(Random_interval),    
    State=gen_server:call(Pid,{get_state}),
    case State#robot.act of
        run ->
            case State#robot.hp > 0 of
                true ->
                    case State#robot.status of
                        standing ->

                            if State#robot.step == 0 ->                           
                                 
                                   Tox = rand(5,27),
                                   Toy = rand(30,45),
                                   New_step = 1;
                               true ->
                                
                                   Tox = rand(5,27),%%State#robot.tox,
                                   Toy = rand(30,45),%%State#robot.toy,
                                   New_step = 0                    
                            end,
                            State2=State#robot{tox=Tox,toy=Toy,step=New_step,status=running},
                            gen_server:cast(State#robot.pid,{upgrade_state,State2});
                        running ->

                            if State#robot.x =/= State#robot.tox orelse State#robot.y =/=State#robot.toy ->    %%当前坐标不等于目的坐标
                                   handle(run,{State#robot.x,State#robot.y, State#robot.tox,State#robot.toy},State#robot.socket),
                                   Random_interval2 = round(abs(State#robot.tox - State#robot.x) / 4)* 1000,
                                   sleep(Random_interval2),
                                   handle(run,{State#robot.tox,State#robot.toy, State#robot.tox,State#robot.toy},State#robot.socket);        
                               true ->
                                   State2=State#robot{status=standing},                        %%到达目的地, 换个状态为站
                                   gen_server:cast(State#robot.pid,{upgrade_state,State2})    %%更新机器人状态

                            end;
                        _->
                            ?TRACE("robot status error!~n")
                    end;
                false ->
                    ok%handle(revive,a,State#robot.socket)
            end;
        undefined ->
            ok
    end,
    ai(Pid).

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
