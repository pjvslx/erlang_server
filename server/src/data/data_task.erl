%%%---------------------------------------
%%% @Module  : data_task
%%% @Author  : csj
%%% @Created : 2010-11-03 17:08:37
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_task).

-compile(export_all).
-include("record.hrl").
-include("common.hrl"). 
-include("task.hrl"). 
-include_lib("stdlib/include/ms_transform.hrl").

%%获取任务模板名字
get_tpl_task_name()->
	temp_task.

%%获取检索task_process所有字典的sql
get_all_sql_task_process()->
	"id,uid,tid,state,trigger_time,type,mark".

%%获取检索daily_task_finish所有字典的sql
get_all_sql_daily_task_finish()->
	"id,uid,td1,td2,td3,td4,td5,td6,td7,td". 


%--------------------------------
%         判断是否是日常任务npcId
%--------------------------------
is_daily_npc_id(NpcId)->
	lists:member(NpcId, ?All_DAILY_NPC_ID_LIST).

%--------------------------------
%         根据npcId获取日常任务类型
%--------------------------------
get_daily_task_type_by_npcId(NpcId)->
	case NpcId of
		?NPC_ID_OF_FACTION_TASK ->
			?FACTION_TASK;
		?NPC_ID_OF_DREAMLAND_TASK ->
			?DREAMLAND_TASK;
		?NPC_ID_OF_GOD_COMMAND_TASK ->
			?GOD_COMMAND_TASK;
		?NPC_ID_OF_CAMP_TASK ->
			?CAMP_TASK;
		?NPC_ID_OF_MINE_TASK ->
			?MINE_TASK;
		?NPC_ID_OF_EXERCISE_TASK ->
			?EXERCISE_TASK;
		?NPC_ID_OF_SELF_IMPROVE_TASK ->
			?SELF_IMPROVE_TASK;
		?NPC_ID_OF_MASTER_TASK ->
			?MASTER_TASK
	end.	

%--------------------------------
%         是否是日常任务类型
%--------------------------------
is_daily_task_type(TaskType)->
	lists:member(TaskType, ?ALL_TASK_TYPE).

%%判断是否是主线任务类型
is_main_task_type(TaskType)->
	TaskType =:= ?MAIN_TASK orelse TaskType =:= ?BRANCHE_TASK.