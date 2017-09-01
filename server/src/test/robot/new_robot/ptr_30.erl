%%--------------------------------------
%% @Module: ptr_30
%% Author: Auto Generated
%% Created: Thu Feb 28 15:17:18 2013
%% Description: 
%%--------------------------------------
-module(ptr_30).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol:30003 接受任务
%%--------------------------------------
read(30003,<<Result:16>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol 30004 完成任务并挑选奖励
%%--------------------------------------
read(30004,<<Result:16>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol:30005 查询任务npc状态
%%--------------------------------------
read(30005,<<BinData/binary>>) ->
    <<NpcListLen:16, NpcListBin/binary>> = BinData,
    Fun_NpcList = fun(_Idx, {RestBin, ResultList}) ->
        <<NpcId:16, NpcState:8, _NpcList_RestBin/binary>> = RestBin,
        {_NpcList_RestBin, [[NpcId, NpcState]|ResultList]}
    end,
    {_NpcList_DoneBin, NpcList} = lists:foldl(Fun_NpcList, {NpcListBin, []}, lists:seq(1,NpcListLen)),
    {ok, [lists:reverse(NpcList)]};

%%--------------------------------------
%%Protocol:30006 获取指定长度任务列表
%%--------------------------------------
read(30006,<<BinData/binary>>) ->
    <<TaskListLen:16, TaskListBin/binary>> = BinData,
    Fun_TaskList = fun(_Idx, {RestBin, ResultList}) ->
        <<TaskId:16, TaskState:8, TaskProcess:32, _TaskList_RestBin/binary>> = RestBin,
        {_TaskList_RestBin, [[TaskId, TaskState, TaskProcess]|ResultList]}
    end,
    {_TaskList_DoneBin, TaskList} = lists:foldl(Fun_TaskList, {TaskListBin, []}, lists:seq(1,TaskListLen)),
    {ok, lists:reverse(TaskList)};

%%--------------------------------------
%%Protocol:30007 消耗元宝自动完成任务
%%--------------------------------------
read(30007,<<Result:16>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 30501 服务端通知客户端任务的完成条件已满足
%%--------------------------------------
read(30501,<<BinData/binary>>) ->
    <<TaskListLen:16, TaskListBin/binary>> = BinData,
    Fun_TaskList = fun(_Idx, {RestBin, ResultList}) ->
        <<TaskId:16, _TaskList_RestBin/binary>> = RestBin,
        {_TaskList_RestBin, [TaskId|ResultList]}
    end,
    {_TaskList_DoneBin, TaskList} = lists:foldl(Fun_TaskList, {TaskListBin, []}, lists:seq(1,TaskListLen)),
    {ok, lists:reverse(TaskList)};

%%--------------------------------------
%%Protocol: 30502 服务器向客户端发送新的任务进度
%%--------------------------------------
read(30502,<<BinData/binary>>) ->
    <<TaskListLen:16, TaskListBin/binary>> = BinData,
    Fun_TaskList = fun(_Idx, {RestBin, ResultList}) ->
        <<TaskId:16, FinNum:8, NowNum:8, _TaskList_RestBin/binary>> = RestBin,
        {_TaskList_RestBin, [[TaskId, FinNum, NowNum]|ResultList]}
    end,
    {_TaskList_DoneBin, TaskList} = lists:foldl(Fun_TaskList, {TaskListBin, []}, lists:seq(1,TaskListLen)),
    {ok, lists:reverse(TaskList)};

%%--------------------------------------
%%Protocol:30503 通知客户端服务器为玩家触发了自动触发任务(列表)
%%--------------------------------------
read(30503,<<BinData/binary>>) ->
    <<TaskListLen:16, TaskListBin/binary>> = BinData,
    Fun_TaskList = fun(_Idx, {RestBin, ResultList}) ->
        <<TaskId:16, _TaskList_RestBin/binary>> = RestBin,
        {_TaskList_RestBin, [TaskId|ResultList]}
    end,
    {_TaskList_DoneBin, TaskList} = lists:foldl(Fun_TaskList, {TaskListBin, []}, lists:seq(1,TaskListLen)),
    {ok, [lists:reverse(TaskList)]};

%%--------------------------------------
%%Protocol:30505 通知客户端服务器为玩家自动触发了某个任务
%%--------------------------------------
read(30505,<<TaskId:16>>) ->
    {ok, [TaskId]};

%%--------------------------------------
%%Protocol:30506 通知客户端服务器为玩家自动完成了某个任务
%%--------------------------------------
read(30506,<<TaskId:16>>) ->
    {ok, [TaskId]};

%%--------------------------------------
%%Protocol:30507  通知客户端日常任务重置
%%--------------------------------------
read(30507,<<BinData/binary>>) ->
    <<TaskListLen:16, TaskListBin/binary>> = BinData,
    Fun_TaskList = fun(_Idx, {RestBin, ResultList}) ->
        <<Type:8, _TaskList_RestBin/binary>> = RestBin,
        {_TaskList_RestBin, [Type|ResultList]}
    end,
    {_TaskList_DoneBin, TaskList} = lists:foldl(Fun_TaskList, {TaskListBin, []}, lists:seq(1,TaskListLen)),
    {ok, [lists:reverse(TaskList)]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol:30003 接受任务
%%--------------------------------------
write(30003,[TaskId]) ->
    {ok, pt:pack(30003, <<TaskId:16>>)};

%%--------------------------------------
%%Protocol:协议号：30004 完成任务并挑选奖励
%%--------------------------------------
write(30004,[TaskId]) ->
    {ok, pt:pack(30004, <<TaskId:16>>)};

%%--------------------------------------
%%Protocol:30005 查询任务npc状态
%%--------------------------------------
write(30005,[NpcList]) ->
    Fun_NpcList = fun([NpcId]) ->
        <<NpcId:16>>
    end,
    NpcList_Len = length(NpcList),
    NpcList_ABin = any_to_binary(lists:map(Fun_NpcList,NpcList)),
    NpcList_ABinData = <<NpcList_Len:16, NpcList_ABin/binary>>,
    {ok, pt:pack(30005, <<NpcList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol:30006 获取指定长度任务列表
%%--------------------------------------
write(30006,[Len]) ->
    {ok, pt:pack(30006, <<Len:8>>)};

%%--------------------------------------
%%Protocol:30007 消耗元宝自动完成任务
%%--------------------------------------
write(30007,[TaskId]) ->
    {ok, pt:pack(30007, <<TaskId:16>>)};

%%--------------------------------------
%%Protocol: 30501 服务端通知客户端任务的完成条件已满足
%%--------------------------------------
write(30501, _) ->
    {ok, pt:pack(30501, <<>>)};

%%--------------------------------------
%%Protocol: 30502 服务器向客户端发送新的任务进度
%%--------------------------------------
write(30502, _) ->
    {ok, pt:pack(30502, <<>>)};

%%--------------------------------------
%%Protocol:30503 通知客户端服务器为玩家触发了自动触发任务(列表)
%%--------------------------------------
write(30503, _) ->
    {ok, pt:pack(30503, <<>>)};

%%--------------------------------------
%%Protocol:30505 通知客户端服务器为玩家自动触发了某个任务
%%--------------------------------------
write(30505, _) ->
    {ok, pt:pack(30505, <<>>)};

%%--------------------------------------
%%Protocol:30506 通知客户端服务器为玩家自动完成了某个任务
%%--------------------------------------
write(30506, _) ->
    {ok, pt:pack(30506, <<>>)};

%%--------------------------------------
%%Protocol:30507  通知客户端日常任务重置
%%--------------------------------------
write(30507, _) ->
    {ok, pt:pack(30507, <<>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

