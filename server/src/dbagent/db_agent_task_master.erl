%% Author: zfz
%% Created: 2012-1-4
%% Description: TODO: Add description to db_agent_task_master
-module(db_agent_task_master).

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

%%通过用户id获取师门令数据
get_task_master_by_uid(Uid)->
	case ?DB_MODULE:select_row(task_master,
						  "uid,master_task,refresh_time,create_time",
						  [{uid,Uid}]) of
		[] -> [];
		TaskMaster ->
			NewTaskMaster = list_to_tuple([task_master|TaskMaster]),
			T=NewTaskMaster#task_master{master_task=util:bitstring_to_term(NewTaskMaster#task_master.master_task)},
			ets:insert(?ETS_TASK_MASTER, T), 
			%io:format("get_task_master_by_uid ~p, uid=~p~n", [T,Uid]),
			%io:format("get_task_master_by_uid ~p, uid=~p~n", [NewTaskMaster,Uid]),
			NewTaskMaster
	end.

%%新建玩家师门令数据
insert_task_master(Uid, MasterTaskList, RefreshTime,CreateTime)->
	MasterTaskListStr = util:term_to_string(MasterTaskList),
	?DB_MODULE:insert(task_master, [uid, master_task, refresh_time,create_time],
					  				[Uid, MasterTaskListStr, RefreshTime,CreateTime]).

%%更新玩家师门令数据
update_task_master(Uid, MasterTaskList, RefreshTime)->
	MasterTaskListStr = util:term_to_string(MasterTaskList),
    ?DB_MODULE:update(task_master, [{master_task, MasterTaskListStr}, {refresh_time, RefreshTime}], 
					  [{uid, Uid}]).

%%更新玩家师门令数据
update_task_master(Uid, MasterTaskList)->
	MasterTaskListStr = util:term_to_string(MasterTaskList),
	?DB_MODULE:update(task_master, [{master_task, MasterTaskListStr}], 
					  [{uid, Uid}]).

%%更新玩家师门令时间数据
update_task_master_time(Uid, RefreshTime)->
	?DB_MODULE:update(task_master, [{refresh_time, RefreshTime}], 
					  [{uid, Uid}]).

%%删除玩家师门令数据
delete_task_master(Uid) ->
    ?DB_MODULE:delete(task_master,[{uid,Uid}]).
