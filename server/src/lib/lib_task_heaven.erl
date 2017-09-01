%%%-----------------------------------
%%% @Module  : lib_task_heaven
%%% @Author  : zfz
%%% @Created : 2013.04.12
%%% @Description: 师门令任务数据
%%%-----------------------------------
-module(lib_task_heaven).
-include("common.hrl").
-include("record.hrl"). 
-include("task.hrl"). 
-include("debug.hrl").
-include("log.hrl").
-compile(export_all).

%%全局的天道令数据
get_heaven(Id)->
    case ets:lookup(?ETS_HEAVEN, Id) of
        [] ->[];
        [R] -> check_heaven_time(R)
    end.

%%玩家天道令记录数据
get_task_heaven_by_uid(Uid)->
    case ets:lookup(?ETS_TASK_HEAVEN, Uid) of
        [] -> [];
        [R] -> check_task_heaven_time(R)
    end.

%%初始化全局天道令数据
init_heaven(Id)->
    ?TASK_TRACE("init_heaven Start ~n", []),
    case  db_agent_task_heaven:get_heaven(Id) of
        [] ->
            Now = util:unixtime(),
            db_agent_task_heaven:insert_heaven(Id, Now, 0),
            EtsHeaven = #heaven{id = Id, reset_time = Now, heaven_count = 0},
            ets:insert(?ETS_HEAVEN, EtsHeaven);
        Heaven -> 
            check_heaven_time(Heaven)
    end,
    ?TASK_TRACE("init_heaven End ~n", []).

%%检查天道令数据时间
check_heaven_time(Heaven) ->
    ?TASK_TRACE("check_heaven_time ~p ~p ~n", [Heaven#heaven.id, util:seconds_to_localtime(Heaven#heaven.reset_time)]),
    Now = util:unixtime(),
    {TodayMidNight, _} = util:get_midnight_seconds(Now),
    if TodayMidNight > Heaven#heaven.reset_time ->
            NewHeaven = Heaven#heaven{heaven_count = 0, 
                reset_time = Now},
            ets:insert(?ETS_HEAVEN, NewHeaven),
            db_agent_task_heaven:reset_heaven(Heaven#heaven.id),
            NewHeaven;
        true->
            Heaven
    end.

%%同步heaven数据进入db
update_heaven_to_db(HeavenId)->
    case get_heaven(HeavenId) of
        [] ->
            ?TASK_TRACE("not update", [now()]),
            skip;
        Heaven->
            ?TASK_TRACE("lib_trak_heaven update_heaven_to_db ~p~n", [now()]),
            db_agent_task_heaven:update_heaven(Heaven)
    end.

%%初始化玩家天道令记录数据
init_task_heaven(PlayerStatus)->
    ?TASK_TRACE("init_task_heaven Start ~p~n", [PlayerStatus#player.id]),
    case db_agent_task_heaven:get_task_heaven(PlayerStatus#player.id) of
        []->
            Now = util:unixtime(),
            TaskHeaven = #task_heaven{uid = PlayerStatus#player.id, 
                reset_time = Now,
                publish_count = 0, 
                publish_heavens = {0,0,0,0},
                receive_count = 0,
                receive_heavens = {0,0,0,0}},
            db_agent_task_heaven:insert_task_heaven(TaskHeaven),									  
            ets:insert(?ETS_TASK_HEAVEN, TaskHeaven);
        TaskHeaven ->
            check_task_heaven_time(TaskHeaven)
    end.

%%检查TaskHeaven时间
check_task_heaven_time(TaskHeaven)->
    ?TASK_TRACE("check_task_heaven_time ~p ~n", [TaskHeaven#task_heaven.uid]),
    Now = util:unixtime(),
    {TodayMidNight, _} = util:get_midnight_seconds(Now),
    if TodayMidNight > TaskHeaven#task_heaven.reset_time ->
            NewTaskHeaven = TaskHeaven#task_heaven{reset_time = Now, 
                publish_heavens = {0,0,0,0},
                receive_heavens = {0,0,0,0}},
            ets:insert(?ETS_TASK_HEAVEN, NewTaskHeaven),
            db_agent_task_heaven:reset_task_heaven(TaskHeaven#task_heaven.uid),
            NewTaskHeaven;
        true->
            TaskHeaven
    end.

%%获取天道令数据
get_heaven_list(PlayerStatus)->
    F = fun(HeavenId)->
            case get_heaven(HeavenId) of
                []->[];
                Heaven->
                    pack_heaven_data(PlayerStatus, Heaven)
            end
    end,
    send_30701_pack(PlayerStatus, lists:map(F, ?ALL_TASK_HEAVEN_IDS)).

%%打包heaven数据
pack_heaven_data(PlayerStatus, Heaven)->
    {Heaven#heaven.id, Heaven#heaven.heaven_count, 1000, 
        lib_task:get_award_exp_count(PlayerStatus, ?GOD_COMMAND_TASK ,Heaven#heaven.id,0)}.

%%发布天道令
publish_heaven(PlayerStatus, HeavenId)->
    %%判断玩家等级
    TempTaskDaily = tpl_task_daily:get(?GOD_COMMAND_TASK),
    if
        PlayerStatus#player.level >= TempTaskDaily#tpl_task_daily.level_limit ->
            %%判断天道令数量
            HeavenGoodCount = get_heaven_goods_count(PlayerStatus, HeavenId),
            ?TASK_TRACE("publish_heaven, HeavenId = ~p,HeavenGoodCount=~p~n", [HeavenId,HeavenGoodCount]),
            case HeavenGoodCount > 0 of 
                true ->
                    TaskHeaven = get_task_heaven_by_uid(PlayerStatus#player.id),
                    {TianCount, DiCount, XuanCount, HuangCount} = TaskHeaven#task_heaven.publish_heavens,
                    TempTaskDetail = tpl_task_detail:get(?GOD_COMMAND_TASK),
                    if (TianCount + DiCount + XuanCount + HuangCount) >= TempTaskDetail#temp_task_detail.cycle_time ->
                            send_oper_result_pack(PlayerStatus, 30702, ?TASK_HEAVEN_TIMES_LIMITED);
                        true->
                            use_heaven_goods(PlayerStatus,HeavenId),%%扣除对应的天道令
                            Heaven = lib_task_heaven:get_heaven(HeavenId),
                            NewHeaven = Heaven#heaven{heaven_count= Heaven#heaven.heaven_count + 1},
                            ets:insert(?ETS_HEAVEN, NewHeaven),
                            send_30701_pack(PlayerStatus, [pack_heaven_data(PlayerStatus, NewHeaven)]),
                            send_oper_result_pack(PlayerStatus, 30702, ?OPT_SUCCESS),

                            NewTaskHeaven = TaskHeaven#task_heaven{publish_count = TaskHeaven#task_heaven.publish_count + 1,
                                publish_heavens = modify_heavens(TaskHeaven#task_heaven.publish_heavens, HeavenId, 1)},
                            ets:insert(?ETS_TASK_HEAVEN, NewTaskHeaven),
                            db_agent_task_heaven:update_task_heaven_publish(PlayerStatus#player.id, 
                                NewTaskHeaven#task_heaven.publish_count, 
                                NewTaskHeaven#task_heaven.publish_heavens),
							%%调用完成活跃度接口
							lib_activity:finish_activity_single(PlayerStatus,1,1),
                            %%调用奖励接口
                            Exp = lib_task:get_award_exp_count(PlayerStatus, ?GOD_COMMAND_TASK, HeavenId,0),
                            case Exp > 0 of 
                                true -> 
                                    lib_task:cast_player_add_exp(PlayerStatus, Exp);
                                _->skip
                            end,
                            lib_task:call_event(PlayerStatus,god_command,{})
                    end;
                _->
                    send_oper_result_pack(PlayerStatus, 30702, ?TASK_HEAVEN_HAVE_NO_HEAVEN_ORDER)
            end;
        true ->
            send_oper_result_pack(PlayerStatus, 30702, ?TASK_HEAVEN_LEVEL_TOO_LOW)
    end.
%%得到相关天道令数量
get_heaven_goods_count(PS, HeavenId)->
    case HeavenId of
        ?TASK_HEAVEN_ID_TIAN ->
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_TIAN) + 
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_TIAN_BIND);
        ?TASK_HEAVEN_ID_DI ->
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_DI) +
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_DI_BIND);
        ?TASK_HEAVEN_ID_XUAN ->
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_XUAN) + 
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_XUAN_BIND);
        ?TASK_HEAVEN_ID_HUANG ->
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_HUANG) +
            goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_HUANG_BIND);
        _-> 0
    end.

use_heaven_goods(PS, HeavenId)->
    case HeavenId of
        ?TASK_HEAVEN_ID_TIAN ->
            case goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_TIAN_BIND) of
                TempNum when TempNum > 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_TIAN_BIND, 1, ?LOG_HEAVEN_TASK);
                TempNum2 when TempNum2 =:= 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_TIAN, 1, ?LOG_HEAVEN_TASK);
                _ ->
                    skip
            end;
        ?TASK_HEAVEN_ID_DI ->
            case goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_DI_BIND) of
                TempNum when TempNum > 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_DI_BIND, 1, ?LOG_HEAVEN_TASK);
                TempNum2 when TempNum2 =:= 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_DI, 1, ?LOG_HEAVEN_TASK);
                _ ->
                    skip
            end;
        ?TASK_HEAVEN_ID_XUAN ->
            case goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_XUAN_BIND) of
                TempNum when TempNum > 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_XUAN_BIND, 1, ?LOG_HEAVEN_TASK);
                TempNum2 when TempNum2 =:= 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_XUAN, 1, ?LOG_HEAVEN_TASK);
                _ ->
                    skip
            end;
        ?TASK_HEAVEN_ID_HUANG ->
            case goods_util:get_bag_goods_num(PS, ?GOODS_ID_HEAVEN_ORDER_HUANG_BIND) of
                TempNum when TempNum > 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_HUANG_BIND, 1, ?LOG_HEAVEN_TASK);
                TempNum2 when TempNum2 =:= 0 ->
                    goods_util:del_bag_goods(PS, ?GOODS_ID_HEAVEN_ORDER_HUANG, 1, ?LOG_HEAVEN_TASK);
                _ ->
                    skip
            end;
        _->
            skip
    end.
%%修改Heavens值
modify_heavens(Heavens, HeavenId, Delta)->
    {TianCount, DiCount, XuanCount, HuangCount} = Heavens,
    case HeavenId of
        ?TASK_HEAVEN_ID_TIAN ->
            {TianCount + Delta, DiCount, XuanCount, HuangCount};
        ?TASK_HEAVEN_ID_DI ->
            {TianCount, DiCount + Delta, XuanCount, HuangCount};
        ?TASK_HEAVEN_ID_XUAN->
            {TianCount, DiCount, XuanCount + Delta, HuangCount};
        _->
            {TianCount, DiCount, XuanCount, HuangCount + Delta}
    end.


%%玩家领取天道令
receive_heaven(PlayerStatus, HeavenId)->
    %%判断天道令数量
    Heaven = lib_task_heaven:get_heaven(HeavenId),
    if Heaven#heaven.heaven_count < 0 orelse Heaven#heaven.heaven_count ==0 ->
            send_oper_result_pack(PlayerStatus, 30703, ?TASK_HEAVEN_NO_HEAVEN_RECEIVE);
        true ->
            TaskHeaven = get_task_heaven_by_uid(PlayerStatus#player.id),
            TempTaskDetail = tpl_task_detail:get(?GOD_COMMAND_TASK),
            {TianCount, DiCount, XuanCount, HuangCount} = TaskHeaven#task_heaven.receive_heavens,
            if (TianCount + DiCount + XuanCount + HuangCount) >= TempTaskDetail#temp_task_detail.cycle_time ->
                    send_oper_result_pack(PlayerStatus, 30703, ?TASK_HEAVEN_TIMES_LIMITED);
                true->
                    %%添加任务
                    TaskIdList = lib_task:get_random_daily_task(task_heaven, {1, PlayerStatus}),
                    case TaskIdList of
                        [] ->
                            skip;
                        [R] ->
                            %%插入task_process
                            {TaskId, TaskGrade} = R,	
                            %lib_task:add_daily_task(TaskId, PlayerStatus, TaskGrade),
                            %cast 任务进程， 更新任务数据
                            gen_server:cast
                            (PlayerStatus#player.other#player_other.pid_task, {'add_daily_task', TaskId, PlayerStatus, TaskGrade}),

                            NewHeaven = Heaven#heaven{heaven_count= Heaven#heaven.heaven_count - 1},
                            ets:insert(?ETS_HEAVEN, NewHeaven),
                            send_30701_pack(PlayerStatus, [pack_heaven_data(PlayerStatus, NewHeaven)]),
                            {ok, BinData} = pt_30:write(30703, [?OPT_SUCCESS]),
                            send_and_pack(PlayerStatus, BinData),
                            NewTaskHeaven = TaskHeaven#task_heaven{receive_count = TaskHeaven#task_heaven.receive_count + 1,
                                receive_heavens = modify_heavens(TaskHeaven#task_heaven.receive_heavens, HeavenId, 1)},
                            ets:insert(?ETS_TASK_HEAVEN, NewTaskHeaven),
                            db_agent_task_heaven:update_task_heaven_receive(PlayerStatus#player.id, 
                                NewTaskHeaven#task_heaven.receive_count, 
                                NewTaskHeaven#task_heaven.receive_heavens)
                    end
            end
    end.

%%玩家发布，领取的天道令数据
get_used_heaven(PlayerStatus)->
    TaskHeaven = get_task_heaven_by_uid(PlayerStatus#player.id), 
    TempTaskDetail = tpl_task_detail:get(?GOD_COMMAND_TASK),
    {ok, BinData} = pt_30:write(30704, [TempTaskDetail#temp_task_detail.cycle_time, TaskHeaven#task_heaven.publish_heavens, 
            TempTaskDetail#temp_task_detail.cycle_time, TaskHeaven#task_heaven.receive_heavens]),
    send_and_pack(PlayerStatus, BinData).

%%元宝完成天道令
complete_heaven_by_coin(PlayerStatus, Id)->
    %%找任务是否存在
    ok.


%%发30701
send_30701_pack(PlayerStatus, HeaveList)->
    ?TASK_TRACE("send_30701_pack ~p~n", [HeaveList]),
    {ok, BinData} = pt_30:write(30701, [HeaveList, length(HeaveList)]),
    ?TASK_TRACE("send_30701_pack_binData ~p~n", [BinData]),
    send_and_pack(PlayerStatus, BinData).

%%发送操作结果包
send_oper_result_pack(PlayerStatus, Cmd, ResultCode)->
    {ok, BinData} = pt_30:write(Cmd, [ResultCode]),
    send_and_pack(PlayerStatus, BinData).

%%发包
send_and_pack(PlayerStatus, BinData)->
    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData).

%%资源销毁
dispose(Uid) ->
    ?TASK_TRACE("lib_task_heaven dispose uid=~p~n", [Uid]),
    ets:delete(?ETS_TASK_HEAVEN, Uid).
