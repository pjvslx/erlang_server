%%%-----------------------------------
%%% @Module  : lib_task
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.01.13
%%% @Description: 任务
%%%-----------------------------------
-module(lib_task).
-compile(export_all).
-include("common.hrl").  
-include("record.hrl").  
-include("log.hrl"). 
-include("task.hrl"). 
-include("leader.hrl").
-include("goods.hrl").

%--------------------------------
%        角色登陆服务器初始化
%--------------------------------  
%%初始化进程字典角色任务，日常数据 
init_pid_data()-> 
	put({role_task_list,0},[]),
	put({role_task_list,1},[]),
	put({role_task_list,2},[]),
	put({daily_task_list,0},[]),
	put({daily_task_list,1},[]),
	put({daily_task_list,2},[]). 

%%初始化整个任务模块数据
init_task_module(PlayerStatus)->
	?TASK_TRACE("start to init player task info ,player id is ~p ~n",[PlayerStatus#player.id]),
	lib_task:init_pid_data() ,
 	lib_task:init_trigger_task(PlayerStatus#player.id),
	lib_task:init_daily_task_finish(PlayerStatus#player.id),
	lib_task:init_fin_role_task(PlayerStatus#player.id),
	lib_task:refresh_active(PlayerStatus), 
	lib_task_master:init_task_master(PlayerStatus),
	lib_task_heaven:init_task_heaven(PlayerStatus),
	?TASK_TRACE("init player task info finish,player id is ~p ~n",[PlayerStatus#player.id]).

%%初始化玩家已触发任务
%%修改改用数据库主键做key
init_trigger_task(PlayerId)-> 
	Result = db_agent_task:get_trigger_task_by_uid(PlayerId),
	?TASK_TRACE("begin to init player task process ,get player ~p task process list -> ~p ~n",[PlayerId,Result]),
	lists:foreach(fun(Task)->
						  D = list_to_tuple([task_process|Task]),
						  TaskInfo = D#task_process{
													%id = {PlayerId,D#task_process.tid},
													mark = data_agent:task_valToTagCode(D#task_process.mark)
												   },
						  ?TASK_TRACE("TaskInfo-info:~p~n", [TaskInfo]),
						  insert_pid(TaskInfo#task_process.type,TaskInfo#task_process.state,TaskInfo#task_process.id),
					 	  ets:insert(?ETS_TASK_PROCESS, TaskInfo)
				  end, Result).

%%插入触发主线,支线任务到进程字典
%%用数据库主键key
insert_pid(Type,State,TaskProcessId)
  when Type =:= ?MAIN_TASK orelse Type =:=?BRANCHE_TASK -> 
	case get({role_task_list,State}) of 
		undefined-> 
			put({role_task_list,State},[TaskProcessId]),
			?ERROR_MSG("pid_dict not exit ~n",[]);
		Result->
			%?TASK_TRACE("insert_pid, State=~p, Result=~p,TaskProcessId=~p~n", [State, Result, TaskProcessId]),
			%?TASK_TRACE("insert_pid, State=~p, Result2=~p,TaskProcessId=~p~n", [State, Result++[TaskProcessId], TaskProcessId]),
			put({role_task_list,State},Result++[TaskProcessId]),
			
			TaskList = get({role_task_list,State}),
			?TASK_TRACE("insert_pid, State=~p, data=~p,TaskProcessId=~p~n", [State, TaskList, TaskProcessId])
	end;
%%插入触发日常任务到进程字典
insert_pid(_,State,TaskProcessId) -> 
	case get({daily_task_list,State}) of 
		undefined-> 
			put({daily_task_list,State},[TaskProcessId]),
			?ERROR_MSG("pid_dict not exit ~n",[]);
		Result->
			put({daily_task_list,State},Result++[TaskProcessId])
	end.

%%初始化玩家日常任务完成列表
init_daily_task_finish(PlayerId)->  
	Result = db_agent_task_daily:get_task_daily_by_uid(PlayerId),
	?TASK_TRACE("begin to init player daily task finish ,get player ~p daily_task_finish list ~n",[PlayerId]),
	%%所有任务类型
	AllTaskType = ?ALL_TASK_TYPE,
	AllLen = length(AllTaskType),
	case length(Result) of
		0->%%玩家初次登陆游戏,为玩家初始化所有日常任务数据
			add_player_task_daily(PlayerId);
		AllLen ->%%玩家之前已经登陆过游戏,直接加载玩家数据
			update_task_daily_reset_time(Result,PlayerId);
		_ ->%%玩家有部分日常任务数据丢失,重新初始化丢失部分,直接加载已有部分
			update_task_daily_reset_time(Result,PlayerId),
			add_player_task_daily(PlayerId)
	end.

%%添加玩家日常任务模块信息
add_player_task_daily(PlayerId)->
	AllTaskType = ?ALL_TASK_TYPE,
	lists:foreach(fun(TaskType) ->
						  case get_one_daily_task_fin(PlayerId, TaskType) of
							  [] ->
								  DataFirstTime = util:getDataFirstTime(),
								  TaskDaily = #task_daily{uid = {PlayerId, TaskType},
														  reset_time = DataFirstTime,
														  trigger_time = date()},
								  ets:insert(?ETS_TASK_DAILY, TaskDaily),
								  db_agent_task_daily:insert_task_daily(TaskDaily);
							  _ ->skip
						  end
				  end, AllTaskType).

%%将数据库中的日常任务完成数据结构化为ets数据
prase_original_daily_data(TaskDaily)->
	TaskDaily#task_daily{uid = {TaskDaily#task_daily.uid,TaskDaily#task_daily.type},
					trigger_time = data_agent:task_valToTagCode(TaskDaily#task_daily.trigger_time)
				   }.

%%将玩家日常任务表的数据加载到ets中
insert_daily_fin_in_ets(TaskDaily)->    
	NewTaskDaily = prase_original_daily_data(TaskDaily), 
	ets:insert(?ETS_TASK_DAILY, NewTaskDaily).

%%移除师门令/天道令日常任务数据 byCXF
removeMasterHeavenTask(PlayerId) ->
    PlayerStatus = lib_player:get_player(PlayerId),
    DailyTaskList = get({daily_task_list,0}),

    Fun = fun(TaskProcessId,Ret) ->
            ets:delete(?ETS_TASK_PROCESS,TaskProcessId),
            put({daily_task_list,0},[]),
            db_agent_task:delete_task_by_uid(PlayerStatus#player.id,9),
            lib_task:get_all_task_2_client(PlayerStatus,12),
            Ret
    end,

    lists:foldl(Fun, 0, DailyTaskList).

%%用户登录时更新日常任务完成数据,尝试重置玩家日常任务
update_task_daily_reset_time(Result,PlayerId)->
	lists:foreach(fun(Task)->
						  D = list_to_tuple([task_daily|Task]), 
						  {ThatMidNight,_} = util:get_midnight_seconds( D#task_daily.reset_time),
						  Now = util:unixtime(),
						  TimeSpend = Now-ThatMidNight,

						  if TimeSpend >=?RESET_TIME ->
                                  if
                                      D#task_daily.type =:= 4 orelse D#task_daily.type =:= 9 ->
                                          removeMasterHeavenTask(PlayerId);
                                      true ->
                                          skip
                                  end,
                                  reset_task_daily(prase_original_daily_data(D), Now);
							 true->
                                 insert_daily_fin_in_ets(D)
						  end
				  end, Result). 

%%重置日常任务
reset_task_daily(TaskDaily, Now)->
    NewTaskDaily = TaskDaily#task_daily {state = 0, 
        trigger_count = 0,
													  used_trigger_count = 0,
													  used_cycle_count = 0},
	ets:insert(?ETS_TASK_DAILY, NewTaskDaily),
	db_agent_task_daily:reset_task_daily(NewTaskDaily#task_daily.uid, NewTaskDaily#task_daily.type, Now),
    NewTaskDaily.

%%初始化角色已完成主线/支线任务
init_fin_role_task(PlayerId)-> 
	case db_agent_task:get_task_finish(PlayerId) of
		[] ->
			NewTaskFinish = db_agent_task:new_task_finish(PlayerId);
		Result -> 
			List = [task_finish | Result],			
			TaskFinish = list_to_tuple(List), 
			TF = TaskFinish#task_finish{td1 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td1)),
										td2 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td2)),
										td3 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td3)),
										td4 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td4)),
										td5 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td5)),
										td6 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td6)),
										td7 = util:string_to_term(binary_to_list(TaskFinish#task_finish.td7))},
			AllFinish = lists:flatten([TF#task_finish.td1, 
						   TF#task_finish.td2,
						   TF#task_finish.td3,
						   TF#task_finish.td4,
						   TF#task_finish.td5,
						   TF#task_finish.td6,
						   TF#task_finish.td7]),
			NewTaskFinish = TF#task_finish{td = AllFinish}				
	end,   
	?TASK_TRACE("begin to init player role task finish ,get player ~p fin_role_task list -> ~p ~n",[PlayerId,NewTaskFinish#task_finish.td]),
	ets:insert(?ETS_TASK_FINISH, NewTaskFinish).
 

%-----------------------------
%         触发任务
%-----------------------------   
				
%%判断任务触发条件
check_trigger_condition(TD, PS,_TaskType) 
  when is_record(TD, tpl_task)->
	Result = check_trigger_main(TD, PS),   
	Result =:= true ;
check_trigger_condition(_,_,_)->
	false.

%%尝试触发任务, 添加任务
trigger_task(TaskId, PS) ->
	case tpl_task:get(TaskId) of
		%%没有这个任务，不能接
		[] ->{false,?TASK_NOT_EXIT};
		TD ->
			case data_task:is_main_task_type(TD#tpl_task.type) of
				true ->
                    %%写操作日志
                    db_agent_log:add_task_log(PS#player.id,PS#player.account_name,PS#player.career,PS#player.level,TD#tpl_task.tid,1,util:unixtime()), 
					trigger_main_task(TD, PS);
				_ ->
					trigger_daily_task(TD, PS)
            end
	end. 

%%接日常任务
%%帮派任务, 阵营任务,聚宝阁任务, 千锤百炼任务, 自强不息
accept_task_by_task_process_id(TaskProcessId, PS)->
	case get_task_process(TaskProcessId) of 
		null ->
			{false,?TASK_NOT_IN_PROCESS};
		TaskProcess->
            lib_task:call_event(PS,lv,{PS#player.level}),%%在接任务的时候判断该任务是否是升级任务(若达到条件直接完成) byCXF
			case check_auto_fin_for_accpet(TaskProcess, PS) of
				true->
					%%走完成任务流程
					%%删除进程中数据
					del_finish_task(TaskProcess#task_process.type, TaskProcess#task_process.id,?TASK_CAN_TRIGGER),
					{false,?TASK_FINISH_BY_AUTO};
				_->
					case TaskProcess#task_process.state of 
						?TASK_NOT_FINISH ->
							{false,?TASK_ALREADY_TRIGGER};
						?TASK_FINISH ->
							{false,?TASK_ALREADY_FINISH};
						?TASK_CAN_TRIGGER->
							%%如果是对话行任务，直接完成
							case tpl_task:get(TaskProcess#task_process.tid) of
								Task when is_record(Task, tpl_task) ->
									TaskState = get_task_process_state_for_accept(Task),
									upd_task_2_db_and_mem(TaskProcess, TaskState),
									case ets:lookup(?ETS_TASK_PROCESS, TaskProcess#task_process.id) of 
										[]->skip;
										[NewTaskProcess] ->
											send_task_process_list(PS, [NewTaskProcess])
									end,
                                    if
                                        Task#tpl_task.target_type =:= 12 ->
                                            NewPlayerOther = PS#player.other#player_other{
                                                step_check_tasks = [{tid,Task#tpl_task.tid} | PS#player.other#player_other.step_check_tasks]
                                            },
                                            NewPs = PS#player{other = NewPlayerOther};
                                        true ->
                                            NewPs = PS
                                    end,
                                    %%写操作日志
                                    db_agent_log:add_task_log(PS#player.id,PS#player.account_name,PS#player.career,PS#player.level,Task#tpl_task.tid,1,util:unixtime()), 
									{true, NewPs, TaskProcess#task_process.id};
								_->
									{false,?TASK_NOT_EXIT}
							end;
						_->{false,?FAIL_FOR_OTHER}
					end
			end
	end.

%%添加主线任务
trigger_main_task(Task, PS) ->
	?TASK_TRACE("trigger_main_task, tid=~p, pid=~p ~n", [Task#tpl_task.tid, PS#player.id]),
	Result = check_trigger_main(Task, PS),
	case Result of
		true -> 
			TaskProcess = do_add_task(Task,PS),  
			send_task_process_list(PS, [TaskProcess]),
			refresh_active(PS),
			{true,PS, TaskProcess#task_process.id};
		_ -> {false, Result}
	end.

%%任务限制判定, 判定主线任务
%%排除重复， 等级， 职业， 性别， 前置任务等
check_trigger_main(TD, PS) ->     
	case check_if_in_trigger(TD#tpl_task.tid) of
		%%该任务已经触发过了，不能接！
		true -> ?TASK_ALREADY_TRIGGER;
		false -> 
			case check_lvl(TD,PS) of
				%%您的等级不足，不能接
				false ->?TASK_LEVEL_NOTENOUGHT;
				true -> 
					case is_finish_task_id(TD#tpl_task.tid, PS#player.id)of	
						%%该任务已完成
						true->?TASK_ALREADY_FINISH;
						false -> %%判断玩家职业
							case check_career(TD#tpl_task.career,PS#player.career)of
								true-> %%判断玩家性别
									case check_sex(TD#tpl_task.gender,PS#player.gender) of
										true->
											%%判断前置任务
											case check_pre_task(TD#tpl_task.pre_tid,PS#player.id) of
												true->
													true;
												false->?PRE_TASK_UNFIN 
											end;
										false ->?TASK_WRONG_SEX 
									end;
								false->?TASK_WRONG_CAREER 
							end
					end
			end  
	end.

%%添加日常任务
%%师门令、天道了任务调用
trigger_daily_task(Task, PS) ->
	?TASK_TRACE("trigger_daily_task, tid=~p, pid=~p ~n", [Task#tpl_task.tid, PS#player.id]),
	%%判定日常任务限定条件
	case get_one_daily_task_fin(PS#player.id, Task#tpl_task.type) of
		[TaskDaily] ->
			TempTaskDetail = tpl_task_detail:get(Task#tpl_task.type),
			{Result, CanTriggerCount} = get_trigger_daily_count(TaskDaily, TempTaskDetail),
			case Result of
				?CAN_TRIGGER ->
					case CanTriggerCount of 
						0-> 
							{false, Result};
						_->
							TaskProcess = do_add_task(Task,PS), 
							send_task_process_list(PS, [TaskProcess]),
							update_task_daily_trigger_count(TaskDaily, TempTaskDetail, 1),
							{true, PS, TaskProcess#task_process.id}
					end;
				_->
					{false, Result}
			end;	
		_ ->
			{false, skip}
	end.

%%检查日常任务条件
check_trigger_daily(TaskDaily, TempTaskDetail)->
	case  check_time_limit(TempTaskDetail#temp_task_detail.time_limit, util:conver_time(time())) of 
		true ->
			if TaskDaily#task_daily.trigger_count >= TempTaskDetail#temp_task_detail.meanw_trigger ->
				   ?OUT_OF_MAX_MEANW_TIME;
			   true ->
				   if TaskDaily#task_daily.used_cycle_count >= TempTaskDetail#temp_task_detail.cycle_time ->
						  ?OUT_OF_MAX_CYCLE_TIME;
					  true ->
						  if TaskDaily#task_daily.used_trigger_count >= TempTaskDetail#temp_task_detail.trigger_time ->
								 ?OUT_OF_MAX_TRIGGER_TIME;
							 true->
								 ?CAN_TRIGGER
						  end
				   end	  
			end;
		_->
			?OUT_OF_TIME_LIMIT
	end.

%%得到可以接的日常任务数量
get_trigger_daily_count(TaskDaily, TempTaskDetail)->
	case  check_time_limit(TempTaskDetail#temp_task_detail.time_limit, util:conver_time(time())) of
		true ->
			if TaskDaily#task_daily.trigger_count >= TempTaskDetail#temp_task_detail.meanw_trigger ->
				   {?OUT_OF_MAX_MEANW_TIME, 0};
			   true->
				   CanTriggerCount = TempTaskDetail#temp_task_detail.meanw_trigger - TaskDaily#task_daily.trigger_count,
				   %%判断是否超出本轮最大次数
				   if TaskDaily#task_daily.used_cycle_count >= TempTaskDetail#temp_task_detail.cycle_time ->
						  %%已经超出本来最大次数， 判断是否还有轮数
						  if TaskDaily#task_daily.used_trigger_count >= TempTaskDetail#temp_task_detail.trigger_time ->
								 {?OUT_OF_MAX_TRIGGER_TIME, 0};
							 true->
								 %%启动新一轮日常任务
								 CanTriggerCount2 = min(CanTriggerCount, TempTaskDetail#temp_task_detail.cycle_time),
								 ?TASK_TRACE("get_trigger_daily_count, CanTriggerCount2=~p~n", [CanTriggerCount2]),
								 {?CAN_TRIGGER, CanTriggerCount2}
						  end;
					  true-> 
						  CanTriggerCount1 = min(CanTriggerCount, TempTaskDetail#temp_task_detail.cycle_time - TaskDaily#task_daily.used_cycle_count),
						  ?TASK_TRACE("get_trigger_daily_count, CanTriggerCount1=~p~n", [CanTriggerCount1]),
						  {?CAN_TRIGGER, CanTriggerCount1}
				   end
			end;
		_-> {?OUT_OF_TIME_LIMIT, 0} 
	end.

%%添加玩家可接的日常任务
add_can_accept_daily_task(PS, TaskTypes)->
	?TASK_TRACE("add_can_accept_daily_task, TaskTypes is ~p~n", [TaskTypes]),
	%AllType = ?ALL_CAN_ACCEPT_TYPE,
	F = fun(TaskType, TaskProcess)->
				case tpl_task_detail:get(TaskType) of
					TempTaskDetail when is_record(TempTaskDetail, temp_task_detail)  ->
						%%判断等级是否满足条件  TODO
                        TempTaskDaily = tpl_task_daily:get(TaskType),
                        if
                            is_record(TempTaskDaily,tpl_task_daily) ->
                                MinLevel = TempTaskDaily#tpl_task_daily.level_limit;
                            true ->
                                MinLevel = 30
                        end,
                        
                        %%对自强不息任务涉及的世界等级进行特判
                        case TaskType =:= ?SELF_IMPROVE_TASK andalso lib_world_level:get_task_status(PS#player.level) =:= false of
                            true ->
                                SpecailCheckCanTriggle = false;
                            false ->
                                SpecailCheckCanTriggle = true
                        end,

                        case PS#player.level >= MinLevel andalso SpecailCheckCanTriggle =:= true of 
							true ->
								%%判断当天是否超出限制
								case get_one_daily_task_fin(PS#player.id, TaskType) of 
									[TaskDaily] when is_record(TaskDaily, task_daily)->
										{Result, CanTriggerCount} = get_trigger_daily_count(TaskDaily, TempTaskDetail),
										?TASK_TRACE("add_can_accept_daily_task INFO:Result=~p, CanTriggerCount=~p~n", [Result, CanTriggerCount]),
										case Result of 
											?CAN_TRIGGER ->
												case CanTriggerCount of 
													0 ->

                                                        TaskProcess;
													_ ->
														TaskIdList = get_random_daily_task(task_daily, {CanTriggerCount, PS, TaskType}),
														?TASK_TRACE("add_can_accept_daily_task, can accept TaskIdList ~p~n", [TaskIdList]),
														%%添加数据库
														case length(TaskIdList) of
															0->
                                                                TaskProcess;
															_->
																TaskProcessList = lists:map(fun(Tid)->
																									case tpl_task:get(Tid) of 
																										[] -> [];
																										Task ->
																											AddTaskProcess = add_task_process(Task, PS, ?TASK_CAN_TRIGGER, ?TASK_COMMON_GRADE),
																											AddTaskProcess
																									end
																							end, TaskIdList),
																update_task_daily_trigger_count(TaskDaily, TempTaskDetail, length(TaskIdList)),
																SrcList = util:check_list(TaskProcess),
																SrcList ++ TaskProcessList
														end
												end;
											_->
												TaskProcess
										end;
									_->TaskProcess
								end;
							_->TaskProcess
						end;
					_->TaskProcess
				end
		end,
	RetTaskList = lists:foldl(F, 0, TaskTypes),
	?TASK_TRACE("add_can_accept_daily_task, success, ~p~n", [RetTaskList]),
	NewTaskList = util:check_list(RetTaskList),
	NewTaskList.


%%触发日常任务时更新日常任务进度完成表
%%used_cycle_count:本轮已使用次数
%%used_trigger_count:已使用的次数
%%trigger_count: 已接受的任务数量
update_task_daily_trigger_count(TaskDaily, TempTaskDetail, DeltaCount) ->
	%%新增同时触发任务数量, 本轮数量
	NewTaskDaily = TaskDaily#task_daily{used_cycle_count = TaskDaily#task_daily.used_cycle_count + DeltaCount, 
										trigger_count = TaskDaily#task_daily.trigger_count + DeltaCount},
	%%超出本来最大次数，使用轮数+1
	if NewTaskDaily#task_daily.used_cycle_count >= TempTaskDetail#temp_task_detail.cycle_time 
		 -> NewTaskDaily1 = NewTaskDaily#task_daily{used_trigger_count = NewTaskDaily#task_daily.used_trigger_count + 1,
													used_cycle_count = 0},
			update_task_daily_to_db_and_ets(NewTaskDaily1);
	   true ->
		   update_task_daily_to_db_and_ets(NewTaskDaily)
	end.

%%更新日常任务到数据， 和ets
update_task_daily_to_db_and_ets(TaskDaily)->
	ets:insert(?ETS_TASK_DAILY, TaskDaily),
	db_agent_task_daily:update_task_daily(TaskDaily).

%%获取指定日常完成任务
get_one_daily_task_fin(PlayerId,Type)->
	ets:lookup(?ETS_TASK_DAILY, {PlayerId,Type}).

%%进入检测时间限制逻辑(判断任务是否在可接时间段)
check_time_limit(TimeList,Now)->
	case TimeList of
		[]->true;
		_->
			lists:member(true,lists:map(fun(Time)->
												case Time of
													{Begin,End}->
														Now >= Begin andalso End >= Now;
													_->
														?ERROR_MSG("time data formater error~n",[]),
														false
												end
										end, TimeList))
	end.
	
%%判定玩家性别
check_sex(TaskSex,PlayerSex)->
	case TaskSex of
		?NULL_SEX->true;
		PlayerSex->true;
		_-> false 
	end.

%%检测前置任务是否完成
check_pre_task(PreTaskId,PlayerId)->
	case PreTaskId of 
		-1->true;
		0->true;
		PreTaskId when is_integer(PreTaskId)->
			is_finished_task_id(PreTaskId,PlayerId);
		_->
			?WARNING_MSG("data error in pre_tid of ~p in temp_task",[PreTaskId]),
			false 
	end.
	 
%%判定玩家职业
check_career(TaskPro,PlayerPro)-> 
	case TaskPro of
		?NULL_CAREER -> true;
		PlayerPro ->true;
		_-> false 
	end.

%% 判断主线/支线任务是否已触发过
%% zfz主线任务不能够有重复的id
check_if_in_trigger(TaskId) ->
	TaskProcessIdList = get_all_role_task(),
	lists:member(TaskId, lists:map(fun(TaskProcessId)-> 
										   case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
											   [TaskProcess] -> TaskProcess#task_process.tid;
											   [] ->skip
										   end	  
								   end, TaskProcessIdList)).

%% 是否是已经完成的taskId
is_finish_task_id(TaskId, PlayerId)->
	case get_finish_task(PlayerId) of
		[] -> true;	%%无完成任务列表，说明玩家任务数据未正常加载，不让接任务的，不然在卡时可能会重复接做过的任务
		TF -> 
			lists:member(TaskId, TF#task_finish.td)
	end.

%% 是否是已经完成(并已领取相应奖励)的taskId
is_finished_task_id(TaskId, PlayerId)->
	case get_finish_task(PlayerId) of
		[] -> true;	%%无完成任务列表，说明玩家任务数据未正常加载，不让接任务的，不然在卡时可能会重复接做过的任务
		TF ->
            case db_agent_task:get_trigger_task_by_uid_taskId(PlayerId,TaskId) of
                TaskProcess when is_list(TaskProcess) andalso length(TaskProcess) > 0 ->
                    false;
                _ ->
                    lists:member(TaskId, TF#task_finish.td)
            end
	end.

%%等级判定
check_lvl(TD,PS)->
	PS#player.level >= TD#tpl_task.level . 

%% 获取已完成任务
get_finish_task(PlayerId)   ->
	case ets:lookup(?ETS_TASK_FINISH, PlayerId) of
		[] ->[];
		[TF] -> TF
	end.

%%添加角色任务判断处理逻辑
do_add_task(TD,PStatus)when TD#tpl_task.target_type =:= ?NPC_TALK_EVENT-> 
	add_task_process(TD,PStatus, ?TASK_FINISH, ?TASK_COMMON_GRADE);
do_add_task(TD,PStatus)-> 
	add_task_process(TD,PStatus, ?TASK_NOT_FINISH, ?TASK_COMMON_GRADE).
%%添加角色任务
add_task_process(TD, PStatus, State, Grade)->
	ResMark =  [TD#tpl_task.target_type|TD#tpl_task.target_property],
	TaskType = TD#tpl_task.type,
	Date = date(),
	RoleTask =  #task_process{uid=PStatus#player.id ,tid = TD#tpl_task.tid, 
								 trigger_time =Date, state=State,
								 mark = ResMark,type=TaskType, grade=Grade },
	Data = [PStatus#player.id,TD#tpl_task.tid, State,util:unixtime(),TaskType,util:term_to_string(ResMark), Grade],
	TaskProcessId = db_agent_task:insert_task_process_data(Data),%%插入任务进度
	NewRoleTask = RoleTask#task_process{id = TaskProcessId},
	insert_pid(TaskType,State,TaskProcessId),
	ets:insert(?ETS_TASK_PROCESS, NewRoleTask),
	NewRoleTask.

%-----------------------------
%    杀怪采集等更新任务进度
%-----------------------------   

%%统一任务事件调用接口
%%
%%参数 PlayerStatus：用户状态record 
%%     Event：任务事件类型（kill,item,npc....）
%%     Param: 事件参数 {对象ID,对象数量}
%%举例：
%%	    杀怪事件 call_event(PlayerStatus,kill,{MonId,MonNum}) 同采集事件
%%     	与npc对话事件 call_event(PlayerStatus,npc,{NpcId}) 同升级事件
%%      到指定副本层数事件 call_event(PlayerStatus,scene,{SceneId,FloorNum})
%%      天道令任务事件 call_event(PlayerStatus,scene,{})
%%      npc购物事件  call_event(PlayerStatus,npc_goods,{NpcId,ItemId,ItemNum})
%%		与副本任务事件 call_event(PlayerStatus,dungeon,{DungeonId}) 
%%
call_event(PlayerStatus,Event,Param)->
	gen_server:cast
	  (PlayerStatus#player.other#player_other.pid_task, {'task_event',PlayerStatus,Event,Param}).
%% 打怪事件成功
task_event(kill, MonInfo, PS) ->   
	upd_task_process(?KILL_EVENT, PS, MonInfo);
%%采集事件
task_event(item,ItemInfo,PS)->  
	upd_task_process(?COLLECT_EVENT, PS, ItemInfo) ;
%%商城购物
task_event(shopping,ItemInfo,PS)-> 
	upd_task_process(?SHOPPING_EVENT, PS, ItemInfo) ;
%%npc购物
task_event(npc_goods,ItemInfo,Ps)->
	upd_task_process(?NPC_GOODS_EVENT, Ps, ItemInfo) ;
%%npc对话事件
task_event(npc, Npc, PS)->  
	upd_task_process(?NPC_TALK_EVENT, PS, Npc);
%%升级事件
task_event(lv,Lv, PS)-> 
	upd_task_process(?LEVEL_EVENT, PS, Lv),
	%%判定是否有可接的日常任务
	AddTaskProcessList = add_can_accept_daily_task(PS, ?ALL_CAN_ACCEPT_TYPE),
	send_task_process_list(PS, AddTaskProcessList);
%%天道令事件
task_event(god_command,_, PS)-> 
	upd_task_process(?GOD_COMMAND_EVENT, PS, {});
%%到副本指定层数， 一废弃
task_event(scene,SceneInfo,Ps)->
	upd_task_process(?SCENE_EVENT, Ps, SceneInfo);
%%完成副本事件
task_event(dungeon, Dungeon,  Ps)->
	upd_task_process(?DUNGEON_EVENT, Ps, Dungeon);
%%完成充值金额 --新增
task_event(gold_charge, ChargeNum,  Ps)->
	upd_task_process(?CHARGE_EVENT, Ps, ChargeNum);
%%完成某个副本一定次数 --新增
task_event(dungeon_finish, DungeonInfo,  Ps)->
	upd_task_process(?DUNGEON_FINISH_EVENT, Ps, DungeonInfo);
%%完成探索地图 --新增
task_event(find_map,PosInfo,Ps) ->
    upd_task_process(?FIND_MAP_EVENT,Ps,PosInfo);

task_event(_R1,_R2,_R3)->
 %	?TASK_TRACE("miss ~p ~n",[{R1,R2,R3}]),
	skip.

%%获取所有未完成任务
get_all_unfinish_task(_PlayerId)->  
	TaskProcessIdList =  get({daily_task_list, 0})++get({role_task_list, 0}), 
	lists:map(fun(TaskProcessId)->  
					  Res = ets:lookup(?ETS_TASK_PROCESS, TaskProcessId),
					  case Res of
						  [TaskProcess] -> TaskProcess;
						  _->{TaskProcessId} 
					  end
			   end,TaskProcessIdList). 

%%更新任务进度
%%ObjInfo 传过来的参数
upd_task_process(Type, Ps, ObjInfo) -> 
	?TASK_TRACE("check task event: event type -> ~p, playerId -> ~p,event info -> ~p ",[Type, Ps#player.id, ObjInfo]),
	ResList =get_all_unfinish_task(Ps#player.id) ,  
	case length(ResList) of
		0-> skip;
		_-> 
			F = fun(TaskProcess,Sum)-> %%匹配任务进度数据结构
						if is_record(TaskProcess, task_process) ->
							   [_Type,Rest] = case TaskProcess#task_process.mark of
												  [Arg1,Arg2]->[Arg1, Arg2];
												  [Arg1]->[Arg1,-1];
												  _->[-1,-1]
											  end,  
							   case _Type of
								   Type ->   
									   check_process_upd(Type, ObjInfo, Rest, TaskProcess, Sum, Ps);
								   _->Sum 
							   end;
						   true ->
							   %%测试代码， 排查错误， 上线除去
							   ?TASK_TRACE("upd_task_process error. badrecord: ~p~n", [TaskProcess]),
							   Sum
						end
				end,
			Rest = lists:foldl(F, 0, ResList), 
			%%通知客户端更新对应的任务 
			send_30501_pack(Ps, util:check_list(Rest))
	end.

%----------------------------------
%    检查是否满足更新任务进度条件
%----------------------------------  

%%杀怪
check_process_upd(?KILL_EVENT,ObjInfo,MarkItem,Task,Sum,PS)-> 
	{MonId,_} = ObjInfo,
	case MarkItem of
		{MonId,_,_}->
			?TASK_TRACE("KILL_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			 do_update(?KILL_EVENT, ObjInfo,Task,Sum,PS);  
		_-> Sum 
	end;
%%采集
check_process_upd(?COLLECT_EVENT,ObjInfo,MarkItem,Task,Sum,PS)-> 
	{ItemId,_} = ObjInfo,
	case MarkItem of
		{ItemId,_,_}->
				?TASK_TRACE("KILL_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(?COLLECT_EVENT, ObjInfo,Task,Sum,PS);  
		_-> Sum 
	end;
%%商城购物
check_process_upd(?SHOPPING_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{ItemId,_} = ObjInfo,
	case MarkItem of
		{ItemId,_,_}->
				?TASK_TRACE("KILL_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(?SHOPPING_EVENT, ObjInfo,Task,Sum,PS);  
		_-> Sum 
	end;
%%npc对话
check_process_upd(?NPC_TALK_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{NpcId} = ObjInfo,
	case MarkItem of
		{NpcId}->
				?TASK_TRACE("NPC_TALK_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(Task,Sum,PS);  
		_-> Sum 
	end;
%%到指定npc处购买指定商品
check_process_upd(?NPC_GOODS_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{NpcId,ItemId,_} = ObjInfo,
	case MarkItem of
		{NpcId,ItemId,_,_}->
				?TASK_TRACE("NPC_GOODS_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(Task,Sum,PS);  
		_-> Sum 
	end;
%%升级
check_process_upd(?LEVEL_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{LV} = ObjInfo,
    if
        is_tuple(MarkItem) ->
            {MarkLv} = MarkItem,
            if
                LV >= MarkLv ->
			        do_update(Task,Sum,PS);  
                true ->
                    Sum
            end;
        true ->
            Sum
    end;

%%到达指定副本的指定层数, 已废弃
check_process_upd(?SCENE_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{SId,FloorNum} = ObjInfo,
	case MarkItem of
		{SId,FloorNum}->
				?TASK_TRACE("SCENE_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(Task,Sum,PS);  
		_-> Sum 
	end;
%%完成进入副本任务
check_process_upd(?DUNGEON_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{DungeonId} = ObjInfo,
	case MarkItem of
		{DungeonId}->
				?TASK_TRACE("DUNGEON_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id, ObjInfo]),
			do_update(Task,Sum,PS);  
		_-> Sum 
	end;
%%npc天道令
check_process_upd(?GOD_COMMAND_EVENT,_,_,Task,Sum,PS)->
	?TASK_TRACE("GOD_COMMAND_EVENT trigger :  playerId -> ~p ",[PS#player.id]),
	do_update(Task,Sum,PS);


%%充值任务
check_process_upd(?CHARGE_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	case MarkItem of
		{_,_,_}->
				?TASK_TRACE("CHARGE_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id,ObjInfo]),
			do_update(?CHARGE_EVENT, ObjInfo,Task,Sum,PS);  
		_-> Sum 
	end;

%%完成N次通关某副本任务
check_process_upd(?DUNGEON_FINISH_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{DungeonId,_} = ObjInfo,
	case MarkItem of
		{DungeonId,_,_}->
				?TASK_TRACE("DUNGEON_FINISH_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id, ObjInfo]),
			do_update(?DUNGEON_FINISH_EVENT, ObjInfo,Task,Sum,PS);  
		_-> Sum 
	end;

%%完成探索地图任务
check_process_upd(?FIND_MAP_EVENT,ObjInfo,MarkItem,Task,Sum,PS)->
	{SceneId,PosX,PosY} = ObjInfo,
	case MarkItem of
		{SceneId,PosX,PosY}->
				?TASK_TRACE("FIND_MAP_EVENT trigger :  playerId -> ~p,event info -> ~p ",[PS#player.id, ObjInfo]),
			do_update(Task,Sum,PS);  
		_-> Sum 
	end;

check_process_upd(_,_,_,_,Sum,_)->
	Sum.
%%格式化并抽取task_progress中的数据
%%没有使用的方法
get_list_from_record(List)->
	if is_record(List, task_process_info) ->
		   {List#task_process_info.task_fin,List#task_process_info.task_unfinsh};
	   true->
		   {[],[]}end.

%%判断任务是自动完成还是更新进度(杀怪,采集,充值等)
do_update(Type, ObjInfo,Task,Sum,PS) ->
	{_,ObjNum,FinNum,NowNum} = convert_mark_data(Type,ObjInfo,Task#task_process.mark),
	%%进入完成任务处理逻辑
	if ObjNum +NowNum >= FinNum ->
		  check_auto_fin(Type,Task,Sum,PS,FinNum);
	   true -> %%进入未完成任务处理逻辑  
		   upd_task_2_mem(Task,prase_mark_data(Type,Task#task_process.mark,ObjNum +NowNum),0),
		   %%加上返回去的id
		   util:make_list(Sum, {Task#task_process.id,Task#task_process.tid,0,ObjNum +NowNum, Task#task_process.grade})
	end.
%%判断任务是自动完成还是更新进度(杀怪,采集等)
check_auto_fin(Type,TaskProcess,Sum,PS,FinNum)->
	case check_auto_finish_task(TaskProcess, PS) of
		true -> 
			call_auto_fin_2_client(PS#player.other#player_other.pid_send,TaskProcess#task_process.id),
			trigger_next_task(TaskProcess#task_process.tid,PS),
			Sum;
		false->
			 do_upd_task_process(Type,TaskProcess,FinNum,Sum);
		_->Sum
	end.


%%接任务时， 判定是否自动完成
check_auto_fin_for_accpet(TaskProcess, PS)->
	case tpl_task:get(TaskProcess#task_process.tid) of 
		Task when is_record(Task, tpl_task) andalso Task#tpl_task.target_type =:= ?NPC_TALK_EVENT ->
			case check_auto_finish_task(TaskProcess, PS) of
				true->
					call_auto_fin_2_client(PS#player.other#player_other.pid_send,TaskProcess#task_process.id),
					trigger_next_task(TaskProcess#task_process.tid,PS),
					true;
				_-> false
			end;
		_->
			false
	end.

%%触发后置任务
trigger_next_task(TaskId,PS)->
	case tpl_task:get(TaskId) of
		TD when is_record(TD, tpl_task)->
				auto_trgger_task_one(TD#tpl_task.next_tid,PS);
		_->skip 
	end.

%%判断任务是自动完成还是更新进度(npc,升级, 副本任务)
do_update(TaskProcess, Sum, PS)->
	case check_auto_finish_task(TaskProcess, PS) of
		true-> 
			call_auto_fin_2_client(PS#player.other#player_other.pid_send,TaskProcess#task_process.id),
			trigger_next_task(TaskProcess#task_process.tid, PS),
            if
                length(PS#player.other#player_other.step_check_tasks) > 0 ->
                    NewPlayerOther = PS#player.other#player_other{
                        step_check_tasks = lists:keydelete(TaskProcess#task_process.id,2,PS#player.other#player_other.step_check_tasks)
                    },
                    NewPs = PS#player{other = NewPlayerOther},
                    mod_player:save_online(NewPs);
                true ->
                    skip
            end,
			Sum;
		false->
			do_upd_task_process(TaskProcess,Sum);
		_->Sum
	end. 

%%执行更新任务进度操作(升级,和npc对话)
do_upd_task_process(Task,Sum)->
	%%进入完成任务处理逻辑  
	upd_task_2_db_and_mem(Task,1), 
	util:make_list(Sum,{Task#task_process.id,Task#task_process.tid, 1, 0, Task#task_process.grade}).  

%%执行更新任务进度操作(杀怪,采集等)
do_upd_task_process(Type,Task,FinNum,Sum)-> 
	upd_task_2_db_and_mem(Task,prase_mark_data(Type,Task#task_process.mark,FinNum),1),
	util:make_list(Sum,{Task#task_process.id, Task#task_process.tid, 1, FinNum, Task#task_process.grade}). 

%%通知客户端有自动完成任务
call_auto_fin_2_client(PidSend,TaskProcessId)->
 	{ok,Data} = pt_30:write(30506, [TaskProcessId]),
	lib_send:send_to_sid(PidSend, Data).

%%将不同类型任务转换为统一结构
convert_mark_data(?NPC_GOODS_EVENT,ObjInfo,Mark)->
	{_,ObjId,ObjNum} = ObjInfo,
	[_,{_,_,FinNum,NowNum}] = Mark,
	{ObjId,ObjNum,FinNum,NowNum};
convert_mark_data(_,ObjInfo,Mark)->
    if
        size(ObjInfo) =:= 2 ->
            {ObjId,ObjNum} = ObjInfo;
        true ->
            ObjId = 0,
            {ObjNum} = ObjInfo
    end,
	[_,{_,FinNum,NowNum}] = Mark, 
	{ObjId,ObjNum,FinNum,NowNum}.
%%将不同类型任务转换为对应mark结构
prase_mark_data(?NPC_GOODS_EVENT,Mark,NewNum)->
	[_,{NpcId,ItemId,ItemNum,_}] = Mark,
	[?NPC_GOODS_EVENT,{NpcId,ItemId,ItemNum,NewNum}];
prase_mark_data(_,Mark,NewNum)->
	[Type,{ItemId,ItemNum,_}] = Mark,
	[Type,{ItemId,ItemNum,NewNum}]. 

%%检测自动完成任务
check_auto_finish_task(TaskProcess,PS)->
	case tpl_task:get(TaskProcess#task_process.tid) of 
		TD when is_record(TD, tpl_task)->
			case TD#tpl_task.end_npc of 
				?TASK_AUTO_FIN_FLAG ->
					%%判断背包是否已满
					case can_put_into_bag(PS, TD#tpl_task.goods_list) of 
						true ->
							cast_player_give_goods(PS,TD#tpl_task.goods_list, TD#tpl_task.tid),
							do_finish(TaskProcess, PS#player.id, 0, local),
							true;
						_->
							false%%背包已满
					end;
				_->false 
			end;
		_->false
	end.

%%更新任务进度到内存
upd_task_2_mem(Task,NewMark,NewState)->
	ets:insert(?ETS_TASK_PROCESS, Task#task_process{ mark = NewMark, state  = NewState}).
upd_task_2_mem(Task,NewState)->
	ets:insert(?ETS_TASK_PROCESS, Task#task_process{ state  = NewState}).

%%分别更新任务进度到内存与数据库
upd_task_2_db_and_mem(Task,NewMark,NewState)-> 
	upd_task_in_pid(Task#task_process.id,Task#task_process.type, NewState),
	upd_task_2_mem(Task,NewMark,NewState),
	db_agent_task:upd_task_process_data([NewState,util:term_to_string(NewMark),Task#task_process.id]).
upd_task_2_db_and_mem(Task,NewState)->
	upd_task_in_pid(Task#task_process.id,Task#task_process.type, NewState),
	upd_task_2_mem(Task,NewState),
	db_agent_task:upd_task_process_data([NewState,Task#task_process.id]).

%%当任务满足完成条件时更新进程字典
upd_task_in_pid(TaskProcessId,Type, NewState)when Type=:=?MAIN_TASK orelse Type=:=?BRANCHE_TASK->
	case NewState of 
		?TASK_NOT_FINISH ->
			CanTrigger =get({role_task_list, ?TASK_CAN_TRIGGER}),
			put({role_task_list, ?TASK_CAN_TRIGGER},lists:delete(TaskProcessId, CanTrigger)),
			UnFinish = get({role_task_list, ?TASK_NOT_FINISH}),
			put({role_task_list, ?TASK_NOT_FINISH},UnFinish++[TaskProcessId]);
		?TASK_FINISH -> 
			CanTrigger =get({role_task_list, ?TASK_CAN_TRIGGER}),
			put({role_task_list, ?TASK_CAN_TRIGGER},lists:delete(TaskProcessId, CanTrigger)),
			UnFinish =get({role_task_list, ?TASK_NOT_FINISH}),
			put({role_task_list, ?TASK_NOT_FINISH}, lists:delete(TaskProcessId, UnFinish)),
			Finish = get({role_task_list, ?TASK_FINISH}),
			put({role_task_list, ?TASK_FINISH},Finish++[TaskProcessId]);
		_->
			?TASK_TRACE("MAIN_TASK upd_task_in_pid error, NewState=~p, TaskProcessId=~p~n", [NewState, TaskProcessId])
	end;
upd_task_in_pid(TaskProcessId,_, NewState)->
	case NewState of 
		?TASK_NOT_FINISH-> 
			CanTrigger =get({daily_task_list,?TASK_CAN_TRIGGER}),
			put({daily_task_list,?TASK_CAN_TRIGGER},lists:delete(TaskProcessId, CanTrigger)),
			UnFinish = get({daily_task_list,?TASK_NOT_FINISH}),
			put({daily_task_list, ?TASK_NOT_FINISH},UnFinish++[TaskProcessId]);
		?TASK_FINISH->
			UnFinish =get({daily_task_list, ?TASK_NOT_FINISH}),
			put({daily_task_list, ?TASK_NOT_FINISH},lists:delete(TaskProcessId, UnFinish)),
			Finish = get({daily_task_list, ?TASK_FINISH}),
			put({daily_task_list, ?TASK_FINISH},Finish++[TaskProcessId]);
		_->
			?TASK_TRACE("upd_task_in_pid error, NewState=~p, TaskProcessId=~p~n", [NewState, TaskProcessId])
	end.

%-----------------------------
%         玩家完成任务 
%----------------------------- 

%%在ets表中检测该任务状态
check_task_in_trigger(TaskId,PlayerId)->  
	case ets:lookup(?ETS_TASK_PROCESS, {PlayerId,TaskId}) of
		[Task] when is_record(Task, task_process)->
			case Task#task_process.state of
				%%该任务未完成
				0 -> {false,?TASK_UNFINISH};
				1->true 
			end;
		%%角色没有触发任务
		_-> 
			?ERROR_MSG("task not in trigger ~p ~n",[ {PlayerId,TaskId}]),
			{false,?TASK_NOT_IN_PROCESS}
	end.

%%根据世界等级重新计算任务的经验奖励
recalExpGoodsList(TaskGoodsList,PlayerStatus) ->
    AddRadio = lib_world_level:get_exp_ratio(PlayerStatus#player.level),
    F = fun(GoodItem,NewGoodsList) ->
            {A,B,ItemId,ItemNum} = GoodItem,
            if
                ItemId =:= ?MONEY_EXP_T_ID ->
                    [{A,B,ItemId,trunc(ItemNum*(1+AddRadio))} | NewGoodsList];
                true ->
                    [GoodItem | NewGoodsList]
            end
    end, 

    case lib_world_level:get_task_status(PlayerStatus#player.level) of
        true ->
            RetGoodsList = lists:foldl(F,[],TaskGoodsList);
        _ ->
            RetGoodsList = TaskGoodsList
    end,
    RetGoodsList.

%%检测任务完成函数
finish_task(TaskProcessId,PS)-> 
	?TASK_TRACE("finish_task playerId ->~p TaskProcessId -> ~p ~n",[PS#player.id,TaskProcessId]),
	case get_task_process(TaskProcessId) of
		null ->
			{false,?TASK_NOT_IN_PROCESS};
		TaskProcess ->
			?TASK_TRACE("finish_task playerId ->~p TaskProcessInfo -> ~p ~n",[PS#player.id,TaskProcess]),
			case TaskProcess#task_process.state of
				?TASK_FINISH ->
					case tpl_task:get(TaskProcess#task_process.tid) of
						Task when is_record(Task, tpl_task) ->

                            %%自强不息任务，在世界等级区间的玩家有经验加成 byCXF
                            if
                                Task#tpl_task.type =:= ?SELF_IMPROVE_TASK ->
                                    NewGoodsList = recalExpGoodsList(Task#tpl_task.goods_list,PS);
                                true ->
                                    NewGoodsList = Task#tpl_task.goods_list
                            end,

							case do_player_get_goods(NewGoodsList, PS) of
								NewPs when is_record(NewPs, player)-> 
									gen_server:cast(NewPs#player.other#player_other.pid_task, {'do_task_finish',{TaskProcess, NewPs}}), 
									?TASK_TRACE("finish_task success playerId ->~p taskId -> ~p lv -> ~p ~n",[PS#player.id,TaskProcessId,NewPs#player.level]),
									%%开启功能系统，宠物系统， 坐骑系统 
									%%NewPS2 = open_func_system(TaskProcess#task_process.tid, NewPs),
									NewPS2 = lib_leader:open_func(NewPs,?TASK_OPEN,TaskProcess#task_process.tid),
									%%剧情对话
									case Task#tpl_task.end_opera of
										[{Type,DialId}] when DialId > 0 ->
											lib_opera:notify_opera_dialogue(PS#player.id,PS#player.other#player_other.pid_send,DialId);
										_ ->
											skip
									end,

                                    %%完成任务获得VIP体验
                                    if
                                        NewPS2#player.vip > 0 ->
                                            NewPS3 = NewPS2;
                                        true ->
                                            NewPS3 = lib_vip:check_task_vip(Task,NewPS2)
                                    end,

                                    %%写操作日志
                                    db_agent_log:add_task_log(PS#player.id,PS#player.account_name,PS#player.career,PS#player.level,Task#tpl_task.tid,2,util:unixtime()), 
									{true,NewPS3};
								R-> 
									?TASK_TRACE("finish_task success but get goods fail playerId ->~p taskId -> ~p ~n",[PS#player.id,TaskProcessId]),
									?ERROR_MSG("give task award to player fail ~p ~n",[R]),
									{false,?GET_GOOD_FAIL}
							end;
						_ ->
							{false,?TASK_NOT_EXIT}
					end;	
				_ ->
					{false,?TASK_UNFINISH}
			end
	end.	
	
%%处理用户获取任务奖励逻辑
do_player_get_goods(GoodList,PS)->  
	?TASK_TRACE("player-> ~p get task award of ~p begin ~n",[PS#player.id,GoodList]),
	%%判断背包是否已满
	case can_put_into_bag(PS, GoodList) of
		true-> 
			case parse_good_list(GoodList,PS) of
				AvailableList when length(AvailableList) >0 ->  
					?TASK_TRACE("player parse_good_list-> ~p get task award of ~p begin ~n",[PS#player.id, AvailableList]),
					%%这里到时候要多调用物品模块的一个接口
					case goods_util:send_goods_and_money_by_task(AvailableList, PS, ?LOG_GOODS_TASK) of 
						NewStatus when is_record(NewStatus, player) ->
							?TASK_TRACE("player parse_good_list PS STATE-> ~p get task award of newNewStatus= ~p begin ~n",[PS#player.id, NewStatus#player.bcoin]),
							mod_player:save_online(NewStatus) ,
							NewStatus;
						_->
							?TASK_TRACE("send_goods_and_money fail, AvailableList=~p~n", [AvailableList]),
							skip
					end;
				_->
					?TASK_TRACE("parse_good_list fail ~p~n", [GoodList]),
					skip
			end;
		_->  
			?TASK_TRACE("bag is full playerId=~p~n.", [PS#player.id]),
			skip %%背包已满
	end.

%%开启功能系统
open_func_system(TaskId, PS)->
	case data_config:get_task_id_for_pet() of 
		TaskId ->
			?TASK_TRACE("open pet system, taskId=~p, playerId=~p ~n", [TaskId, PS#player.id]),
			{ok, NewPS} = lib_pet:create_pet(PS);
		_->
            NewPS = PS
	end,
	
	%%开启坐骑系统
	case data_config:get_task_id_for_mount() of 
		TaskId->
			?TASK_TRACE("open mount system, taskId=~p, playerId=~p ~n", [TaskId, NewPS#player.id]),
			lib_mount:open_mount(NewPS),
			?TASK_TRACE("open mount system, taskId=~p, playerId=~p ~n", [TaskId, NewPS#player.id]);
		_->
			skip
	end,

	%%开启经脉系统
	case data_config:get_task_id_for_meridian() of 
		TaskId->
			NewPS2 = lib_meridian:init_meridian(NewPS,1),
			?TASK_TRACE("openMeridiaSystem, taskId=~p, playerId=~p ~n", [TaskId, NewPS#player.id]);
		_->
			NewPS2 = NewPS
	end,
    NewPS2.

%%调用玩家进程奖励物品
cast_player_give_goods(PS, GoodList, TaskId)->
	gen_server:cast(PS#player.other#player_other.pid, {give_present, GoodList, TaskId}).

%%调用玩家进程奖励经验
cast_player_add_exp(PS, Exp)->
	gen_server:cast(PS#player.other#player_other.pid, {add_exp, Exp}).

%%解析任务奖励物品列表
parse_good_list(List,PS) when is_list(List)->  
	F = fun(Goods)->
			{_,_,ItemId,ItemNum} = Goods,
			{ItemId,ItemNum}
	end,
		[F(Item)||Item<-List,parse_one_good(Item,PS)].

%%解析物品， 排除虚拟物品, 金币， 经验
%%返回[{GoodTid1,NumCount1}, ...]
parse_good_list_exclude_virtual_goods(List,PS)->
	F = fun(Goods)->
				{_,_,ItemId,ItemNum} = Goods,
				{ItemId,ItemNum}
		end,
	CheckVirtual = fun(Goods) ->
						   {_,_,ItemId,_} = Goods,
						   case goods_util:is_virtual_goods(ItemId) of
							   true -> false;
							   _->true
						   end
				   end,
	[F(Item)||Item<-List,parse_one_good(Item,PS), CheckVirtual(Item)].

%%检查能否放进背包
can_put_into_bag(PS, GoodsList)->
	case parse_good_list_exclude_virtual_goods(GoodsList, PS) of
		[] -> true;
		NewGoodsList ->
			case goods_util:can_put_into_bag(PS, NewGoodsList) of
				true -> true;
				_ ->
					lib_player:send_tips(5002006,[], PS#player.other#player_other.pid_send),
					false
			end
	end.	

 
%-----------------------------
%     解析ets任务奖励数据  
%-----------------------------
parse_one_good({?NULL_TASK_FLAG,_,ItemId,ItemNum},_)->  
	true;
parse_one_good({?CAREER_TASK_FLAG,ItemCareer,ItemId,ItemNum},PS)-> 
	if ItemCareer =:=PS#player.career-> true;
	   ItemCareer =:= 0 -> true;
	   true->  false
	end;
parse_one_good(_,_)->
	false.

%%执行完成任务逻辑 State:任务状态
%%如果是日常任务
do_finish(TaskProcess, PlayerId, State, CallType)-> 
	ets:delete(?ETS_TASK_PROCESS, TaskProcess#task_process.id),
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[]->skip;
		[PS]-> 
			do_del_dict(CallType,State,TaskProcess, PS)
	end,
	spawn(db_agent_task,syn_db_task_bag_delete,[[TaskProcess#task_process.id, PlayerId]]),
	do_normal_finish(TaskProcess, PlayerId, CallType).

%%在进程字典中删除任务判断逻辑,是本地调用还是跨进程
do_del_dict(local,State,TaskProcess,_)->  
	del_finish_task(TaskProcess#task_process.type, TaskProcess#task_process.id,State);
do_del_dict(remote,State,TaskProcess,PS)->
	gen_server:cast(PS#player.other#player_other.pid_task,
							{'del_dict',{TaskProcess#task_process.type, TaskProcess#task_process.id,State}}).

%%角色任务完成逻辑
do_normal_finish(TaskProcess, PlayerId, _CallType)when TaskProcess#task_process.type=:=?BRANCHE_TASK orelse TaskProcess#task_process.type=:=?MAIN_TASK->
	TaskFinish = get_finish_task(PlayerId),
	Task = tpl_task:get(TaskProcess#task_process.tid),
	NewTaskFin = upd_finish_task(TaskFinish,Task#tpl_task.level,Task#tpl_task.tid),
	ets:insert(?ETS_TASK_FINISH, NewTaskFin),
	db_agent_task:save_finish_task(NewTaskFin, Task#tpl_task.level);

%%日常任务奖励
do_normal_finish(TaskProcess, PlayerId, CallType) ->
	case get_one_daily_task_fin(PlayerId, TaskProcess#task_process.type) of
		[TaskDaily]->
			NewTaskDaily = TaskDaily#task_daily{trigger_count = max(TaskDaily#task_daily.trigger_count - 1, 0)},
			ets:insert(?ETS_TASK_DAILY, NewTaskDaily),
			db_agent_task_daily:update_trigger_count(NewTaskDaily),
			
			case ets:lookup(?ETS_ONLINE, PlayerId) of 
				[PS] ->
					%%处理日常天道令任务， 师门令任务发送特殊奖励, 任务品质发放奖励
					case TaskProcess#task_process.grade > 0 of
						true ->
							case TaskDaily#task_daily.type of
								?MASTER_TASK ->
									finish_special_daily_task(task_master, TaskProcess, PS, CallType);
								?GOD_COMMAND_TASK ->
									finish_special_daily_task(task_heaven, TaskProcess, PS, CallType);
								_->skip
							end;
						_->skip
					end,
					
					%%自动添加后续可接的日常任务
					case TaskProcess#task_process.type of 
						?MASTER_TASK-> skip;
						?GOD_COMMAND_TASK-> skip;
						_->
							AddTaskProcessList = add_can_accept_daily_task(PS, [TaskProcess#task_process.type]),
							send_task_process_list(PS, AddTaskProcessList)
					end;
				_->skip
			end;
		_->skip
	end.

%%日常任务完成时特殊处理
finish_special_daily_task(task_master, TaskProcess, PS, CallType)->
	Exp = get_award_exp_count(PS, TaskProcess#task_process.type, TaskProcess#task_process.grade,TaskProcess#task_process.tid),
	award_exp_4_daily_task(CallType, PS, Exp);
finish_special_daily_task(task_heaven, TaskProcess, PS, CallType)->
	Exp = get_award_exp_count(PS,TaskProcess#task_process.type, TaskProcess#task_process.grade,TaskProcess#task_process.tid),
	award_exp_4_daily_task(CallType, PS, Exp).

%%奖励玩家经验值
%%local 表示任务进程remote 表示玩家进程
award_exp_4_daily_task(local, PS, Exp)->
	case Exp > 0 of
		true ->
			cast_player_add_exp(PS, Exp);
		_->skip
	end;

award_exp_4_daily_task(remote, PS, Exp)->
	case Exp > 0 of
		true ->
			case lib_player:add_exp(PS, Exp, task) of 
				NewPS when is_record(NewPS, player)->
					mod_player:save_online(NewPS),
					NewPS;
				_->skip
			end;
		_->skip
	end.


%%在进程字典中删除任务 State:任务状态
del_finish_task(Type,TaskProcessId,State)when Type =:= ?BRANCHE_TASK orelse Type=:=?MAIN_TASK->
	RoleTask = get({role_task_list,State}),
	put({role_task_list,State},lists:delete(TaskProcessId, RoleTask));
del_finish_task(_,TaskProcessId,State) ->
	DailyTask = get({daily_task_list,State}), 
	put({daily_task_list,State},lists:delete(TaskProcessId, DailyTask)).

%%重新格式化内存中的已完成任务
upd_finish_task(TF, Level, TaskId) ->
	if 
		Level < 11 ->
			case lists:member(TaskId, TF#task_finish.td1) of
				false ->
					List = [TaskId | TF#task_finish.td1],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td1 = List, td = List1};
				_-> NewTF =TF
			end;
		Level < 21 ->
			case lists:member(TaskId, TF#task_finish.td2) of
				false->
					List = [TaskId | TF#task_finish.td2],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td2 = List, td = List1};
				_-> NewTF = TF
			end;
		Level < 31 ->
			case lists:member(TaskId, TF#task_finish.td3) of 
				false->
					List = [TaskId | TF#task_finish.td3],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td3 = List, td = List1};
				_-> NewTF = TF
			end;
		Level < 41 ->
			case lists:member(TaskId, TF#task_finish.td4) of
				false->
					List = [TaskId | TF#task_finish.td4],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td4 = List, td = List1};
				_->NewTF = TF
			end;
		Level < 51 ->
			case lists:member(TaskId, TF#task_finish.td5) of 
				false ->
					List = [TaskId | TF#task_finish.td5],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td5 = List, td = List1};
				_-> NewTF = TF
			end;
		Level < 61 ->
			case lists:member(TaskId, TF#task_finish.td6) of 
				false ->
					List = [TaskId | TF#task_finish.td6],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td6 = List, td = List1};
				_-> NewTF = TF
			end;
		Level < 71 ->
			case lists:member(TaskId, TF#task_finish.td7) of 
				false ->
					List = [TaskId | TF#task_finish.td7],
					List1 = [TaskId | TF#task_finish.td],
					NewTF = TF#task_finish{td7 = List, td = List1};
				_-> NewTF = TF
			end;
		true ->
			NewTF = TF
	end, 
	NewTF.		


%%在ets中获取单条任务数据
get_task_process(TaskProcessId)->
	case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
		[Task] ->
			Task;
		[]->null 
	end. 

%-----------------------------
%     更新可接任务列表
%-----------------------------

%% 更新角色可接任务 
refresh_active(PS) -> 
	MainActiveTids = [TD#tpl_task.tid || TD<- tpl_task:get_by_type(0), check_trigger_condition(TD, PS,0)],
	BtanchActiveTids =[TD#tpl_task.tid ||  TD<-tpl_task:get_by_type(1), check_trigger_condition(TD, PS,1)]  , 
	IdList = MainActiveTids++BtanchActiveTids,  
	ets:insert(?ETS_TASK_QUERY_CACHE, {PS#player.id, IdList}),	
	?TASK_TRACE("refresh player active task ,get player ~p can trigger task list -> ~p ~n",[PS#player.id,IdList]),
 	TriId = auto_trgger_task(IdList,PS),
	?TASK_TRACE("refresh player auto trigger task ,get player ~p  auto trigger task list -> ~p ~n",[PS#player.id,TriId]),
	case TriId of
		0 ->
			skip;
		_ ->
			send_task_process_list(PS, TriId),
			refresh_active(PS)
	end.	
 
%%检测自动触发任务(列表)
%%内容修改，不是自动触发任务， 也需要添加task_process, 状态
auto_trgger_task(IdList,PS)-> 
	lists:foldl(fun(TaskId,TaskList)->
						case tpl_task:get(TaskId) of
							Task when is_record(Task, tpl_task)-> 
								TaskState = get_task_process_state_for_trigger(Task),
								TaskProcess = add_task_process(Task, PS, TaskState, ?TASK_COMMON_GRADE),
								util:make_list(TaskList, TaskProcess);
%% 								if Task#tpl_task.start_npc =:=?TASK_AUTO_TRIG_FLAG ->
%% 									   case  Task#tpl_task.target_type of
%% 										   ?NPC_TALK_EVENT ->
%% 											   TaskProcess = add_task_process(Task,PS,?TASK_FINISH,?TASK_COMMON_GRADE),
%% 											   util:make_list(TaskList, TaskProcess); 
%% 										   _->
%% 											   TaskProcess = add_task_process(Task, PS, ?TASK_NOT_FINISH,?TASK_COMMON_GRADE),
%% 											   util:make_list(TaskList, TaskProcess) 
%% 									   end;  
%% 								   true ->
%% 									   TaskList
%% 								end;
							[]-> TaskList
						end 
				end, 0, IdList).

%%检测自动后置触发任务
%%修改逻辑，startNpc>0, 需要玩家手动接任务;startNpc = 0 自动接任务状态改为0
auto_trgger_task_one(TaskId,PS)-> 
	?TASK_TRACE("auto trigger task(method-> auto_trgger_task_one) playerId ->~p taskId -> ~p ~n",[PS#player.id,TaskId]),
	case tpl_task:get(TaskId) of
		Task when is_record(Task, tpl_task)->  
			case check_trigger_condition(Task, PS,Task#tpl_task.type) of
				true ->
					TaskState = get_task_process_state_for_trigger(Task),
					TaskProcess = add_task_process(Task, PS, TaskState, ?TASK_COMMON_GRADE),
					send_task_process_list(PS, [TaskProcess]);
				_->
					skip 
			end; 
		_->skip
	end.

%%得到新增加任务的状态
get_task_process_state_for_trigger(Task)->
	case Task#tpl_task.start_npc of 
		0 ->
			case Task#tpl_task.target_type of 
				%%单独处理npc对话任务逻辑, 直接完成
				?NPC_TALK_EVENT ->
					?TASK_FINISH;
				_->
					?TASK_NOT_FINISH
			end;
		_->
			?TASK_CAN_TRIGGER
	end.

%%接任务， 返回状态
get_task_process_state_for_accept(Task) ->
	case Task#tpl_task.target_type of 
		?NPC_TALK_EVENT->
			?TASK_FINISH;
		_->
			?TASK_NOT_FINISH
	end.

%-----------------------------
%     玩家退出逻辑
%----------------------------- 

%%玩家退出
player_exit(PlayerId)->
	 clean_unfininsh_task_data(PlayerId),
	 clean_finish_task_data(PlayerId),
	 clean_task_daily(PlayerId),
	 ets:delete(?ETS_TASK_QUERY_CACHE,PlayerId),
	 ets:delete(?ETS_TASK_FINISH,PlayerId),
	 lib_task_master:dispose(PlayerId),
	 lib_task_heaven:dispose(PlayerId).

%%清理玩家完成日常任务数据
clean_task_daily(PlayerId)->
	AllType = ?ALL_TASK_TYPE,
	lists:foreach(fun(Type)->
						  ets:delete(?ETS_TASK_DAILY, {PlayerId, Type})
				  end, AllType).

%%清理玩家未完成任务逻辑
clean_unfininsh_task_data(_PlayerId)->
    List = get({role_task_list,0})++get({daily_task_list,0}),
     lists:foreach(fun(TaskProcessId)->
	case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
		[Task] when is_record(Task,task_process) ->
			  	erlang:spawn(db_agent_task,upd_task_process_data,[[Task#task_process.state,util:term_to_string(Task#task_process.mark),TaskProcessId]]);
		_->skip end,
 		ets:delete(?ETS_TASK_PROCESS, TaskProcessId) 
 			end
	, List). 

%%完成任务逻辑	
clean_finish_task_data(_PlayerId)->
	List = get({role_task_list,1})++get({daily_task_list,1}),
	lists:foreach(fun(TaskProcessId)->
		ets:delete(?ETS_TASK_PROCESS, TaskProcessId)
			end
	, List). 
 
%-----------------------------
%         npc状态
%----------------------------- 

%%检测npc是否有可接任务
check_in_active(NpcId,PlayerId)->
	case ets:lookup(?ETS_TASK_QUERY_CACHE, PlayerId) of
		[{PlayerId,ActiveList}]->	
		 	Result = lists:foldl(fun(TaskId,Sum)->
										 case tpl_task:get(TaskId) of
											 Task when is_record(Task, tpl_task) ->
												 case Task#tpl_task.start_npc of
													 NpcId ->Sum+1;
													 _->Sum
												 end;
											 _-> Sum 
										 end
								  end, 0, ActiveList),
			if Result=/=0 ->
				   ?NPC_CAN_TRIGGER;
			   true ->
				   ?NPC_NO_TASK
				   end;
		_-> ?NPC_NO_TASK 
			end.
	
%%检测npc是否有未完成任务
check_in_trigger(NpcId)->
	List = get({role_task_list,0})++get({daily_task_list,0}),
	case check_npc_in_pid(List,NpcId) of
		true->?NPC_UNFIN_TASK;
		false -> ?NPC_NO_TASK;
		_-> ?ERROR_MSG("charge npc state error ~n",[]),
			?NPC_NO_TASK
			end.

%%检测npc是否有已完成任务
check_in_finish(NpcId)->
	List = get({role_task_list,1})++get({daily_task_list,1}),
	case check_npc_in_pid(List,NpcId) of
		true->?NPC_FINISH_TASK;
		false -> ?NPC_NO_TASK;
		_->?ERROR_MSG("charge npc state error ~n",[]),
		   ?NPC_NO_TASK
		   end. 

%%在进程字典中检测对应的npc状态
check_npc_in_pid(List,NpcId)->
	Result = lists:foldl(fun(TaskId,Sum)->
								 case tpl_task:get(TaskId) of
									 Task when is_record(Task, tpl_task) ->
										 case Task#tpl_task.end_npc of
											 NpcId ->Sum+1;
											 _->Sum
										 end;
									 _-> Sum
								 end
						  end, 0, List),
	Result=/=0. 

%%检查单个npc状态
check_npc_state(NpcId,PlayerId)->
	Result = [?NPC_NO_TASK,check_in_trigger(NpcId),check_in_finish(NpcId),check_in_active(NpcId,PlayerId)],
	{NpcId,lists:max(Result)}.

%%接收npc列表,通知客户端所有npc的状态
check_npc_list_state(NpcList,PS)->
 	Result = lists:map(fun(NpcId)->
							   check_npc_state(NpcId,PS#player.id) end, NpcList),
	case length(Result) of
		0->skip;
		Len->
			case pt_30:write(30005,[Result,Len]) of
				{ok, Data} ->
					lib_send:send_to_sid(PS#player.other#player_other.pid_send, Data);
				_->
					?WARNING_MSG("make data of proto 30005 error ~n",[])
					end
	end. 

%--------------------------------
%         获取npc任务数据
%--------------------------------
query_npc_task_info(NpcId,PS)->
	?TASK_TRACE("show npc ~p ~n",[NpcId]),
	case data_task:is_daily_npc_id(NpcId) of
		true ->
			MainRetList = query_npc_main_task_info(NpcId, PS),
			?TASK_TRACE("query_npc_task_info: MainRetList=~p, npcid=~p~n",[MainRetList, NpcId]),
			DailyRetList = query_npc_daily_task_info(NpcId, PS),
			?TASK_TRACE("query_npc_task_info: DailyRetList=~p, npcid=~p~n",[DailyRetList, NpcId]),
			call_client_npc_info(MainRetList ++ DailyRetList, PS);
		_ ->	
			MainRetList = query_npc_main_task_info(NpcId, PS),
			call_client_npc_info(MainRetList, PS)
	end.

%获取主线任务信息
query_npc_main_task_info(NpcId, PS)->
	TriList = util:check_list(get_npc_in_data(main, NpcId, 0,PS)), 
	?TASK_TRACE("TriList ~p ~n",[TriList]),
	FinList = util:check_list(get_npc_in_data(main, NpcId, 1,PS)),
	?TASK_TRACE("FinList ~p ~n",[FinList]),
	CanTriggerList = util:check_list(get_npc_in_data(main, NpcId, 2,PS)), 
	?TASK_TRACE("CanTriggerList ~p ~n",[CanTriggerList]),
	QueryList = util:check_list(get_npc_in_active(NpcId,PS#player.id)),
	?TASK_TRACE("QueryList ~p ~n",[QueryList]),
	FinList ++ TriList++QueryList ++ CanTriggerList.

%%获取日常任务信息
query_npc_daily_task_info(NpcId, PS)->
	CanAcceptList = util:check_list(get_npc_in_data(daily, NpcId, 2,PS)), 
	?TASK_TRACE("CanAcceptList=~p ~n",[CanAcceptList]),
	TriList = util:check_list(get_npc_in_data(daily, NpcId, 0,PS)), 
	?TASK_TRACE("TriList=~p ~n",[TriList]),
	FinList = util:check_list(get_npc_in_data(daily, NpcId, 1,PS)), 
	?TASK_TRACE("FinList=~p ~n",[FinList]),
	QueryList = get_task_from_daily_task_list(NpcId, PS),
	?TASK_TRACE("QueryList=QueryList~p ~n", [QueryList]),
	CanAcceptList ++ FinList ++ TriList++QueryList.

%从日常任务列表中获取日常
%%需要加等级限制， 差不多需要废弃了, 在升级, 每次登录时, 判定可接收的日常任务绑定到玩家身上
get_task_from_daily_task_list(NpcId, PS)->
	TaskType = data_task:get_daily_task_type_by_npcId(NpcId),
	case TaskType of 
		?MASTER_TASK -> [];
		?GOD_COMMAND_TASK -> [];
		_ ->
			case tpl_task_detail:get(TaskType) of
				TempTaskDetail when is_record(TempTaskDetail, temp_task_detail)->
					%%判断当天是否超出限制
					case get_one_daily_task_fin(PS#player.id, TaskType) of 
						[TaskDaily] when is_record(TaskDaily, task_daily) ->
							Result = check_trigger_daily(TaskDaily, TempTaskDetail),
							case Result of
								?CAN_TRIGGER ->
									ResultList = util:check_list(get_npc_in_data(daily, NpcId, 1,PS)) ++ util:check_list(get_npc_in_data(daily, NpcId, 0,PS)),
									Len = length(ResultList),
									if Len< TempTaskDetail#temp_task_detail.meanw_trigger ->
										   Count = TempTaskDetail#temp_task_detail.meanw_trigger - Len,
										   TaskIdList = get_random_daily_task(task_daily, {Count, PS, TaskType}),
										   NewResultList = lists:foldl(fun(TaskId, Sum) -> 
																			   util:make_list(Sum, {0, TaskId, ?TASK_CAN_TRIGGER})
																	   end, 0, TaskIdList),
										   ResultList ++ util:check_list(NewResultList);
									   true->
										   ResultList  
									end;   
								_-> [] 
							end;
						_->  [] 
					end;
				_->[]
		end
	end.

%%通知客户端npc任务数据
call_client_npc_info(List,PS)->
	?TASK_TRACE("call_client_npc_info, INFO:[~p]~n", [List]),
	{ok,Data} = pt_30:write(30008, [List]),
	lib_send:send_to_sid(PS#player.other#player_other.pid_send, Data).

%%在可接任务中获取npc任务信息 ets_task_query_cache
get_npc_in_active(NpcId,PlayerId)->
	%?TASK_TRACE("get_npc_in_active ~p ~n",[{NpcId,PlayerId}]),
	case ets:lookup(?ETS_TASK_QUERY_CACHE, PlayerId) of
		[{PlayerId,List}]->get_npc_data_from_query(List,NpcId);
		_->[]
	end.
	
%%获取npc任务信息
get_npc_in_data(main,NpcId,State,PlayerStatus)->
	List = get({role_task_list,State}),
	?TASK_TRACE("get_npc_in_data ~p, State=~p ~n", [list_to_tuple(List), State]),
 		get_npc_data_from_pid(List,NpcId,State,PlayerStatus);
get_npc_in_data(daily,NpcId,State,PlayerStatus)->
	List = get({daily_task_list,State}),
    RetList = get_npc_data_from_pid(List,NpcId,State,PlayerStatus),
    RetList.

%%在进程字典中获取npc任务信息
get_npc_data_from_pid(List,NpcId,State,PlayerStatus)-> 
	lists:foldl(fun(TaskProcessId,Sum)->
						case get_task_process(TaskProcessId) of
							TaskProcess when is_record(TaskProcess, task_process)->
								case tpl_task:get(TaskProcess#task_process.tid) of
									Task when is_record(Task, tpl_task) ->
										case State of 
											?TASK_NOT_FINISH ->
												%%util:make_list(Sum, {TaskProcessId, Task#tpl_task.tid,State})
												if Task#tpl_task.end_npc =:= NpcId ->
													   util:make_list(Sum, {TaskProcessId, Task#tpl_task.tid,State});
												   true->
													   Sum
												end;
											?TASK_FINISH->
												if Task#tpl_task.end_npc =:= NpcId ->
													   util:make_list(Sum, {TaskProcessId, Task#tpl_task.tid,State});
												   true->
													   Sum
												end;
											?TASK_CAN_TRIGGER->
												if Task#tpl_task.start_npc =:= NpcId ->
                                                        WorldLevelTaskOpen = lib_world_level:get_task_status(PlayerStatus#player.level),
                                                        %%玩家需要达到世界等级区间才可以领取相应的自强不息任务
                                                        if
                                                            NpcId =:= ?NPC_ID_OF_SELF_IMPROVE_TASK andalso WorldLevelTaskOpen =:= false -> 
                                                                [];
                                                            true ->
                                                                util:make_list(Sum, {TaskProcessId, Task#tpl_task.tid,State})
                                                        end;
												   true->
													   Sum
												end;
											_->
												Sum
										end;
									_->Sum
								end;
							_-> 
								Sum
						end
				end,0,List). 

%%从可接任务中获取npc任务信息
get_npc_data_from_query(List,NpcId)->
	lists:foldl(fun(TaskId,Sum)->
						case tpl_task:get(TaskId) of
							Task when is_record(Task, tpl_task)-> 
								case Task#tpl_task.start_npc of
									NpcId->
										util:make_list(Sum, {0, Task#tpl_task.tid, ?TASK_CAN_TRIGGER});
									_->
										Sum
								end;
							_->
								Sum
						end
				end,0,List).                                                
%-------------------------------
%         任务查询函数
%-------------------------------

%%获取角色所有任务
get_all_task()->
	get({role_task_list,0})++get({role_task_list,1}) ++ get({role_task_list,2}) ++get({daily_task_list,0})
		++get({daily_task_list,1}) ++ get({daily_task_list,2}).

%%获取角色所有日常任务
get_all_daily_task() ->
	get({daily_task_list,0})++get({daily_task_list,1}) ++ get({daily_task_list,2}).

%%获取角色所有主线， 支线任务
get_all_role_task()->
	get({role_task_list,0})++get({role_task_list,1}) ++ get({role_task_list,2}).

%%从多个TaskPid中获取一个TaskPid
get_one_taskpid(List,Size) ->
    F=fun(_,{List,GotOneNotAccept,Result})-> 
            [TaskProcessId|Rest] = List,
            case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
                [Task]->
                    if
                        Task#task_process.state =:= 2 ->
                            if
                                GotOneNotAccept =:= false ->
                                    {ok,{Rest,true,Result++ [{TaskProcessId, Task#task_process.tid, Task#task_process.state, get_mark_info(Task#task_process.mark), Task#task_process.grade}]}};
                                true ->
                                    {ok,{Rest,GotOneNotAccept,Result}}
                            end;
                        true ->
                            {ok,{Rest,GotOneNotAccept,Result++ [{TaskProcessId, Task#task_process.tid, Task#task_process.state, get_mark_info(Task#task_process.mark), Task#task_process.grade}]}}
                    end;
                [] ->
                    {ok,{Rest,GotOneNotAccept,Result}}
            end 
    end,  
    {ok,{_,_,Result}} = util:for(1, erlang:min(length(List), Size), F, {List,false,[]}).

%%从多个Task中获取一个Task
get_one_task(List) ->
    F=fun(Task,RetVal)-> 
            {GotOneNotAccept,Result} = RetVal,
            case is_record(Task,task_process) of
                true ->
                    if
                        Task#task_process.state =:= 2 ->
                            if
                                GotOneNotAccept =:= false ->
                                    {true,[Task | Result]};
                                true ->
                                    {GotOneNotAccept,Result}
                            end;
                        true ->
                            {GotOneNotAccept,[Task | Result]}
                    end;
                false ->
                    {GotOneNotAccept,Result}
            end 
    end,  
    {_,Result} = lists:foldl(F,{false,[]},List).%% util:for(1, erlang:min(length(List), Size), F, {List,false,[]}).


%%获取玩家所有完成/未完成任务到客户端
get_all_task_2_client(PS,Size)->
	?TASK_TRACE("get_all_task_2_client, playerId=~p, Size=~p, ~n", [PS#player.id, Size]),
	add_can_accept_daily_task(PS, ?ALL_CAN_ACCEPT_TYPE),
	List = get_all_task(), 
   
    {ok,{_,_,Result}} = get_one_taskpid(List,Size),
	case pt_30:write(30006,[Result,length(Result)]) of
				{ok, Data} -> 
					lib_send:send_to_sid(PS#player.other#player_other.pid_send, Data);
				_->
					?WARNING_MSG("make data of proto 30006 error ~n",[])
					end .
%%获取任务进度参数
get_mark_info(Mark)->
	case Mark of
		[_,{_,_,NowNum}]-> NowNum;
		[_,{_}]-> 0;
		[_,{_,_}]->0;
		[_,{_,_,_,NowNum}]-> NowNum;
		Err->
			?ERROR_MSG("error task mark ~p in get_mark_info",[Err]),
			0
	end.
%-----------------------------
%   消耗元宝自动完成任务
%-----------------------------   

%%通过任务id获取任务子表数据
get_task_detail_by_tid(TaskId)->
	case  tpl_task:get(TaskId) of
		Tpl when is_record(Tpl, tpl_task) ->
			case tpl_task_detail:get(Tpl#tpl_task.type) of
				Task when is_record(Task, temp_task_detail) ->
					Task;
				_-> 
					?ERROR_MSG("no data in table temp_task_detail ~n",[]),
					{false,?UNKNOW_ERROR}%任务不在任务模板子表
			end;
		_-> 
			?ERROR_MSG("no data in table temp_task ~n",[]),
			{false,?UNKNOW_ERROR}%任务模板不存在
	end.

%%消耗元宝自动完成任务
auto_finish_task_by_coin(PS,TaskProcessId)->
	case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
		[TaskProcess] when is_record(TaskProcess, task_process)->
			case tpl_task_detail:get(TaskProcess#task_process.type) of
				TempTaskDetail when is_record(TempTaskDetail, temp_task_detail)->  
					check_coin_auto_finish(TempTaskDetail#temp_task_detail.coin, PS, TaskProcessId);
				_->
					{false,?UNKNOW_ERROR}
			end;
		_->
			{false,?TASK_NOT_IN_PROCESS}
	end.

%%检测任务是否支持消耗元宝完成		
check_coin_auto_finish(Cost,PS,TaskProcessId)->
		case Cost of
			0-> 
			{false,?NOT_COIN_TASK};
			Data ->
			do_coin_auto_finish(Data,PS,TaskProcessId)
		end.

%%尝试消耗元宝完成任务（调用游戏币模块） 改逻辑
%%提前判断背包是否满
do_coin_auto_finish(Cost,PS,TaskProcessId)->
	[TaskProcess] = ets:lookup(?ETS_TASK_PROCESS, TaskProcessId),
	?TASK_TRACE("do_coin_auto_finish: INFO=~p, UID=~p~n", [TaskProcess, PS#player.id]),
	case tpl_task:get(TaskProcess#task_process.tid) of 
		[] ->
			skip;
		Task ->
			%%先判断背包是否已满
			case can_put_into_bag(PS, Task#tpl_task.goods_list) of
				true ->
					case Cost > (PS#player.gold + PS#player.bgold) of 
						true->  
							%%元宝不足
							{false,?TASK_NOT_ENOUGH_COIN};
						_->	
							case lib_money:cost_money(PS, Cost, ?MONEY_T_BGOLD, ?LOG_AUTO_FINISH_TASK) of
								NewPs1 when is_record(NewPs1, player)->   
                                    lib_player:send_player_attribute3(NewPs1),
									case do_coin_auto_success(NewPs1, TaskProcess, Task) of
										NewPs2 when is_record(NewPs2,player)->
											{ok,NewPs2};
										_->
											?ERROR_MSG("give present to player fail ~n",[]),
											{ok, NewPs1}
									end;
								_->
									?TASK_TRACE("do_coin_auto_finish fail errorCode=~p~n", [?TASK_NOT_ENOUGH_COIN]),
									{false,?TASK_NOT_ENOUGH_COIN}
							end
					end;
				_->
					%%背包已满
					?TASK_TRACE("do_coin_auto_finish fail, bag is full.:  INFO=~p, UID=~p~n", [TaskProcess, PS#player.id]),
					{false,?FAIL_FOR_EXCEED_BAG_CELL}
			end
	end.

%%消耗元宝完成任务逻辑处理成功, 玩家经常里面调用
do_coin_auto_success(PS, TaskProcess, Task)->
    Exp = get_award_exp_count(PS,TaskProcess#task_process.type, TaskProcess#task_process.grade,TaskProcess#task_process.tid),
    gen_server:cast(PS#player.other#player_other.pid, {add_exp, Exp}),
	case do_player_get_goods(Task#tpl_task.goods_list,PS) of 
		NewPs  when is_record(NewPs, player)->
			%日常任务没有后续任务
			do_finish(TaskProcess, PS#player.id, 1, remote), 
			NewPs;
		_->skip
	end.

%------------------------------------
%   判断玩家采集的物品是否与任务有关
%------------------------------------ 

%%判断玩家采集的物品是否与指定任务有关
check_collect_task(TaskProcessId,ItemId,_PlayerId)->
	?TASK_TRACE("check_collect_task: Info uid=~p pid=~p ItemId=~p~n", [_PlayerId, TaskProcessId, ItemId]),
  case get_task_process(TaskProcessId) of
	  null ->
		  ?WARNING_MSG("no task process~n",[]),
		  false;
	  Task -> 
		  case Task#task_process.mark of
			  [?COLLECT_EVENT,{ItemId,_,_}]->true;
			  _->  
				  false
		  end
  end.

check_dungeon_task(TaskProcessId,ItemId,_PlayerId)->
	?TASK_TRACE("check_collect_task: Info uid=~p pid=~p ItemId=~p~n", [_PlayerId, TaskProcessId, ItemId]),
	case get_task_process(TaskProcessId) of
		null ->
			?WARNING_MSG("no task process~n",[]),
			false;
		Task -> 
			case Task#task_process.mark of
				[?DUNGEON_EVENT,{ItemId,_,_}]->true;
				_->  
					false
			end
	end.
%------------------------------
%-           GM指令
%------------------------------

%%-xtask	清空角色所接的所有任务	$xtask	清空角色所接的所有任务
do_task_gm("-xtask",[PlayerId])-> 
	do_clean_task_finish(PlayerId),
	do_clean_task_process(PlayerId),	
	do_clean_daily_task_finish(PlayerId),
	init_pid_data();  

%%taskcomplete 自动完成指定编号的任务	-taskcomplete 1100	完成编号为1100的任务
%%根据TaskProcessId完成任务进度
do_task_gm("-taskcomplete",[Ps,TaskId])->
	Result = db_agent_task:get_trigger_task_by_uid_taskId(Ps#player.id, TaskId),
	?TASK_TRACE("do_task_gm ~p~n", [Result]),
	lists:foreach(fun(Task) -> 
						  D = list_to_tuple([task_process| Task]),
						  ?TASK_TRACE("do_task_gm D=~p~n", [D]),
						  TaskProcessId = D#task_process.id,
						  ?TASK_TRACE("do_task_gm TaskProcessId=~p~n", [TaskProcessId]),
						  case ets:lookup(?ETS_TASK_PROCESS, TaskProcessId) of
							  [TD]->   
								  upd_task_2_db_and_mem(TD,TD#task_process.mark,1),
								  NewTaskProcess = TD#task_process{state= 1},
								  ?TASK_TRACE("do_task_gm NewTaskProcess=~p~n", [NewTaskProcess]),
								  send_task_process_list(Ps, [NewTaskProcess]);
							  %{ok,Data} =  pt_30:write(30501,[[{Tid,?TASK_FINISH,0}],1]),
							  %lib_send:send_to_sid(Ps#player.other#player_other.pid_send, Data);
							  _->
								  ?TASK_TRACE("do_task_gm error TaskId=~p~n", [TaskId]),
								  ?WARNING_MSG("no task data find in pid of id ~p ~n",[TaskProcessId])
						  end
				  end, Result);  
%%taskgoto跳到特定的任务
do_task_gm("-taskgoto", [Ps,TaskId])->
	%%第一步判断任务是否存在
	case tpl_task:get(TaskId) of 
		Task when is_record(Task, tpl_task)->
			TaskType = Task#tpl_task.type,
			if TaskType =:= ?MAIN_TASK orelse TaskType =:= ?BRANCHE_TASK ->
				   %%如果是主线任务   
				   %%第二步，完成已存在的主线任务
				   ?TASK_TRACE("do_task_gm start, pid=~p, taskId=~p ~n", [Ps#player.id, TaskId]),
				   AllMainTask = get_all_role_task(),
				   ?TASK_TRACE("AllMainTask info ~p ~n", [AllMainTask]),
				   lists:foreach(fun(TaskProcessId)->
										 case get_task_process(TaskProcessId) of 
											 null -> skip;
											 TaskProcess ->
												 do_finish(TaskProcess, Ps#player.id, 1, local),
												 call_auto_fin_2_client(Ps#player.other#player_other.pid_send,TaskProcess#task_process.id)
										 end
								 end, AllMainTask),
				   %%第三步， 修改taskFinish
				   util:for(1, TaskId, fun(Tid) -> 
											   case tpl_task:get(Tid) of 
												   TaskItem when is_record(TaskItem, tpl_task) ->
													   TaskFinish = get_finish_task(Ps#player.id),
													   NewTaskFin = upd_finish_task(TaskFinish,TaskItem#tpl_task.level,TaskItem#tpl_task.tid),
													   ets:insert(?ETS_TASK_FINISH, NewTaskFin);
												   _->
													   skip
											   end
							end),
				   TaskFinish = get_finish_task(Ps#player.id),
				   db_agent_task:save_finish_task(TaskFinish),
				   
				   %%第四步领取任务
				   TaskState = get_task_process_state_for_accept(Task),
				   NewTaskProcess = lib_task:add_task_process(Task, Ps, TaskState, ?TASK_COMMON_GRADE),
				   send_task_process_list(Ps, [NewTaskProcess]);
			   true ->
				   %%日常任务类型
				   TaskGrade = get_task_grade_for_daiytask_gm(Task),
				   add_daily_task(TaskId, Ps, TaskGrade),
				   skip
			end;
		_->
			?TASK_TRACE("taskgoto tempTask is null, taskId=~p~n", [TaskId]),
			skip
	end,
    lib_task:call_event(Ps,lv,{Ps#player.level});
do_task_gm(_,_)->
	skip.
%%获取日常任务品质， gm方法特有
get_task_grade_for_daiytask_gm(Task)->
	case Task#tpl_task.type of 
		?GOD_COMMAND_TASK ->
			1;
		?MASTER_TASK ->
			1;
		_->
			0
	end.

%%清空玩家主/支线完成任务信息
do_clean_task_finish(PlayerId)->
	db_agent_task:clean_palyer_task_finish_in_db(PlayerId),
	init_fin_role_task(PlayerId).
%%清空玩家任务进度
do_clean_task_process(PlayerId)->
	db_agent_task:clean_player_task_process_in_db(PlayerId),
	clean_ets_task_process_data(PlayerId).
%%清空ets玩家任务进度
clean_ets_task_process_data(PlayerId)->
	ets:match_delete(?ETS_TASK_PROCESS, #task_process{uid = PlayerId,_='_'}). 
%%清空玩家日常任务完成进度
do_clean_daily_task_finish(PlayerId)->
	ets:match_delete(?ETS_TASK_DAILY, #task_daily{uid=PlayerId, _='_'}),
	db_agent_task_daily:clean_task_daily_by_uid(PlayerId),
	init_daily_task_finish(PlayerId).

%%根据任务类型，等级区间获取任务id, 日常任务使用
%%师门令任务，天道令任务可以重复接任务
%%@param Type 任务类型
%%@param MinLevel   开始等级
%%@param MaxLevel   结束等级
%%@param Count   	获取数量
get_task_id_list_by_type_and_level(Type, MinLevel, MaxLevel, Count) ->
	?TASK_TRACE("Type:~p, MinLevel:~p, MaxLevel:~p~n",[Type, MinLevel, MaxLevel]),
	F = fun(Level, Result) ->
				List = tpl_task:get_by_type_level(Type, Level),
				IdList = [TD#tpl_task.tid || TD<-List],
				{ok, Result++IdList}
		end,
	{ok, ResultList} = util:for(MinLevel, MaxLevel, F, []),
	?TASK_TRACE("get_task_id_list_by_type_and_level Data:~p~n",[ResultList]),
	case ResultList of
		[] -> [];
		 _  ->
			F1 = fun(_, RetIdList) ->
						 {ok, [lists:nth(util:rand(1, length(ResultList)), ResultList) | RetIdList]}
				 end,
			{ok, Ret} = util:for(1, Count, F1, []),
			Ret
	end.

%%得到师门令，天道令任务等级
get_task_random_grade(task_master) ->
	util:rand(?TASK_MASTER_GRADE_WHITE, ?TASK_MASTER_GRADE_ORANGE);
get_task_random_grade(task_heaven) ->
	util:rand(?TASK_HEAVEN_GRADE_TIAN, ?TASK_HEAVEN_GRADE_HUANG).
  
%%根据玩家状态， 随机获取相应的日常任务
%%@param Count   			获取数量
%%@param PlayerStatus   	玩家状态
get_random_daily_task(task_master, {Count, PlayerStatus,TaskQuality}) ->
	?TASK_TRACE("get_random_daily_task Start ~p~n",[PlayerStatus#player.id]),
	case tpl_task_factor:get(?MASTER_TASK, ?TASK_MASTER_GRADE_WHITE) of
		TaskFactor when is_record(TaskFactor, temp_task_factor) ->
			
			IdList = get_task_id_list_by_type_and_level(?MASTER_TASK, 
														max(0, PlayerStatus#player.level - TaskFactor#temp_task_factor.level_span),
														PlayerStatus#player.level,
														Count),
            if
                TaskQuality > 0 ->
			        [{Id, TaskQuality, ?TASK_MASTER_STATE_COMMON}|| Id<-IdList];
                true ->
                    [{Id, get_task_random_grade(task_master), ?TASK_MASTER_STATE_COMMON}|| Id<-IdList]
            end;
		_->
			[]
	end;
get_random_daily_task(task_heaven, {Count, PlayerStatus}) ->
	case  tpl_task_factor:get(?GOD_COMMAND_TASK, ?TASK_HEAVEN_GRADE_TIAN)of 
		TaskFactor when is_record(TaskFactor, temp_task_factor) ->
			
			IdList = get_task_id_list_by_type_and_level(?GOD_COMMAND_TASK, 
														max(0, PlayerStatus#player.level - TaskFactor#temp_task_factor.level_span),
														PlayerStatus#player.level,
														Count),
			[{Id, get_task_random_grade(task_master)}|| Id<-IdList];
		_->
			[]
	end;		
get_random_daily_task(task_daily, {Count, PlayerStatus, TaskType})->
	case tpl_task_factor:get(TaskType, ?TASK_COMMON_GRADE) of
		TaskFactor when is_record(TaskFactor, temp_task_factor) ->
			get_task_id_list_by_type_and_level(TaskType, 
											   max(0, PlayerStatus#player.level - TaskFactor#temp_task_factor.level_span),
											   PlayerStatus#player.level,
											   Count);
		_->
			[]
	end.

%%玩家新增新日常的任务进度
%%天道令任务， 师门令任务调用接口
add_daily_task(TaskId, PlayerStatus, Grade) ->
	?TASK_TRACE("add_daily_task Grade=~p, TaskId=~p~n", [Grade, TaskId]),
	case tpl_task:get(TaskId) of
		[] ->{false, ?TASK_NOT_EXIT};
		TaskInfo ->
			%%do_add_task(TaskInfo, PlayerStatus),
			TaskProcess = add_task_process(TaskInfo, PlayerStatus, 0, Grade),
			%%检验错错误TODO, TODO
			%upd_daily_task_fin(PlayerStatus#player.id, TaskInfo#tpl_task.type),
            get_all_task_2_client(PlayerStatus,12)
            %%send_task_process_list(PlayerStatus, [TaskProcess])
	end.

%%获取奖励的经验值
get_award_exp_count(PlayerStatus,TaskType, Grade,Tid)->
    TaskFactor = tpl_task_factor:get(TaskType, Grade),
    Level = max(1, PlayerStatus#player.level),

    if
        Tid > 0 ->
            Task = tpl_task:get(Tid),  
            if
                %%自强不息任务，在世界等级区间的玩家有经验加成 byCXF
                Task#tpl_task.type =:= ?SELF_IMPROVE_TASK ->
                    AddRadio = lib_world_level:get_exp_ratio(PlayerStatus#player.level);
                true ->
                    AddRadio = 0
            end;
        true ->
            AddRadio = 0
    end,

    case TaskFactor of
        [] ->
            10000*(1+AddRadio);
        %%util:floor(Level*Level*Level + Level*Level + 3 + 100);
        R ->
            R#temp_task_factor.fact4*(1+AddRadio)
            %%util:floor(R#temp_task_factor.fact1*Level*Level*Level + 
            %%R#temp_task_factor.fact2*Level*Level + 
            %%R#temp_task_factor.fact3*3 + R#temp_task_factor.fact4)
    end.

%%task_process
send_task_process_list(PlayerStatus, TaskProcessList)->
    {_,Result} = get_one_task(TaskProcessList),
	?TASK_TRACE("send_task_process: uid=~p, Info=~p~n", [PlayerStatus#player.id, Result]),
	case  length(Result) of
		0->
			skip;
		_->
			send_30501_pack(PlayerStatus, packend_task_process_list(Result))
	end.

%%打包数据
packend_task_process_list(TaskProcessList)->
	lists:map(fun(TaskProcess) -> {TaskProcess#task_process.id, 
								   TaskProcess#task_process.tid,
								   TaskProcess#task_process.state,
								   get_mark_info(TaskProcess#task_process.mark),
								   TaskProcess#task_process.grade}end, TaskProcessList).

%%发30501, 玩家新接任务时，  服务器端推送包到客户端  
send_30501_pack(PlayerStatus, TaskList)->
	?TASK_TRACE("send_30501_pack: uid=~p, taskList=~p, Len=~p~n", [PlayerStatus#player.id, TaskList, length(TaskList)]),
	%%如果长度空， 不发包
	case length(TaskList) of
		0 ->
			skip;
		_->
			{ok, BinData} = pt_30:write(30501, [TaskList, length(TaskList)]),
			send_and_pack(PlayerStatus, BinData)
	end.

%%发包
send_and_pack(PlayerStatus, BinData)->
	lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData).

%%检查位置相关的任务
checkMove(PlayerStatus) ->
    Scene = PlayerStatus#player.scene div 100,
    PosX = PlayerStatus#player.battle_attr#battle_attr.x,
    PosY = PlayerStatus#player.battle_attr#battle_attr.y,
    lib_task:call_event(PlayerStatus,find_map,{Scene,PosX,PosY}),
    lib_task:call_event(PlayerStatus,collect2,{Scene,PosX,PosY}).
