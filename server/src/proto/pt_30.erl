%%%-----------------------------------
%%% @Module  : pt_30
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.01.13
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_30).
-export([read/2, write/2]).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%

%% 接受日常任务， 当前任务进度id
read(30002, <<TaskProcessId:32>>) ->
    {ok, [TaskProcessId]};  
 
%% 接受任务
read(30003, <<TaskId:16>>) ->
    {ok, [TaskId]};  

%% 完成任务
read(30004, <<TaskProcessId:32>>)->
		{ok,[TaskProcessId]};

%% 检测npc状态
read(30005, <<ILen:16, Bin/binary>>) ->
    F = fun(_, {TB, Result}) ->
            <<NpcId:16, NewTB/binary>> = TB,
            {ok, {NewTB, Result++[NpcId]}}
    end,
    {ok,{ _, NpcList}} = util:for(1, ILen, F, {Bin, []}),
    {ok, [NpcList]};
%%获取指定大小的任务列表
read(30006, <<Size:8>>) ->
    {ok, [Size]};
%%消耗元宝完成任务
read(30007,<<TaskProcessId:32>>)->
	{ok, [TaskProcessId]};
%% 获取npc任务信息 
read(30008,<<NpcId:16>>) ->
    {ok, [NpcId]};
%%通知服务器玩家与某任务npc对话
read(30100,<<NpcId:16>>)->
    {ok, [NpcId]};
%%获取师门令任务列表
read(30601, _)->
    {ok, []};
%%领取师门令任务
read(30602, <<Index:8,TaskId:16>>)->
	{ok, [Index, TaskId]};
%%免费刷新师门令任务列表
read(30603, _)->
	{ok, []};
%%一键刷新师门令任务列表
read(30604, _)->
	{ok, []};
%%元宝刷新师门令任务列表
read(30606, _)->
	{ok, []};
%%获取全部天道令数据
read(30701, _)->
	{ok, []};
%%发布天道令任务
read(30702, <<HeavenId:16>>)->
	{ok, [HeavenId]};
%%领取天道令任务
read(30703, <<HeavenId:16>>)->
	{ok, [HeavenId]};
%%获取领取的， 发布的天道令数据
read(30704, _)->
	{ok, []};
%%快速完成天道令
read(30705, <<Id:32>>)->
	{ok, [Id]};
%%查询日常任务
read(30801,_) ->
	{ok, []};

read(_Cmd, R) -> 
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% --- NPC对话开始 ----------------------------------
 
%% 接受任务
write(30003,[Result, TaskProcessId])->  
	{ok, pt:pack(30003, <<Result:16, TaskProcessId:32>>)};

%% 完成任务
write(30004,[Result])->
	{ok, pt:pack(30004, <<Result:16>>)};
 
%%通知客户端npc状态
write(30005,[List,Len])->
	F = fun({NpcId,State}) -><<NpcId:16,State:8>> end,
	Data = tool:to_binary([F(Item)|| Item <- List]),
	{ok, pt:pack(30005, tool:to_binary([<<Len:16>>|Data]))};

%%获取任务列表
write(30006,[List,Len]) ->  
	F = fun({Id,TaskId,State,Mark, Grade}) ->  
				<<Id:32,TaskId:16,State:8,Mark:32,Grade:8>> 
		end,  
    Data = tool:to_binary([F(Task)|| Task <- List]),
	{ok, pt:pack(30006, tool:to_binary([<<Len:16>>|Data]))};
%%消耗元宝自动完成任务 
write(30007,Result) ->  
	{ok, pt:pack(30007, <<Result:16>>)};

%%通知客户端指定任务进度更新
write(30501,[List,Len]) ->
	F = fun({Id,Tid,State,NowNum, Grade}) -><<Id:32, Tid:16,State:8,NowNum:32, Grade:8>> end,
	Data = tool:to_binary([F(Task)|| Task <- List]),
	{ok, pt:pack(30501, tool:to_binary([<<Len:16>>|Data]))};
 
%%通知客户端服务器为玩家触发了自动触发任务
%%废弃
write(30503,[List,Len])->
	F = fun(Temp_task) -><<Temp_task:16>> end,
	Data = tool:to_binary([F(Task)|| Task <- List]),
	{ok, pt:pack(30503, tool:to_binary([<<Len:16>>|Data]))};


write(30505,[TaskId])->  
		{ok, pt:pack(30505, <<TaskId:16>>)};
%%通知客户端有自动完成任务(单个)
write(30506,[TaskProcessId])->  
		{ok, pt:pack(30506, <<TaskProcessId:32>>)};
%%通知客户端日常任务重置
write(30507,[List,Len])->  
	F = fun(Task_Type) -> 
				<<Task_Type:8>> end,
	Data = tool:to_binary([F(Task)|| Task <- List]),
	{ok, pt:pack(30507, tool:to_binary([<<Len:16>>|Data]))}; 
%%获取npc任务信息 
write(30008,[TaskList]) ->
    Fun_TaskList = fun({Id,TaskId,TaskState}) ->
        <<Id:32, TaskId:16,TaskState:8>>
    end,
    TaskList_Len = length(TaskList),
    TaskList_ABin = any_to_binary(lists:map(Fun_TaskList,TaskList)),
    TaskList_ABinData = <<TaskList_Len:16, TaskList_ABin/binary>>,
    {ok, pt:pack(30008, <<TaskList_ABinData/binary>>)};

%%师门令任务列表
write(30601, [TaskMasterList, Len,CardNum,GoldNum]) ->
	F = fun({TaskId, Grade, State, AwardExpCount}) ->
				<<TaskId:16, Grade:8, State:8, AwardExpCount:32>>
		end,
	Data = tool:to_binary([F(TaskMaster) || TaskMaster <- TaskMasterList]),
	{ok, pt:pack(30601, tool:to_binary([<<Len:16>>,<<CardNum:16>>,<<GoldNum:32>> | Data]))};

%%推送刷新师门令列表结果
write(30603, [Result, Value]) ->
	{ok, pt:pack(30603, <<Result:16, Value:32>>)};

%%服务器推送 师门令领取次数， 当前可用次数
write(30605, [ReceiveTimes, RarallelTimes]) ->
	{ok, pt:pack(30605, <<ReceiveTimes:8, RarallelTimes:8>>)};

%%元宝刷新结果
write(30606,[Result,GoldNum]) ->
    {ok, pt:pack(30603, <<Result:16, GoldNum:32>>)};

%%通知客户端 天道令数据
write(30701,[List,Len])->
	F = fun({HeavenId, HeavenCount, AwardItemId, AwardItemCount}) ->
				<<HeavenId:16, HeavenCount:16, AwardItemId:32, AwardItemCount:32>>
		end,
	Data = tool:to_binary([F(HeavenItem) || HeavenItem <- List]),
	{ok, pt:pack(30701, tool:to_binary([<<Len:16>> | Data]))};

%%玩家发布天道令结果
write(30702,[Result])->
	{ok, pt:pack(30702, <<Result:16>>)};

%%玩家领取天道令结果
write(30703,[Result])->
	{ok, pt:pack(30703, <<Result:16>>)};

%%玩家天道令数据
write(30704,[MaxPublish, PublishHeavens, MaxReceive, ReceiveHeavens])->
	{PubTian, PubDi, PubXuan, PubHuang} = PublishHeavens,
	{RecTian, RecDi, RecXuan, RecHuang} = ReceiveHeavens,
	{ok, pt:pack(30704, <<MaxPublish:16, PubTian:8, PubDi:8, PubXuan:8, PubHuang:8, 
						  MaxReceive:16, RecTian:8, RecDi:8, RecXuan:8, RecHuang:8>>)};
%%玩家元宝完成天道令
write(30705,[Result])->
	{ok, pt:pack(30705, <<Result:16>>)};	

%%查询日常任务
write(30801,[DailyTask]) ->
	Len = length(DailyTask),
	Bin = tool:to_binary([pack_daily_task(D) || D <- DailyTask]),
	{ok, pt:pack(30801,<<Len:8,Bin/binary>>)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(csj_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.
 
any_to_binary(Any) ->
    tool:to_binary(Any).

pack_daily_task(DailyTaskData) ->
	{TaskType,Accept,Contribute} = DailyTaskData,
	<<TaskType:16,Accept:16,Contribute:16>>.
