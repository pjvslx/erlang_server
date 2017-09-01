%%%------------------------------------
%%% @Module  : pp_task
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.01.13
%%% @Description: 任务模块
%%%------------------------------------
-module(pp_task).
-compile(export_all).
-include("common.hrl").
-include("record.hrl"). 
-include("task.hrl").
%% 获取任务列表
handle(30000, PlayerStatus, []) ->
    gen_server:cast(PlayerStatus#player.other#player_other.pid_task,{'task_list',PlayerStatus});

%%已接任务列表
handle(30001,PlayerStatus,[])->
    gen_server:cast(PlayerStatus#player.other#player_other.pid_task,{'trigger_task',PlayerStatus});

%%接受任务, 日常任务类型
handle(30002, PlayerStatus,[TaskProcessId])->
    gen_server:cast(PlayerStatus#player.other#player_other.pid_task,{'accept_task_by_task_process_id',PlayerStatus, TaskProcessId});

%% 接受任务
handle(30003, PlayerStatus, [TaskId]) -> 
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'accept_task',PlayerStatus, TaskId});
%%     	erlang:send_after
%% 	(1000, PlayerStatus#player.other#player_other.pid_task, {'test_event',PlayerStatus});
%% 	lib_task:call_event(PlayerStatus,kill,{1,1});
%% 	lib_task:call_event(PlayerStatus,item,{2,5}),
%% 	lib_task:call_event(PlayerStatus,npc,{1}),
%% 	lib_task:call_event(PlayerStatus,shopping,{1,5}),
%% 	lib_task:call_event(PlayerStatus,npc_goods,{1,1,5}),
%% 	lib_task:call_event(PlayerStatus,god_command,{}),
%% 	lib_task:call_event(PlayerStatus,scene,{1,5});

%% 完成任务(还没处理逻辑:1.获取任务奖励，删除任务物品 2.更新角色状态并发送到客户端)  
handle(30004, PlayerStatus, [TaskProcessId])->	  
    case lib_task:finish_task(TaskProcessId, PlayerStatus) of
        {true, NewPlayerStatus} ->	
            {ok, BinData1} = pt_30:write(30004, [?OPT_SUCCESS]),
            lib_send:send_to_sid(NewPlayerStatus#player.other#player_other.pid_send, BinData1), 
            {ok,NewPlayerStatus};
        {false, Reason} -> 
            {ok, BinData1} = pt_30:write(30004, [Reason]),
            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData1),
            ok;
        _ ->
            {ok, BinData2} = pt_30:write(30004, [?UNKNOW_ERROR]),
            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData2),
            ok
    end;
%% 	 gen_server:cast
%% 			(PlayerStatus#player.other#player_other.pid_task, {'finish_task', PlayerStatus, [TaskId]});
%% 检测npc状态
handle(30005, PlayerStatus, [Npclist])->	  
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'check_npc', PlayerStatus, Npclist});

handle(30006, PlayerStatus, [Size])->	  
    gen_server:cast(PlayerStatus#player.other#player_other.pid_task, {'show_all_task', PlayerStatus, Size});

%%消耗元宝完成任务
handle(30007, PlayerStatus, [TaskProcessId])->
    RetVal = gen_server:call(PlayerStatus#player.other#player_other.pid_task,{'auto_finish_task_by_coin',PlayerStatus,TaskProcessId}),
    case RetVal of
        {ok,NewPs}->  
            {ok,Data} = pt_30:write(30007, ?OPT_SUCCESS),

            case lib_task:get_one_daily_task_fin(PlayerStatus#player.id, ?MASTER_TASK) of
                [] -> skip;
                [TaskDaily] ->
                    case tpl_task_detail:get(?MASTER_TASK) of 
                        TempTaskDetail when is_record(TempTaskDetail, temp_task_detail) ->
                            if
                                TaskDaily#task_daily.used_trigger_count >= TempTaskDetail#temp_task_detail.trigger_time ->
                                    lib_task_master:send_30605_pack(PlayerStatus, [0,0]);
                                true ->
                                    lib_task_master:send_30605_pack(PlayerStatus, [TempTaskDetail#temp_task_detail.cycle_time-TaskDaily#task_daily.used_cycle_count,
                                            TempTaskDetail#temp_task_detail.meanw_trigger- TaskDaily#task_daily.trigger_count])
                            end;
                        _->
                            skip
                    end
            end,

            lib_send:send_to_sid(NewPs#player.other#player_other.pid_send, Data),
            {ok,NewPs};
        {false,Reason}->
            {ok,Data} = pt_30:write(30007, Reason),
            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data)
    end;
%%查看npc任务状态
handle(30008, PlayerStatus, [NpcId])->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'npc_info', PlayerStatus, NpcId});
%% %%通知服务器玩家与某任务npc对话
%% handle(30100,PlayerStatus,[NpcId])->
%%      gen_server:cast
%% 			(PlayerStatus#player.other#player_other.pid_task, {'talk_2_npc', PlayerStatus, NpcId});

%%请求师门令任务列表
handle(30601, PlayerStatus, [])->
    %?TRACE("handle 30601 ~n"),
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'task_master_list', PlayerStatus});

%%领取师门令任务
handle(30602, PlayerStatus, [Index, TaskId])->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'receive_task_master', PlayerStatus, Index, TaskId});

%%免费刷新师门令任务列表
handle(30603, PlayerStatus, []) ->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'master_refresh_by_free', PlayerStatus});

%%一键刷新师门令任务列表, 消耗师门令
handle(30604, PlayerStatus, []) ->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'master_refresh_by_order', PlayerStatus});

%%元宝刷新师门令任务列表
handle(30606, PlayerStatus, []) ->
    case lib_task_master:refresh_by_gold(PlayerStatus) of
        {ok,NewPs}->
            {ok,NewPs};
        _ ->
            skip
    end;

%%获取天道令数据
handle(30701, PlayerStatus, []) ->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'get_heaven_list', PlayerStatus});

%%玩家发布天道令
handle(30702, PlayerStatus, [HeavenId]) ->
    gen_server:cast
    (mod_heaven:get_heaven_pid(HeavenId), {'publish_heaven', PlayerStatus, HeavenId});

%%玩家领取天道令
handle(30703, PlayerStatus, [HeavenId]) ->
    gen_server:cast
    (mod_heaven:get_heaven_pid(HeavenId), {'receive_heaven', PlayerStatus, HeavenId});

%%玩家领取天道令
handle(30704, PlayerStatus, []) ->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'get_used_heaven', PlayerStatus});

%%玩家元宝完成天道令
handle(30705, PlayerStatus, [Id]) ->
    gen_server:cast
    (PlayerStatus#player.other#player_other.pid_task, {'complete_heaven_by_coin', PlayerStatus, Id});

handle(30801,PlayerStatus,[]) ->
    F = fun(T,Result) ->
            case lib_task:get_one_daily_task_fin(PlayerStatus#player.id,T) of
                [TaskDaily] when is_record(TaskDaily, task_daily) ->
                    Result ++ [{T,TaskDaily#?ETS_TASK_DAILY.trigger_count,TaskDaily#?ETS_TASK_DAILY.used_trigger_count}];
                _ ->
                    Result	
            end
    end,
    TaskData = lists:foldl(F,[],?ALL_TASK_TYPE),
    {ok, BinData} = pt_30:write(30801, [TaskData]),
    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData),
    ok;

handle(_Cmd, _PlayerStatus, _Data) ->
    {error, bad_request}. 

