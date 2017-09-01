-module(mod_mon_fsm).
-behaviour(gen_fsm).
-export([start_link/2]).
%% gen_fsm 回调函数 
-export([init/1,handle_event/3,handle_sync_event/4,handle_info/3, terminate/3, code_change/4]).
%% 状态回调函数
-export([mon_state_guard/2,player_join/0]).

-include("common.hrl").
-include("record.hrl").

-record(monBaseInfo,{
        id,%%怪物的标识
        mon_state,%%怪物当前的状态
        mon_ai_id,%%怪物当期的AI id
        enermy,%%玩家当前敌人
        enermy_time, %%敌人出现时间
        keep_clock,%%保持定时器
        clock_time,%%心跳间隔
        refresh_time,%%等待时间
        scene_id %%场景id
    }).

%%需要设置ServerName，这样才可以创建多个怪物
%%[通过{local, ServerName}来区分不同怪物]
start_link(ServerName,MonId) ->
    gen_fsm:start_link({local, ServerName}, ?MODULE, [ServerName,MonId], []).

%% 初始化怪物AI为巡逻状态
init([ServerName,MonId]) ->
    State = #monBaseInfo{id=MonId,enermy=0,keep_clock = 1,enermy_time = 0,clock_time = ?MON_STATE_SPEED_7,refresh_time = 0,scene_id = 0},
    {ok, mon_state_guard, State}.

%%@spec 怪物进入战斗状态
handle_info({'player_coming',MonRcd,Pid,PlayerStatus},StateName,State) ->
    PlayerId = PlayerStatus#player.id,
    if %% 远程AOE攻击距离 目前最大为 8 
        abs(MonRcd#temp_mon_layout.pos_x - PlayerStatus#player.battle_attr#battle_attr.x) =< 8 andalso
        abs(MonRcd#temp_mon_layout.pos_y - PlayerStatus#player.battle_attr#battle_attr.y) =< 8 ->
            SureComming = true;
        true ->
            SureComming = false
    end,

    case lib_scene:is_dungeon_scene(MonRcd#temp_mon_layout.scene_id) of
        true ->
            if
                State#monBaseInfo.enermy =/= 0 andalso PlayerId =/= State#monBaseInfo.enermy ->
                    ?ERROR_MSG("[ERROR_MSG:mod_mon_fsm player_coming] Not the Same player!enermy:~p,PlayerId:~p~n",[State#monBaseInfo.enermy,PlayerId]);
                true ->
                    skip
            end;
        false ->
            skip
    end,
    NowTime = util:longunixtime(),
    if
        NowTime > State#monBaseInfo.enermy_time + 500 andalso State#monBaseInfo.enermy =/= PlayerId andalso SureComming =:= true ->%%防止短时间重复接收
            NewState = State#monBaseInfo{enermy = PlayerId,enermy_time = NowTime},
            gen_server:cast(Pid,{apply_cast,lib_mon_ai,change_to_fight_ai,[MonRcd#temp_mon_layout.id]});%%进入战斗AI状态
        true ->
            NewState = State
    end,

    {next_state, StateName, NewState};

%%@spec 怪物脱离战斗状态(包括逃跑，巡逻)
handle_info({'player_leaving',PlayerId},StateName,State) ->
    if
        PlayerId > 0 ->%%如果指定某个玩家离开
            if
                State#monBaseInfo.enermy =:= PlayerId ->
                    NewState = State#monBaseInfo{enermy = 0};
                true ->
                    NewState = State
            end;
        true ->
            NewState = State#monBaseInfo{enermy = 0}
    end,
    {next_state, StateName, NewState};

%%@spec 场景创建
handle_info({'scene_create'},StateName,State) ->
    NewState = State#monBaseInfo{keep_clock = 1},
    {next_state, StateName, NewState};

%%@spec 场景销毁
handle_info({'scene_erase'},StateName,State) ->
    NewState = State#monBaseInfo{keep_clock = 0},
    {next_state, StateName, NewState};

handle_info({'change_mon_data',NewMonState,NewClockTime,NewMonAIID,NewRefreshTime,ScendId},StateName,State) ->
    NewState = State#monBaseInfo{
        mon_state = NewMonState,
        clock_time = NewClockTime,
        mon_ai_id = NewMonAIID,
        refresh_time = NewRefreshTime,
        scene_id = ScendId 
    },
    {next_state, StateName, NewState};

%%更改怪物的AI
handle_info({'change_mon_ai',NewMonAIID},StateName,State) ->
    NewState = State#monBaseInfo{
        mon_ai_id = NewMonAIID
    },
    {next_state, StateName, NewState};

%%有玩家出现，怪物开始进入AI判定
handle_info({'player_showing_up',Pid,NowTime},StateName,State) ->
    misc:cancel_timer(?MON_STATE_TIMER_KEY) ,

    if
        State#monBaseInfo.mon_state =/= ?MON_STATE_6_DEAD ->
            case misc:is_process_alive(Pid) of
                true ->
                    NowTime2 = util:longunixtime(),

                    PlayerId = State#monBaseInfo.enermy,
                    if
                        PlayerId > 0 ->%%进入战斗AI状态
                          %  PlayerPidTemp = lib_player:get_player_pid(PlayerId),
                          PlayerStatus = gen_server:call(Pid,{apply_call,lib_scene,get_scene_player,[State#monBaseInfo.scene_id,PlayerId]});
                          %  PlayerStatus = gen_server:call(PlayerPidTemp,'PLAYER');
                        true ->  
                            PlayerStatus = null
                    end,

                    %%触发AI
                    if
                        State#monBaseInfo.mon_ai_id > 0->
                            gen_server:cast(Pid,{apply_cast,lib_mon_ai,handle_mon_ai,
                                    [State#monBaseInfo.mon_ai_id, State#monBaseInfo.id, PlayerStatus]});
                        true ->
                            skip
                    end,

                    if
                        State#monBaseInfo.enermy > 0 -> %% 作战状态
                            if
                                is_record(PlayerStatus,player) ->
                                    do_refresh_monster(Pid,PlayerStatus,NowTime,State);
                                true ->
                                    skip
                            end;
                        true ->                     %% 非作战状态
                            skip
                    end,


                    if
                        State#monBaseInfo.keep_clock =:= 1 -> %%如果keep_clock = 1，则维护定时器
                            %{M_RealTime, S_RealTime, Ms_RealTime} = erlang:now(),
                            %RealTime = (M_RealTime * 1000000000000 + S_RealTime * 1000000 + Ms_RealTime) div 1000,

                            %%加入10毫秒的代码执行时间
                            NextTimer = erlang:send_after(State#monBaseInfo.clock_time,self(),{'player_showing_up',Pid,NowTime2}),

                            put(?MON_STATE_TIMER_KEY,NextTimer);
                        true ->
                            skip
                    end;
                false ->
                    skip
            end;
        true ->
            skip
    end,
    {next_state, StateName, State};

handle_info({'stop'}, _StateName, State) ->
    {stop, normal, State};

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

%%@spec 具体状态逻辑
do_refresh_monster(Pid,PlayerStatus,NowTime,State) ->
    if
        State#monBaseInfo.refresh_time =< NowTime ->
            case State#monBaseInfo.mon_state of
                ?MON_STATE_1_GUARD ->
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_guard,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_2_TRYATT ->   
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_try_attack,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_7_CHANT ->
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_chant,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_3_MOVE ->
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_move,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_4_FIGHT ->
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_fight,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_5_RETURN ->
                    gen_server:cast(Pid,{apply_cast,lib_mon_state,do_return,[PlayerStatus,State#monBaseInfo.id,NowTime]});
                ?MON_STATE_6_DEAD ->     
                    skip;
                _ ->
                    skip
            end;
        true ->
            skip
    end.



%% ----------------------------------------------------其他接口，暂时不用-----------------------------------------
%% [fsm接口实例]玩家进入视野
player_join() ->
    %%send_event的第一个参数gen_fsm进程，第二个参数是即将发生的事件
    %%send_event之后，会调用当前事件状态StateName同名的函数
    %%且该同名函数的第一个参数Event就是send_event的第二个参数值
    gen_fsm:send_event(?MODULE, {player_join,0}).

%%在前端调用send_all_state_event/2的时候，在这里处理
%%send_all_state_event的第一个参数是gen_fsm的进程，
%%第二个参数值是传入到handle_event的第一个参数值
handle_event(stop, _StateName, State) ->
    %io:format("Ok,terminate!~n"),
    {stop, normal, State};

handle_event(_Event, StateName, State) ->
    {next_state,StateName,State}.


%%在前端调用sync_send_all_state_event/2的时候，在这里事件
%%函数sync_send_all_state_event的第一个参数是gen_fsm的进程，
%%第二个参数值是传入到handle_event的第一个参数
handle_sync_event(_Event, _From, StateName, State) ->
    Reply = ok,
    {reply, Reply, StateName, State}.


terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

%-------------------状态回调函数定义---------------------------
%% 巡逻状态下，接受来自客户端的事件
mon_state_guard(_Event, State) ->
    {next_state, mon_state_guard, State}.

