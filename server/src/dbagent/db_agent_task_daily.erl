%% Author: zfz
%% Created: 2012-1-4
%% Description: 天道令模块
-module(db_agent_task_daily).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions 
%%
%%通过用户id获取日常任务信息数据
get_task_daily_by_uid(Uid)->
	?DB_MODULE:select_all(task_daily,
						  "uid,type,state,used_trigger_count,used_cycle_count,trigger_count,reset_time,total,trigger_time",
						  [{uid,Uid}]).

%%添加新的完成任务列表
insert_task_daily(TaskDaily)->
	{Uid, Type} = TaskDaily#task_daily.uid,
	?DB_MODULE:insert(task_daily, 
						   [uid,type,state,used_trigger_count,used_cycle_count,trigger_count,
							reset_time,total,trigger_time],
						   [Uid, Type, 
							TaskDaily#task_daily.state, TaskDaily#task_daily.used_trigger_count,
							TaskDaily#task_daily.used_cycle_count,TaskDaily#task_daily.trigger_count,
							TaskDaily#task_daily.reset_time, TaskDaily#task_daily.total,
							util:term_to_string(TaskDaily#task_daily.trigger_time)]).

%%重置日常任务信息
reset_task_daily(Uid, TaskType, Time)->
	{NewUid, _Type} = Uid,
	?DB_MODULE:update(task_daily, 
								 [{used_trigger_count, 0},
								  {used_cycle_count, 0},
								  {state,0},
								  {reset_time,Time}
								  ], 
								 [{uid, NewUid},
								  {type, TaskType}]).
%%重置所有日常任务信息
reset_all_task_daily(Uid, Time)->
	?DB_MODULE:update(task_daily, 
								 [{used_trigger_count, 0},
								  {used_cycle_count, 0},
								  {state,0},
								  {reset_time,Time}
								  ], 
								 [{uid, Uid}]).
	
%%更新日常任务信息
update_task_daily(TaskDaily)->
	{Uid, Type} = TaskDaily#task_daily.uid,
	?DB_MODULE:update(task_daily, 
					  [{state,TaskDaily#task_daily.state},
					   {used_trigger_count, TaskDaily#task_daily.used_trigger_count},
					   {used_cycle_count, TaskDaily#task_daily.used_cycle_count},
					   {trigger_count, TaskDaily#task_daily.trigger_count},
					   {total, TaskDaily#task_daily.total},
					   {trigger_time, TaskDaily#task_daily.trigger_time}], 
					  [{uid, Uid},
					   {type, Type}]).

%%更新已接日常任务数量
update_trigger_count(NewTaskDaily)->
	{Uid, Type} = NewTaskDaily#task_daily.uid,
	?DB_MODULE:update(task_daily, 
					  [{trigger_count, NewTaskDaily#task_daily.trigger_count}],
					  [{uid, Uid},
					   {type, Type}]).

%%删除日常任务完成表中所有玩家任务数据
clean_task_daily_by_uid(Uid) ->
	?DB_MODULE:delete(task_daily, 
								 [{uid, Uid}]).
