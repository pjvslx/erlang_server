%%%-----------------------------------
%%% @Author  : zfz
%%% @Created : 2013.04.12
%%% @Description: 师门令任务数据
%%%-----------------------------------
-module(lib_task_master).
-include("common.hrl").
-include("record.hrl"). 
-include("task.hrl"). 
-include("debug.hrl").
-include("log.hrl").
-include("goods.hrl").
-compile(export_all).

%% ====================================================================
%% API functions
%% =======================================d=============================
%%

%%初始化玩家师门令任务
%%如果没有数据需要初始化 TODO
%%每天刷新师门令数据 TODO
init_task_master(PlayerStatus)->
    ?TASK_TRACE("Init Task Master Start ~p~n", [PlayerStatus#player.id]),
    NowTime = util:unixtime(),
    case db_agent_task_master:get_task_master_by_uid(PlayerStatus#player.id) of
        [] -> NewTaskMaster = #task_master{uid = PlayerStatus#player.id, 
                master_task = lib_task:get_random_daily_task(task_master, {3, PlayerStatus,0}),
                refresh_time = NowTime,
                create_time = NowTime},
            db_agent_task_master:insert_task_master(NewTaskMaster#task_master.uid, 
                NewTaskMaster#task_master.master_task, 
                NewTaskMaster#task_master.refresh_time,
                NewTaskMaster#task_master.create_time),
            %?TRACE("init_task_master ~p, uid=~p~n", [NewTaskMaster,PlayerStatus#player.id]),
            ets:insert(?ETS_TASK_MASTER, NewTaskMaster),
            NewTaskMaster;
        TaskMaster ->
            TaskMaster
    end, 
    ?TASK_TRACE("Init Task Master End ~p~n", [PlayerStatus#player.id]).

remove_master_task_list(PlayerStatus,TaskProcessId) ->
    ets:delete(?ETS_TASK_PROCESS,TaskProcessId),
    put({daily_task_list,0},[]),
    db_agent_task:delete_task_by_uid(PlayerStatus#player.id,9),
    lib_task:get_all_task_2_client(PlayerStatus,12).

%%获取玩家师门令任务
get_task_master(PlayerStatus)->
    ?TASK_TRACE("get_task_master Start ~p~n",[PlayerStatus#player.id]),

    case get_task_master_by_uid(PlayerStatus#player.id) of
        [] ->
            io:format("123456789"),
            skip;
        R -> 
            case R#task_master.master_task of 
                [] ->
                    NewR = R#task_master{master_task = lib_task:get_random_daily_task(task_master, {3, PlayerStatus,0})},
                    db_agent_task_master:update_task_master(PlayerStatus#player.id, NewR#task_master.master_task),
                    ets:insert(?ETS_TASK_MASTER, NewR);
                _->
                    NewR = R
            end,
            
            %%put({role_task_list,State},lists:delete(TaskProcessId, RoleTask)),

            case lib_task:get_one_daily_task_fin(PlayerStatus#player.id, ?MASTER_TASK) of
                [] -> skip;
                [TaskDaily] ->
                    case tpl_task_detail:get(?MASTER_TASK) of 
                        TempTaskDetail when is_record(TempTaskDetail, temp_task_detail) ->
                            if
                                TaskDaily#task_daily.used_trigger_count >= TempTaskDetail#temp_task_detail.trigger_time ->
                                    send_30605_pack(PlayerStatus, [0,0]);
                                true -> 
                                    send_30605_pack(PlayerStatus, [TempTaskDetail#temp_task_detail.cycle_time-TaskDaily#task_daily.used_cycle_count,
                                            TempTaskDetail#temp_task_detail.meanw_trigger- TaskDaily#task_daily.trigger_count])
                            end;
                        _->
                            skip
                    end
            end,
            send_30601_pack(PlayerStatus, [NewR#task_master.master_task,length(NewR#task_master.master_task)])
    end.


%%获取玩家师门令任务
get_task_master_by_uid(Uid)->
    case ets:lookup(?ETS_TASK_MASTER, Uid) of
        [] -> [];
        [R] ->
            if
                is_record(R,task_master) ->
                    R;
                true ->
                    %%db_agent_task_master:delete_task_master(Uid),
                    []
            end
    end.

%%领取师门令
receive_task_master(PlayerStatus, Idx, Tid)->
    ?TASK_TRACE("receive_task_master ~p, ~p~n", [Tid, Idx]),
    case PlayerStatus#player.level < 36 of
        true ->
            lib_player:send_tips(1402001, [], PlayerStatus#player.other#player_other.pid_send);
        false ->
            case tpl_task:get(Tid) of
                Task when is_record(Task, tpl_task) andalso Task#tpl_task.type =:= ?MASTER_TASK -> 
                    case lib_task:get_one_daily_task_fin(PlayerStatus#player.id, Task#tpl_task.type) of
                        [TaskDaily] when is_record(TaskDaily, task_daily)->
                            TempTaskDetail = tpl_task_detail:get(Task#tpl_task.type),
                            Result = lib_task:check_trigger_daily(TaskDaily, TempTaskDetail),
                            case Result of 
                                ?CAN_TRIGGER ->
                                    case get_task_master_by_uid(PlayerStatus#player.id) of
                                        [] ->skip;
                                        R ->
                                            if length(R#task_master.master_task) < Idx ->
                                                    skip;
                                                true ->
                                                    ReceiveItem = lists:nth(Idx, R#task_master.master_task),
                                                    {_, Grade, _} = ReceiveItem, 

                                                    %% 添加任务
                                                    lib_task:add_daily_task(Tid, PlayerStatus, Grade),
                                                    %% 刷新当前列表
                                                    [NewTaskItem] = lib_task:get_random_daily_task(task_master, {1, PlayerStatus,0}),
                                                   
                                                    Fun = fun(CurTaskItem,RetInfo) ->
                                                        {HaveRep,RetList} = RetInfo,
                                                        case CurTaskItem of
                                                           ReceiveItem ->
                                                               if
                                                                   HaveRep =:= false ->
                                                                       {true,RetList ++ [NewTaskItem]};
                                                                   true ->
                                                                       {HaveRep,RetList ++ [CurTaskItem]}
                                                               end;
                                                           _ ->
                                                               {HaveRep,RetList ++ [CurTaskItem]}
                                                        end
                                                    end,

                                                    {_,NewList} = lists:foldl(Fun,{false,[]},R#task_master.master_task),

                                                    NewR = R#task_master{master_task = NewList},
                                                    ets:insert(?ETS_TASK_MASTER, NewR),
                                                    db_agent_task_master:update_task_master(PlayerStatus#player.id, NewR#task_master.master_task),
                                                    %更新日常任务计算
                                                    lib_task:update_task_daily_trigger_count(TaskDaily, TempTaskDetail, 1),
													
													%完成活跃度接口
													lib_activity:finish_activity_single(PlayerStatus,1,2),

                                                    lib_player:send_tips(6002002, [], PlayerStatus#player.other#player_other.pid_send) ,
                                                    %%返回日常任务数据
                                                    get_task_master(PlayerStatus)
                                            end
                                    end;
                                _->
                                    ?TASK_TRACE("receive_task_master error, exceed max times Tid=~p, uid=~p~n", [Tid, PlayerStatus#player.id])
                            end;		
                        _->
                            ?TASK_TRACE("receive_task_master error, TaskDaily is null Start Tid=~p, uid=~p~n", [Tid, PlayerStatus#player.id]),
                            skip
                    end;	
                _->
                    ?TASK_TRACE("receive_task_master error, task is null Start Tid=~p~n", [Tid]),
                    skip
            end
    end.

%%免费方式刷新师门令
refresh_by_free(PlayerStatus)->
    {Result, Value} = check_refresh_cd(PlayerStatus#player.id,1),
     case Result of 
        ?TASK_MASTER_CD_ERROR ->
            send_30603_pack(PlayerStatus, [Result, Value]);
        _ ->
            send_30603_pack(PlayerStatus, [Result, Value]),
            refresh(PlayerStatus,0)				
    end.

%%师门令刷新 
%%判断师门数量是否足够
refresh_by_order(PlayerStatus)->
    ?TASK_TRACE("refresh_by_order Start uid=~p~n", [PlayerStatus#player.id]),
    Count = goods_util:get_bag_goods_num_total(PlayerStatus, ?GOODS_ID_MASTER_ORDER_BIND),
    ?TASK_TRACE("refresh_by_order MasterCount=~p~n", [Count]),
    case Count>0 of 
        true ->
            case goods_util:del_bag_goods_new(PlayerStatus, ?GOODS_ID_MASTER_ORDER_BIND, 1,?BINDSTATE_BIND_FIRST, ?LOG_MASTER_TASK) of
                true->
                    send_30603_pack(PlayerStatus, [?OPT_SUCCESS, 0]),
                    refresh(PlayerStatus,0);
                {false, not_enough}->
                    ?TASK_TRACE("refresh_by_order error. MasterOrder Count less=~n"),
                    send_30603_pack(PlayerStatus, [?TASK_MASTER_ORDER_LESS, 0]);
                _->	
                    ?TASK_TRACE("refresh_by_order error.bad_args~n"),
                    send_30603_pack(PlayerStatus, [?UNKNOW_ERROR, 0])
            end;
        _->
            %%师门令数量不够
            send_30603_pack(PlayerStatus, [?TASK_MASTER_ORDER_LESS, Count])
    end.

%%元宝刷新 
%%判断元宝数量是否足够
refresh_by_gold(PlayerStatus)->
    GoldNum = PlayerStatus#player.gold,
     case GoldNum> ?MIN_REFRESH_NEED_GOLD of 
        true ->
            case lib_money:cost_money(PlayerStatus, ?MIN_REFRESH_NEED_GOLD, ?MONEY_T_GOLD, ?LOG_MONEY_MASTER_REFRESH) of
                NewPlayerStatus when is_record(NewPlayerStatus, player)->
                    send_30603_pack(NewPlayerStatus, [?OPT_SUCCESS, 0]),
                    lib_player:send_player_attribute3(NewPlayerStatus),
                    refresh(NewPlayerStatus,?TASK_MASTER_GRADE_ORANGE),
                    {ok,NewPlayerStatus};
                _->
                    send_30603_pack(PlayerStatus, [?TASK_MASTER_GOLD_LESS,0]),
                    {ok,PlayerStatus}
            end;
        _->
            %%元宝不足
            send_30603_pack(PlayerStatus, [?TASK_MASTER_GOLD_LESS,0]),
            {ok,PlayerStatus}
    end.

%%私有方法， 一键刷新， 免费刷新调用
refresh(PlayerStatus,TastQuality)->
    Now = util:unixtime(),
    case lib_task:get_random_daily_task(task_master, {3, PlayerStatus,TastQuality}) of 
        [] ->
            skip;
        MasterTask  ->
            TaskMaster = get_task_master_by_uid(PlayerStatus#player.id),
            NewTaskMaster = #task_master{uid = PlayerStatus#player.id,
                master_task = MasterTask,
                refresh_time = Now},
            ets:insert(?ETS_TASK_MASTER, NewTaskMaster),
            db_agent_task_master:update_task_master(PlayerStatus#player.id, MasterTask, Now),
            send_30601_pack(PlayerStatus, [MasterTask,length(MasterTask)]),
            ?TRACE("[INFO] refresh_by_free Success ~p~n", [PlayerStatus#player.id])
    end.


%%免费刷新限制cd条件, 返回{Reuslt, Value}
%%ActionType 1:刷新 2:查看
check_refresh_cd(Uid,ActionType)->
    case get_task_master_by_uid(Uid) of
        [] -> skip;
        R ->
            Now = util:unixtime(),
            TimeSpan = Now - R#task_master.refresh_time,
            if TimeSpan < ?TASK_MASTER_CD_TIME -> 
                    {?TASK_MASTER_CD_ERROR, ?TASK_MASTER_CD_TIME - TimeSpan};
                ActionType =:= 1 ->
                    {?OPT_SUCCESS,?TASK_MASTER_CD_TIME};
                true -> 
                    {?OPT_SUCCESS,0}
            end
    end.


%%私有方法， 30601发包
send_30601_pack(PlayerStatus, [ResultList,Len]) ->
    %%打包计算 奖励经验值
    F = fun({Tid, Grade, State}) ->
            {Tid, Grade, State, lib_task:get_award_exp_count(PlayerStatus, ?MASTER_TASK ,Grade,0)}
    end,
    NewResultList = [F(Item) || Item <- ResultList],

    Count = goods_util:get_bag_goods_num_total(PlayerStatus, ?GOODS_ID_MASTER_ORDER_BIND),
    {ok, Data} = pt_30:write(30601, [NewResultList, Len,Count,PlayerStatus#player.gold]),
    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data).

%%资源销毁
dispose(Uid) ->
    ?TASK_TRACE("lib_task_master dispose uid~p~n", [Uid]),
    ets:delete(?ETS_TASK_MASTER, Uid).
%% ====================================================================
%% Internal functions
%% ====================================================================
%%服务器推送 师门令领取次数， 当前可用次数
send_30605_pack(PlayerStatus, [ReceiveTimes, RarallelTimes]) ->
    {ok, BinData} = pt_30:write(30605, [ReceiveTimes, RarallelTimes]),
    send_and_pack(PlayerStatus, BinData).

%%服务器推送操作结果
%%Result 错误类型, Value:相应值
send_30603_pack(PlayerStatus, [Result, Value])->
    {ok, BinData} = pt_30:write(30603, [Result, Value]),
    send_and_pack(PlayerStatus, BinData).

%%发包
send_and_pack(PlayerStatus, BinData)->
    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData).
