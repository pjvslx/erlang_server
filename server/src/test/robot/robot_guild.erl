%%%---------------------------------------------
%%% @Module  : robot_guild
%%% @Author  : smxx
%%% @Created : 2013.03.01
%%% @Description: 客户端测试程序
%%%---------------------------------------------
-module(robot_guild).
-include("robot.hrl").
-compile(export_all).

%%断言以及打印调试信息宏
%%不需要时启用 -undefine行
-define(guild_debug, 1).
%-undefine(guild_debug).
-ifdef(guild_debug).
    -define(MYTRACE(Str), io:format(Str)).
    -define(MYTRACE(Str, Args), io:format(Str, Args)).
-else.
    -define(MYTRACE(Str), void).
    -define(MYTRACE(Str, Args), void).
-endif.

%%Robot进程调用 (外部调用)
handle(State) -> 
    ?TRACE("guild handle : begin"),
    if State#robot.guild =:= 0 ->  %%没有帮派情况
         case robot:rand(100) of
            Int when Int =< 90 ->  %%大部分都是加入,不建
                Cmd = 40001;
            _ -> 
                Cmd = 40002
         end,
         case Cmd of   
               40001 -> %查找帮派 -> 
                    IsNotFull = robot:rand(100) rem 2,
                    IsSameGroup = robot:rand(100) rem 2,
                   {ok, BinData} = ptr_40:write(Cmd, [1,IsNotFull,IsSameGroup]);
               40002 -> %建一个帮派
                    %%加建帮令
                    GoodsId = 390004205,
                    Content = string:concat("-addgoods ",util:term_to_string(GoodsId)),
                    Content2 = string:concat(Content," 1"),
                    ContentLen = length(Content2),
                    NewContent = list_to_binary(Content2),
                    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)),
                    %%升级
                    Level = 45,
                    LevelContent = string:concat("-level ",util:term_to_string(Level)),
                    LevelContentLen = length(LevelContent),
                    NewLevelContent = list_to_binary(LevelContent),
                    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<LevelContentLen:16,NewLevelContent:LevelContentLen/binary-unit:8>>/binary>>)),
    

                   GName = "Guild" ++ integer_to_list(State#robot.acid),
                   {ok, BinData} = ptr_40:write(Cmd, [GName, <<" ">>])
         end,
         mysend(State#robot.socket, BinData),
         State;
    true -> 
         if State#robot.guild_post =:= 1 ->  %帮主
                %%{ok, Bin} = ptr_40:write(40031, [0]), %%先处理帮派申请
               %% mysend(State#robot.socket, Bin),
                ActionCmds = [40005, 40010,40031,40034],
                Cmd = lists:nth(robot:rand(length(ActionCmds)), ActionCmds);
         true ->
                %ActionCmds = [40004, 40005, 40006],
                case robot:rand(100) < 20 of 
                    true ->
                        Cmd = 40004;
                    false ->
                        ActionCmds = [40005],
                        Cmd = lists:nth(robot:rand(length(ActionCmds)), ActionCmds)
                end                
         end,
         case Cmd of
               40004 -> %退出帮派
                   {ok, BinData} = ptr_40:write(Cmd, [0]);
               40005 -> %查询帮派成员
                   {ok, BinData} = ptr_40:write(Cmd, [0,0]);
%%                40006 -> %弹劾帮主
%%                    {ok, BinData} = ptr_40:write(Cmd, [0]);
               40010 ->%请求帮派信息
                   {ok, BinData} = ptr_40:write(Cmd, [0,0]);
%%                40011 -> %查看帮派成员的属性值
%%                     
%%                     skip;
               40031 -> %申请列表
                   {ok, BinData} = ptr_40:write(Cmd, [0])
%%                40034 -> %解散帮派
%%                    {ok, BinData} = ptr_40:write(Cmd, [0])
%%                 _ ->
%%                     skip
         end,
         mysend(State#robot.socket, BinData),
         State
    end.

%%Robot进程
handle_cast({guild_create_ok}, State) ->
    NewState = State#robot{guild = 1, guild_post = 1},
    {noreply, NewState};
	
%%随便加入帮派
handle_cast({request_join, GuildId}, State) ->
    if State#robot.guild =:= 0 ->
        {ok, BinData} = ptr_40:write(40003, [GuildId]),
        mysend(State#robot.socket, BinData);
    true -> skip end,
    {noreply, State};

handle_cast({join_guild_approve}, State) ->
    NewState = State#robot{guild = 1, guild_post = 0},
    {noreply, NewState};

handle_cast({refresh_robot_guild_state,[GuildId,Position]}, State) ->
    ?TRACE("refresh_robot_guild_state:GuildId=~p,Position=~p ",[GuildId,Position]),
    NewState = State#robot{guild = GuildId, guild_post = Position},
    {noreply, NewState};

handle_cast({quit_guild}, State) ->
    NewState = State#robot{guild = 0, guild_post = 0},
    {noreply, NewState};

%%帮主对成员的操作
handle_cast({member, Uid}, State) ->
    if State#robot.guild =:= 1 andalso State#robot.guild_post =:= 1 -> %帮主
          ActionCmds = [40033, 40035, 40037],
          Cmd = lists:nth(robot:rand(length(ActionCmds)), ActionCmds),
          case Cmd of
               40033 -> %任命副帮主(帮主操作)
                   Position = robot:rand(2) + 1,  %2妇帮　3长老
                   {ok, BinData} = ptr_40:write(Cmd, [Uid, Position]);
               40035 -> %踢出成员(帮主/副帮主)
                   {ok, BinData} = ptr_40:write(Cmd, [Uid]);
               40037 -> %帮主让位
                   {ok, BinData} = ptr_40:write(Cmd, [Uid])
          end,
          mysend(State#robot.socket, BinData);
    true -> skip end,
    {noreply, State};

%%成员的操作
handle_cast({new_guild_chief, Uid}, State) ->
    if State#robot.guild =:= 1 andalso State#robot.id =:= Uid -> %新帮主
        {noreply, State#robot{guild_post = 1}};
    true ->  {noreply, State} 
    end;

handle_cast(_, State) ->
    {noreply, State}.
 
%%在另一个进程中
do_parse_packet(Socket, Pid, Cmd, BinData) ->%%模拟客户端收包
    %%?MYTRACE("do_parse_packet begin: Cmd: ~p, BinData: ~p~n", [Cmd, BinData]),
    {ok, DecodeMsg} = ptr_40:read(Cmd, BinData),
    %%?MYTRACE("Cmd: ~p, Result: ~p~n", [Cmd, DecodeMsg]),
    case Cmd of
         40001 ->  %%帮派列表
            [_, _, GuildList] = DecodeMsg,
            if GuildList =/= [] ->
                [[GuildId|_T1]|_T2] = GuildList,
                gen_server:cast(Pid, {guild, {request_join, GuildId}});
            true -> skip end;

         40002 ->  %%建帮派成功
            [Result] = DecodeMsg,
            if Result =:= 1 -> gen_server:cast(Pid, {guild, {guild_create_ok}});
            true -> skip end;

         40003 ->  %%加入帮派成功
            skip;

         40004 ->  %%退出帮派成功
            [Result] = DecodeMsg,
            if Result =:= 1 -> gen_server:cast(Pid, {guild, {quit_guild}});
            true -> skip end;

        40005 -> %成员列表
            [StCode|T] = DecodeMsg,
            if StCode =:= 1 andalso length(T) >= 1 ->
                 [Uid|_] = lists:nth(robot:rand(length(T)), T),
                 gen_server:cast(Pid, {guild, {member, Uid}});
            true -> skip end;

         40006 ->  %%弹劾操作返回
            skip;

         40007 ->  %弹劾投票返回
            skip;

         40008 ->  %弹劾结果
            skip;

         40031 -> %%申请列表
            F = fun(Apply) ->
                [Uid|_T] = Apply,
                Ops = robot:rand(2),
                {ok, BinData} = ptr_40:write(40032, [Uid, Ops]),
                mysend(Socket, BinData)
            end,
            lists:foreach(F, DecodeMsg);

        40034 ->  %%解散帮派(帮主)
            [Result] = DecodeMsg,
            if Result =:= 1 -> gen_server:cast(Pid, {guild, {quit_guild}});
            true -> skip end;

        40070 ->   %新成员
            [Uid|_] = DecodeMsg,
            gen_server:cast(Pid, {guild, {member, Uid}});

        40071 ->  %被踢了
            gen_server:cast(Pid, {guild, {quit_guild}});

        40074 -> %被让位了
            [_, _, Uid, _] = DecodeMsg,
            gen_server:cast(Pid, {guild, {new_guild_chief, Uid}});

        40078 ->  %通过加入帮派的申请
            gen_server:cast(Pid, {guild, {join_guild_approve}});
         _ -> skip
    end.
    

mysend(Socket, BinData) ->
    <<_:16, _Cmd:16, _/binary>>  = BinData,
    ?MYTRACE("sending: cmd: ~p~n", [_Cmd]),
    gen_tcp:send(Socket, BinData).%%最后会给玩家进程

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.