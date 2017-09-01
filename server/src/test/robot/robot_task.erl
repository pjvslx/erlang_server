%%--------------------------------------------
%%---------任务机器人相关接口-----------------
%%-----------------by CXF---------------------
%%--------------------------------------------

-module(robot_task).
-include("robot.hrl").

%% gen_server callbacks
-compile(export_all).

accept_task(Socket,TaskProcessId) ->
    io:format("accept_task.....................~n"),
    gen_tcp:send(Socket, pack(30002, <<TaskProcessId:32>>)).

finish_task(Socket,TaskId) ->
    io:format("finish_task.....................~n"),
    Content = string:concat("-taskgoto ",util:term_to_string(TaskId)),
    ContentLen = length(Content),
    NewContent = list_to_binary(Content),
    gen_tcp:send(Socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)).

submit_task(Socket,TaskProcessId) ->
    io:format("submit_task.....................~n"),
    gen_tcp:send(Socket, pack(30004, <<TaskProcessId:32>>)).

parse_task_data(BinData,Result) ->
	case BinData of
		<<Id:32,TaskId:16,State:8,Mark:32,Grade:8,LeftData/binary>> -> 
			Result2 = Result ++ [#task_list{id = Id,taskId = TaskId,state = State,mark = Mark,grade = Grade}],
			parse_task_data(LeftData,Result2);
		_ ->
			Result
	end.

%%随机获得玩家的某个任务
get_rand_taskPid(TaskList) ->
    io:format("VVVVVVVVVVVVVVVVVVVVV333::::::::~p~n",[length(TaskList)]),
    if
        is_list(TaskList) ->
            io:format("VVVVVVVVVVVVVVVVVVVVV666::::::::~p~n",[length(TaskList)]),
            RandNum = rand(length(TaskList)),
            io:format("VVVVVVVVVVVVVVVVVVVVV444::::::::~p~n",[RandNum]),
            TargetTask = lists:nth(RandNum,TaskList);
        true ->
            skip
    end.

handle(get_task,{},Socket) ->
    TotalNum = ?MAX_TASK_NUM,
    gen_tcp:send(Socket, pack(30006, <<TotalNum:8>>)).

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
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

