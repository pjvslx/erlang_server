%% Author: Administrator
%% Created: 2012-1-4
%% Description: TODO: Add description to db_agent_task
-module(db_agent_task).

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
%%获取任务模板表所有数据
get_all_tpl_task()->
	?DB_MODULE:select_all(data_task:get_tpl_task_name(), "*", [], [], []).

get_all_task_detail()->
	?DB_MODULE:select_all(temp_task_detail, "*", [], [], []).

%%根据玩家id获取对应的已触发任务
get_trigger_task_by_uid(PlayerId)->
	?DB_MODULE:select_all(task_process, 
						  "id,uid,tid,state,trigger_time,type,mark,grade", 
						  [{uid, PlayerId}]).

delete_task_by_uid(PlayerId,Type) ->
    ?DB_MODULE:delete(task_process,
        [{uid, PlayerId},{type,Type}]).
%%根据玩家id, 任务模版id， 获取task_process
get_trigger_task_by_uid_taskId(PlayerId, TaskId)->
	?DB_MODULE:select_all(task_process, 
						  "id,uid,tid,state,trigger_time,type,mark,grade", 
						  [{uid, PlayerId}, {tid, TaskId}]).

%%通过用户id获取日常任务完成表的数据
get_daily_fin_by_uid(PlayerId)->
	?DB_MODULE:select_all(daily_task_finish,
						  "uid,type,state,count_detail,cycle_datil,trigger_detail,reset_time,total,trigger_time",
						  [{uid,PlayerId}]).
%%获取用户已完成任务列表
get_task_finish(PlayerId) ->
	?DB_MODULE:select_row(task_finish, "*", [{uid, PlayerId}],
						  [], [1]).	

%%新建用户已完成任务列表
new_task_finish(PlayerId) ->
	%ValueList = lists:nthtail(1, tuple_to_list(TaskFinish)),
    %[FieldList] = record_info(fields, task_finish),
	_Ret = ?DB_MODULE:insert(task_finish, 
							[uid, td1, td2, td3, td4, td5, td6, td7, td], 
							[PlayerId, 
							 util:term_to_string([]), 
							 util:term_to_string([]),
							 util:term_to_string([]),util:term_to_string([]),
							 util:term_to_string([]),util:term_to_string([]),
							 util:term_to_string([]),util:term_to_string([])]),	
	TaskFinish1 = #task_finish{uid = PlayerId,
								  td1 = [], td2 = [],
								  td3 = [], td4 = [],
								  td5 = [], td6 = [],
								  td7 = [], td = []},
 	TaskFinish1.

 
  %%插入任务进度      
insert_task_process_data(Data)->
	?DB_MODULE:insert_get_id(task_process,
								 [uid, tid, state,trigger_time, type,mark, grade],
								 Data).


%% 同步任务进度数据（更新任务信息包）
upd_task_process_data([State, Mark, Id])->
	_X = ?DB_MODULE:update(task_process, 
								 [{state, State},
								  {mark, Mark}], 
								 [{id, Id}]),  
	_X;
upd_task_process_data([State, Id])-> 
	_X = ?DB_MODULE:update(task_process, 
								 [{state, State}], 
								 [{id, Id}]), 
	_X.

%%更新最新已完成任务列表
save_finish_task(TF) ->
	BD1 = util:term_to_string(TF#task_finish.td1),
	BD2 = util:term_to_string(TF#task_finish.td2),
	BD3 = util:term_to_string(TF#task_finish.td3),
	BD4 = util:term_to_string(TF#task_finish.td4),
	BD5 = util:term_to_string(TF#task_finish.td5),
	BD6 = util:term_to_string(TF#task_finish.td6),
	BD7 = util:term_to_string(TF#task_finish.td7),
	BD = util:term_to_string([]),
	?DB_MODULE:update(task_finish, 
					  [{td1, BD1},{td2, BD2},
					   {td3, BD3},{td4, BD4},
					   {td5, BD5},{td6, BD6},
					   {td7, BD7},{td, BD}], 
					  [{uid, TF#task_finish.uid}]).
%%根据等级区间更新已完成任务列表
save_finish_task(TF, Level) -> 
	if 
		Level < 11 ->
			Bindata = util:term_to_string(TF#task_finish.td1),
			?DB_MODULE:update(task_finish, 
					  [{td1, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 21 ->
			Bindata = util:term_to_string(TF#task_finish.td2),
			?DB_MODULE:update(task_finish, 
					  [{td2, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 31 ->
			Bindata = util:term_to_string(TF#task_finish.td3),
			?DB_MODULE:update(task_finish, 
					  [{td3, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 41 ->
			Bindata = util:term_to_string(TF#task_finish.td4),
			?DB_MODULE:update(task_finish, 
					  [{td4, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 51 ->
			Bindata = util:term_to_string(TF#task_finish.td5),
			?DB_MODULE:update(task_finish, 
					  [{td5, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 61 ->
			Bindata = util:term_to_string(TF#task_finish.td6),
			?DB_MODULE:update(task_finish, 
					  [{td6, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		Level < 71 ->
			Bindata = util:term_to_string(TF#task_finish.td7),
			?DB_MODULE:update(task_finish, 
					  [{td7, Bindata}], 
					  [{uid, TF#task_finish.uid}]);
		true ->
			skip
 end .	

%% 删除任务进度表中已完成任务
syn_db_task_bag_delete(Data)->
	[Id, Uid] = Data, 
	?DB_MODULE:delete(task_process, 
								 [{id, Id},
								  {uid, Uid}]).
%%删除任务进度表中所有玩家任务数据
clean_player_task_process_in_db(PlayerId)-> 
	 ?DB_MODULE:delete(task_process, 
								 [{uid, PlayerId}]). 
%%删除任务完成表中所有玩家任务数据
clean_palyer_task_finish_in_db(PlayerId)->
	?DB_MODULE:delete(task_finish, 
								 [{uid, PlayerId}]).
	
