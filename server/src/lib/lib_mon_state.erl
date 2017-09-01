%%%-----------------------------------
%%% @Module  : lib_mon_state
%%% @Author  : chenzm
%%% @Created : 2013.1.22
%%% @Description:  场景中怪物状态切换管理
%%%-----------------------------------
-module(lib_mon_state).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("battle.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-export([do_guard/3,  
        do_try_attack/3,
        do_chant/3,
        do_move/3,
        do_revive/3,
        do_fight/3,  
        do_return/3,
        get_attack_skill/1,
        broad_monster_move/5,
        move_action/2,
        change_to_return/3
    ]).

-define(MON_DEFAULT_SKILL,5) .
-define(MON_DEFAULT_SKILL_LV,1) .

%%@spec 警戒具体业务逻辑===begin
%% 1. 普通小怪无仇恨，谁第一个打它它就将谁设置成攻击目标
%% 2. BOSS怪物则需要根据攻击警戒范围来确定攻击目标
%% 3. 确定攻击目标后，试图发起攻击
do_guard(PlayerStatus,MonRcdId,_NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),

    if
        is_record(MonRcd,temp_mon_layout) andalso MonRcd#temp_mon_layout.monrcd#temp_npc.npc_type >= 20 ->
            HateList = lib_mon:update_hate([PlayerStatus],MonRcd#temp_mon_layout.hate_list),
            if
                is_record(PlayerStatus,player) andalso PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->   
                    lib_battle:merge_battle_player(PlayerStatus#player.id), 
                    NewPs = lib_battle:change_2_battle_state(PlayerStatus),
                    if NewPs#player.status =/= PlayerStatus#player.status ->
                            gen_server:cast(NewPs#player.other#player_other.pid,{change_battle_status,?PLAYER_BATTLE_STATE,NewPs#player.battle_attr#battle_attr.energy});
                        true->
                            skip
                    end,

                    %%修正移动速度为正常速度
                    {ok,Data} = pt_22:write(22006,[?ELEMENT_MONSTER,MonRcd#temp_mon_layout.id,?BUFF_EFFECT_MOVE_SPEED,?COMMON_MOVE_SPEED]),
                    case lib_scene:is_dungeon_scene(MonRcd#temp_mon_layout.scene_id) of
                        true ->
                            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data) ;
                        false ->
                            mod_scene_agent:send_to_matrix(MonRcd#temp_mon_layout.scene_id,MonRcd#temp_mon_layout.pos_x, MonRcd#temp_mon_layout.pos_y, Data)
                    end,

                    NewBattleAttr = MonRcd#temp_mon_layout.battle_attr#battle_attr{speed = 7,clock_time = ?MON_STATE_SPEED_7},
                    NewMonRcd = MonRcd#temp_mon_layout{target_uid = PlayerStatus#player.id ,
                        state = ?MON_STATE_2_TRYATT ,
                        hate_list = HateList,
                        start_fight_time = util:unixtime(),
                        battle_attr = NewBattleAttr},
                    lib_mon:save_monster(NewMonRcd);
                true ->  						
                    MonRcd#temp_mon_layout.pid ! {'player_leaving',0}
            end;
        true ->   		%% 被动怪物自己先不动
            skip
    end .



%%@spec 试图攻击业务逻辑=== 
%% 1. 如果在技能的攻击范围内，则发起攻击
%% 2. 不在攻击范围内，则走过去
do_try_attack(PlayerStatus,MonRcdId,NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    SceneId = PlayerStatus#player.scene,
    %% 获取怪物的攻击技能
    if
        is_record(MonRcd,temp_mon_layout) ->
            if
                is_record(PlayerStatus,player) andalso PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->
                    BuffList = MonRcd#temp_mon_layout.battle_attr#battle_attr.skill_buff ,
                    BuffCheck = buff_util:check_unskill_buff(BuffList) ,

                    {SkillId,SkillLv} 	= get_attack_skill(MonRcd#temp_mon_layout.monrcd#temp_npc.act_skilllist) ,
                    AttackRange 		= data_skill:get_skill_distance(SkillId) ,
                    {CanBreak,SingTime} = data_skill:get_sing(SkillId) , 
                    SkillUsable = lib_skill:check_skill_usable(MonRcd#temp_mon_layout.battle_attr,SkillId,SkillLv) ,
                    if
                        BuffCheck =:= true orelse SkillUsable =:= false ->%%orelse MonRcd#temp_mon_layout.target_uid =< 0	
                            NewMonRcd = MonRcd#temp_mon_layout{ state = ?MON_STATE_1_GUARD, refresh_time = NowTime + ?MON_STATE_SPEED_7 },
                            lib_mon:save_monster(NewMonRcd);
                        SingTime > 0 ->
                            spawn(fun() -> broad_monster_chant(SceneId,MonRcd,SkillId,CanBreak,SingTime) end ) ,
                            NewMonRcd = MonRcd#temp_mon_layout{attack_skill = SkillId ,skill_lv = SkillLv , sing_expire = util:longunixtime() +  SingTime,state = ?MON_STATE_7_CHANT, refresh_time = NowTime + SingTime },
                            lib_mon:save_monster(NewMonRcd);
                        true ->
                            case util:is_in_range(PlayerStatus#player.battle_attr#battle_attr.x,
                                    PlayerStatus#player.battle_attr#battle_attr.y, 
                                    MonRcd#temp_mon_layout.pos_x, MonRcd#temp_mon_layout.pos_y, 
                                    AttackRange) of
                                true ->		
                                    NewMonRcd = MonRcd#temp_mon_layout{attack_skill = SkillId , skill_lv = SkillLv ,
                                        state = ?MON_STATE_4_FIGHT},
                                    lib_mon:save_monster(NewMonRcd),
                                    lib_mon_state:do_fight(PlayerStatus,NewMonRcd#temp_mon_layout.id,NowTime);
                                false ->  
                                    case buff_util:check_unmove_buff( MonRcd#temp_mon_layout.battle_attr) of
                                        true ->		%% 擦，被封脚了，不能走路
                                            NewMonRcd = MonRcd#temp_mon_layout{state = ?MON_STATE_1_GUARD, refresh_time = NowTime + ?MON_STATE_SPEED_7 },
                                            lib_mon:save_monster(NewMonRcd);
                                        false ->
                                            ?TRACE("[change_to_move] ~p ~p ~n",[MonRcd#temp_mon_layout.battle_attr#battle_attr.x,MonRcd#temp_mon_layout.battle_attr#battle_attr.y]),
                                            change_to_move(PlayerStatus,MonRcd,NowTime,AttackRange) 
                                    end 
                            end 
                    end ;
                true ->
                    NewMonRcd = MonRcd#temp_mon_layout{target_uid = 0 , state = ?MON_STATE_1_GUARD, refresh_time = NowTime + ?MON_STATE_SPEED_7 },
                    lib_mon:save_monster(NewMonRcd)
            end;
        true ->
            skip
    end.



broad_monster_chant(SceneId,MonRcd,SkillId,CanBreak,SingTime) ->
    {ok,ChantBin} = pt_12:write(12014,[MonRcd#temp_mon_layout.id,SkillId,CanBreak,SingTime]) ,
    X = MonRcd#temp_mon_layout.pos_x ,
    Y = MonRcd#temp_mon_layout.pos_y ,
    mod_scene_agent:send_to_same_screen(SceneId, X, Y, ChantBin,"") .


%%@spec 怪物吟唱具体业务逻辑(有吟唱的不追击)=== 
do_chant(PlayerStatus,MonRcdId,NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    NowLongTime = util:longunixtime() ,
    if
        is_record(MonRcd,temp_mon_layout) ->
            case NowLongTime > MonRcd#temp_mon_layout.sing_expire of
                true ->
                    NewMonRcd = MonRcd#temp_mon_layout{state = ?MON_STATE_4_FIGHT},
                    lib_mon:save_monster(NewMonRcd),
                    lib_mon_state:do_fight(PlayerStatus,NewMonRcd#temp_mon_layout.id,NowTime);
                false ->
                    skip
            end;
        true ->
            skip
    end.


%%@spec 走动具体业务逻辑=== 
do_move(PlayerStatus,MonRcdId,NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    SceneId = PlayerStatus#player.scene,
    if
        is_record(MonRcd,temp_mon_layout) ->
            if
                is_record(PlayerStatus,player) andalso 
                PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->
                    AttackRange 		= data_skill:get_skill_distance(MonRcd#temp_mon_layout.attack_skill) ,
                    MovePath = MonRcd#temp_mon_layout.move_path , 

                    if
                        length(MovePath) > 0 ->
                            NewMonRcd = move_action(MonRcd,MovePath),
                            lib_mon:save_monster(NewMonRcd);
                        true ->
                            case util:is_in_range(PlayerStatus#player.battle_attr#battle_attr.x, 
                                    PlayerStatus#player.battle_attr#battle_attr.y, 
                                    MonRcd#temp_mon_layout.pos_x, MonRcd#temp_mon_layout.pos_y, 
                                    AttackRange) of
                                true ->		%% 在攻击范围之内，发起战斗
                                    NewMonRcd = MonRcd#temp_mon_layout{state = ?MON_STATE_4_FIGHT,
                                        battle_attr = MonRcd#temp_mon_layout.battle_attr#battle_attr{move_destination = {0,0}}
                                    },
                                    lib_mon:save_monster(NewMonRcd),
                                    lib_mon_state:do_fight(PlayerStatus,NewMonRcd#temp_mon_layout.id,NowTime);
                                false ->    %% 超过了攻击范围
                                    return_or_move(PlayerStatus,MonRcd,NowTime,AttackRange) 
                            end
                    end ;
                true ->	%%	没有攻击目标，返回
                    change_to_return(PlayerStatus,MonRcd,NowTime)
            end;
        true ->
            skip
    end.




%%@spec 战斗具体业务逻辑=== 
%% -define(ATTACK_SUCCESS,   1).   % 攻击成功
%% -define(ATTACK_NO_TARGET, 2).   % 攻击范围内没有攻击目标
%% -define(NOT_ATTACK_AREA,  3).   % 超出攻击范围
do_fight(PlayerStatus,MonRcdId,NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    if
        is_record(MonRcd,temp_mon_layout) ->
            %%BattleAttr = lib_skill:update_mon_battle_attr(MonRcd#temp_mon_layout.battle_attr, MonRcd#temp_mon_layout.attack_skill, MonRcd#temp_mon_layout.skill_lv) ,
            %% 	NewMonRcd = MonRcd#temp_mon_layout{battle_attr = BattleAttr} , 
		      {SkillId,SkillLv,NewMonRcd} = refresh_monster_record(MonRcd) ,  
            AttackRange 	= data_skill:get_skill_distance(SkillId) ,
            case util:is_in_range(PlayerStatus#player.battle_attr#battle_attr.x,
                    PlayerStatus#player.battle_attr#battle_attr.y, 
                    NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y,AttackRange) of
                true ->  
                    if
                        NowTime >= NewMonRcd#temp_mon_layout.refresh_time ->
                            if
                                PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->
                                    case lib_battle:do_monster_begin_attack(NewMonRcd, PlayerStatus, SkillId, SkillLv) of
                                        {?ATTACK_SUCCESS, DataList} ->      	%% 有攻击目标,要清楚仇恨值

                                            if
                                                NewMonRcd#temp_mon_layout.scene_id =/= PlayerStatus#player.scene ->
                                                    ?ERROR_MSG("[ERROR] Mon  And Player Not In the Same Scene:~p,~p~n!!!",
                                                        [NewMonRcd#temp_mon_layout.scene_id,PlayerStatus#player.scene]);
                                                true ->
                                                    skip
                                            end,
                                            NewFinalMonRcd = NewMonRcd#temp_mon_layout{
                                                round_times = NewMonRcd#temp_mon_layout.round_times + 1,
                                                refresh_time = NowTime + NewMonRcd#temp_mon_layout.battle_attr#battle_attr.attack_speed
                                            },
                                            lib_mon:save_monster(NewFinalMonRcd);
                                        _ ->          							%% 不在攻击范围，是继续追击还是返回
                                            NewMonRcd2 = battle_util:get_status(NewMonRcd#temp_mon_layout.id, ?ELEMENT_MONSTER),
                                            return_or_move(PlayerStatus,NewMonRcd2,NowTime,AttackRange)
                                    end;
                                true ->
                                    change_to_return(PlayerStatus,NewMonRcd,NowTime)
                                    %{PlayerStatus,NewMonRcd}
                            end;
                        true ->
                            skip
                    end;
                false ->
                    return_or_move(PlayerStatus,NewMonRcd,NowTime,AttackRange)
            end;
        true ->
            skip
    end.

%% 获取具体的攻击技能
refresh_monster_record(MonRcd) ->
    {SkillId,SkillLv} = 
    case MonRcd#temp_mon_layout.ai_skill_id > 0 of
        true ->
            {MonRcd#temp_mon_layout.ai_skill_id, MonRcd#temp_mon_layout.ai_skill_lv} ;
        false ->
            {MonRcd#temp_mon_layout.attack_skill, MonRcd#temp_mon_layout.skill_lv}
    end ,
    BattleAttr = lib_skill:update_mon_battle_attr(MonRcd#temp_mon_layout.battle_attr, SkillId, SkillLv) ,
    NewMonRcd = MonRcd#temp_mon_layout{battle_attr = BattleAttr, ai_skill_id = 0, ai_skill_lv = 0 } ,
    {SkillId,SkillLv,NewMonRcd} .

  
%%@spec 返回具体业务逻辑=== 
do_return(PlayerStatus,MonRcdId,NowTime) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    if
        is_record(MonRcd,temp_mon_layout) ->
            case length(MonRcd#temp_mon_layout.move_path) > 0 of
                true ->	
                    NewMonRcd = move_action(MonRcd,MonRcd#temp_mon_layout.move_path),
                    BattleAttr = MonRcd#temp_mon_layout.battle_attr,
                    ReturnStepNum = BattleAttr#battle_attr.return_steps,
                    if
                        ReturnStepNum > 5 andalso length(MonRcd#temp_mon_layout.move_path) > 5 ->
                            {ok,Teleport} = pt_12:write(12042, [NewMonRcd#temp_mon_layout.id,NewMonRcd#temp_mon_layout.x,NewMonRcd#temp_mon_layout.y]) ,
                            case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
                                true ->
                                    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Teleport) ;
                                false ->
                                    mod_scene_agent:send_to_matrix(
                                        PlayerStatus#player.scene,
                                        NewMonRcd#temp_mon_layout.pos_x,
                                        NewMonRcd#temp_mon_layout.pos_y,
                                        Teleport
                                    )
                            end,

                            lib_mon:update_monster_warn_area(
                                NewMonRcd#temp_mon_layout.id,
                                BattleAttr#battle_attr.x,
                                BattleAttr#battle_attr.y,
                                NewMonRcd#temp_mon_layout.x,
                                NewMonRcd#temp_mon_layout.y,
                                NewMonRcd#temp_mon_layout.monrcd#temp_npc.warn_range
                            ),
                            NewMonRcd#temp_mon_layout.pid ! {'player_leaving',0},
                            NewMonRcd2 = NewMonRcd#temp_mon_layout{
                                move_path = 0,
                                pos_x =  NewMonRcd#temp_mon_layout.x,
                                pos_y =  NewMonRcd#temp_mon_layout.y,
                                state = ?MON_STATE_1_GUARD
                            };
                        true ->
                            NewMonRcd2 = NewMonRcd#temp_mon_layout{battle_attr = BattleAttr#battle_attr{return_steps = ReturnStepNum + 1}}
                    end,
                    lib_mon:save_monster(NewMonRcd2);
                _-> 	
                    BattleAttr = MonRcd#temp_mon_layout.battle_attr ,
                    NewBattleAttr = BattleAttr#battle_attr{
                        x = MonRcd#temp_mon_layout.x,
                        y = MonRcd#temp_mon_layout.y,
                        return_steps = 0
                    } ,
                    NewMonRcd = MonRcd#temp_mon_layout{battle_attr = NewBattleAttr,
                        pos_x = MonRcd#temp_mon_layout.x ,
                        pos_y = MonRcd#temp_mon_layout.y ,
                        move_path = [] ,
                        state = ?MON_STATE_1_GUARD ,
                        refresh_time = NowTime + ?MON_STATE_SPEED_7 ,
                        round_times = 0 ,   
                        start_fight_time = 0},
                    lib_mon:save_monster(NewMonRcd),
                    NewMonRcd2 = lib_mon_ai:back_init_ai(MonRcd#temp_mon_layout.id),%%还原怪物的战斗初始AI
                    MonRcd#temp_mon_layout.pid ! {'player_leaving',0}
            end;
        true ->
            skip
    end.


%%@spec 复活具体业务逻辑===begin
do_revive(PlayerStatus,MonRcd,NowTime) ->
    SceneId = PlayerStatus#player.scene,
    %%?TRACE("===do_revive: ~p ~n", [Mon#temp_mon_layout.move_path]),
    BattleAttrRcd = MonRcd#temp_mon_layout.battle_attr ,
    NewBattleAttrRcd = BattleAttrRcd#battle_attr{x = MonRcd#temp_mon_layout.x , 
        y = MonRcd#temp_mon_layout.y ,
        hit_point = BattleAttrRcd#battle_attr.hit_point_max,
        magic = BattleAttrRcd#battle_attr.magic_max} ,
    NewMonRcd = MonRcd#temp_mon_layout{target_uid = 0 ,
        state = ?MON_STATE_1_GUARD ,
        refresh_time = NowTime + ?MON_STATE_SPEED_7 ,
        pos_x = MonRcd#temp_mon_layout.x ,
        pos_y = MonRcd#temp_mon_layout.y ,
        battle_attr = NewBattleAttrRcd ,
        round_times = 0 ,	
        ai_skill_id = 0 ,	
        start_fight_time = 0 ,
        ai_handle_list = [] ,
        hate_seq = 10000 } ,
    {ok,MonBin} = pt_12:write(12007, [NewMonRcd]) ,

    lib_mon:save_monster(NewMonRcd),
    NewMonRcd2 = lib_mon_ai:back_init_ai(NewMonRcd#temp_mon_layout.id),
    mod_scene_agent:send_to_matrix(SceneId, NewMonRcd2#temp_mon_layout.x, NewMonRcd2#temp_mon_layout.y, MonBin) ,
    lib_mon:update_monster_warn_area(NewMonRcd2#temp_mon_layout.id,0,0,
        NewMonRcd2#temp_mon_layout.x,
        NewMonRcd2#temp_mon_layout.y,
        NewMonRcd2#temp_mon_layout.monrcd#temp_npc.warn_range),
    NewMonRcd2#temp_mon_layout.pid ! {'scene_create'},
    NewMonRcd2#temp_mon_layout.pid ! {'player_showing_up',self(),util:longunixtime()},
    %%如果怪物为主动怪，而且玩家在怪物攻击范围以内，怪物复活之后会主动攻击玩家
    if
        NewMonRcd2#temp_mon_layout.monrcd#temp_npc.warn_range > 0 ->
            NewPlayerStatus = lib_player:get_player(PlayerStatus#player.id),
            {SkillId,SkillLv} 	= get_attack_skill(NewMonRcd2#temp_mon_layout.monrcd#temp_npc.act_skilllist) ,
            AttackRange 		= data_skill:get_skill_distance(SkillId) ,
            case util:is_in_range(NewPlayerStatus#player.battle_attr#battle_attr.x,
                    NewPlayerStatus#player.battle_attr#battle_attr.y, 
                    NewMonRcd2#temp_mon_layout.pos_x, NewMonRcd2#temp_mon_layout.pos_y, 
                    AttackRange) of
                true ->
                    NewMonRcd2#temp_mon_layout.pid ! {'player_coming',NewMonRcd2,PlayerStatus#player.other#player_other.pid_scene,PlayerStatus};
                false ->
                    skip
            end;
        true ->
            skip
    end.


%% 战斗没有命中目标,判断是继续追击还是返回原点
return_or_move(PlayerStatus,MonRcd,NowTime,AttackRange) ->	
    case util:is_in_range(PlayerStatus#player.battle_attr#battle_attr.x, PlayerStatus#player.battle_attr#battle_attr.y, 
            MonRcd#temp_mon_layout.pos_x, MonRcd#temp_mon_layout.pos_y, 
            MonRcd#temp_mon_layout.monrcd#temp_npc.fire_range) of
        true ->
            change_to_move(PlayerStatus,MonRcd,NowTime,AttackRange) ;
        false ->
            change_to_return(PlayerStatus,MonRcd,NowTime)
    end .

%% 追击玩家
change_to_move(PlayerStatus,MonRcd,NowTime,AttackRange) ->
    %FirePosList = [{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}],
    %{FirePosX,FirePosY} = getNearestFirePos(PlayerStatus,MonRcd,FirePosList,1000000,{0,0}),
    if
        is_record(MonRcd,temp_mon_layout) ->
            X1 = PlayerStatus#player.battle_attr#battle_attr.x,
            Y1 = PlayerStatus#player.battle_attr#battle_attr.y,
            X2 = MonRcd#temp_mon_layout.pos_x,
            Y2 = MonRcd#temp_mon_layout.pos_y,
            if
                AttackRange < 0 ->
                    if
                        X1 =/= X2 ->
                            FirePosX = trunc(abs(X1-X2)/(X1-X2));
                        true ->
                            FirePosX = 0
                    end,
                    if
                        Y1 =/= Y2 ->
                            FirePosY = trunc(util:rand(-1,1)*abs(Y1-Y2)/(Y1-Y2));
                        true ->
                            FirePosY = 0
                    end,

                    if 
                        FirePosX =:= 0 andalso FirePosY =:= 0 ->
                            NewFirePosX = 1,
                            NewFirePosY = util:rand(-1,1);
                        true ->
                            NewFirePosX = FirePosX,
                            NewFirePosY = FirePosY
                    end;
                true ->
                    %% XTemp1和XTemp2是通过方程式运算得出的
                    XTemp1 = AttackRange*(X2-X1)/math:sqrt( (Y2-Y1)*(Y2-Y1)+(X2-X1)*(X2-X1) ) + X1,
                    YTemp1 = AttackRange*(Y2-Y1)/math:sqrt( (Y2-Y1)*(Y2-Y1)+(X2-X1)*(X2-X1) ) + Y1,
                    if
                        XTemp1 > X1 ->
                            XTemp = trunc(XTemp1);
                        true ->
                            XTemp = trunc(XTemp1) + 1
                    end,
                    if
                        YTemp1 > Y1 ->
                            YTemp = trunc(YTemp1);
                        true ->
                            YTemp = trunc(YTemp1) + 1
                    end,
                    NewFirePosX = X1 - XTemp,
                    NewFirePosY = Y1 - YTemp
            end,

            OffSetX = abs(X2 - (X1 - NewFirePosX)),
            OffSetY = abs(Y2 - (Y1 - NewFirePosY)),
            OffSet = max(OffSetX,OffSetY),

            FireRange = MonRcd#temp_mon_layout.monrcd#temp_npc.fire_range ,

            if
                FireRange =< OffSet ->
                    CanMoveStep = FireRange;
                true ->
                    CanMoveStep = OffSet
            end,

            SrcPost = {MonRcd#temp_mon_layout.pos_x , MonRcd#temp_mon_layout.pos_y} ,

            MonBattleAttr = MonRcd#temp_mon_layout.battle_attr#battle_attr{fight_pos = {NewFirePosX,NewFirePosY}},
            DescPost = {PlayerStatus#player.battle_attr#battle_attr.x -NewFirePosX, PlayerStatus#player.battle_attr#battle_attr.y - NewFirePosY} ,


            MovePath = lib_mon:get_move_path(SrcPost, DescPost, CanMoveStep) ,

            case length(MovePath) > 0 of %% andalso MonRcd#temp_mon_layout.battle_attr#battle_attr.status_stop =< 0 
                true ->
					if MonRcd#temp_mon_layout.battle_attr#battle_attr.status_stop =< 0 ->
                    spawn(fun() -> broad_monster_move(PlayerStatus, MonRcd#temp_mon_layout.id, MonRcd#temp_mon_layout.x, MonRcd#temp_mon_layout.y, MovePath) end) ,
                    NewMonRcd = MonRcd#temp_mon_layout{state = ?MON_STATE_3_MOVE,move_path = MovePath,
                        battle_attr = MonBattleAttr#battle_attr{move_destination = DescPost,clock_time = ?MON_STATE_SPEED_7}
                    },
                    lib_mon:save_monster(NewMonRcd);
					true ->
						        change_to_return(PlayerStatus,MonRcd,NowTime)
					end;
                false ->
                    change_to_return(PlayerStatus,MonRcd,NowTime)
            end;
        true ->
            skip
    end.


%%@spec 好吧，没事干了，回去
change_to_return(PlayerStatus,MonRcd,NowTime) when is_record(PlayerStatus,player)->
    if
        is_record(MonRcd,temp_mon_layout) ->
            SrcPost = {MonRcd#temp_mon_layout.pos_x, MonRcd#temp_mon_layout.pos_y} ,
            DestPost =  lib_scene:check_stoptable_pos(MonRcd#temp_mon_layout.x, MonRcd#temp_mon_layout.y,MonRcd#temp_mon_layout.battle_attr),
            ReturnPath = lib_mon:get_move_path(SrcPost, DestPost, 10000) ,
            case length(ReturnPath) > 0 of
                true ->
                    spawn(fun() -> broad_monster_move(PlayerStatus, MonRcd#temp_mon_layout.id, MonRcd#temp_mon_layout.x, MonRcd#temp_mon_layout.y,ReturnPath) end ) ;
                false ->
                    skip
            end ,
            NewMonRcd = MonRcd#temp_mon_layout{target_uid = 0 , hate_list = [], move_path = ReturnPath,
                state = ?MON_STATE_5_RETURN , refresh_time = NowTime + ?MON_STATE_SPEED_7,
                battle_attr = MonRcd#temp_mon_layout.battle_attr#battle_attr{move_destination = {0,0},clock_time = ?MON_STATE_SPEED_7}
            },

            lib_mon:save_monster(NewMonRcd);
        true ->
            skip
    end.

%%@spec 广播怪物走路
broad_monster_move(PlayerStatus,MonId,X,Y,Path) when is_record(PlayerStatus,player)  ->
    case length(Path) > 0 of
        true ->
            {ok,MoveBin} = pt_12:write(12012, [MonId,Path]) ,
            case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
                true ->
                    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, MoveBin) ;
                false ->
                    mod_scene_agent:send_to_matrix(PlayerStatus#player.scene, X, Y, MoveBin) 
            end ;
        false ->
            skip
    end ;
broad_monster_move(SceneId,MonId,X,Y,Path) when is_integer(SceneId)  ->
    case length(Path) > 0 of
        true ->
            {ok,MoveBin} = pt_12:write(12012, [MonId,Path]) ,
            mod_scene_agent:send_to_matrix(SceneId, X, Y, MoveBin)  ;
        false ->
            skip
    end .

%% 获取攻击技能和技能等级		  
get_attack_skill(SkillList) ->
    case length(SkillList) > 0 of
        true ->
            Index = random:uniform(length(SkillList)) ,
            {SkillId,SkillLv} = lists:nth(Index, SkillList) ;
        false ->
            SkillId = ?MON_DEFAULT_SKILL ,
            SkillLv = ?MON_DEFAULT_SKILL_LV
    end ,
    {SkillId,SkillLv} .


concatPatrol(Intval) ->
    Val1 = Intval div 1000,
    Val2 = Intval rem 1000,
    {Val1,Val2}.

%%执行怪物移动操作
move_action(MonRcd,Path)->
    if
        MonRcd#temp_mon_layout.battle_attr#battle_attr.status_stop =:= 0 ->
            [{NextX,NextY}|LeftPath] = Path ,
            BattleAttr = MonRcd#temp_mon_layout.battle_attr,
            %%处理走直线和走斜线的定时调用时间间隔，实现前后端同步

            if
                MonRcd#temp_mon_layout.pos_x =/= NextX  andalso MonRcd#temp_mon_layout.pos_y =/= NextY ->

                    if
                        BattleAttr#battle_attr.clock_time =:= ?MON_STATE_SPEED_3 ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY,clock_time = ?MON_STATE_SPEED_BIAS_3};
                        BattleAttr#battle_attr.clock_time =:= ?MON_STATE_SPEED_7 ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY,clock_time = ?MON_STATE_SPEED_BIAS_7};
                        true ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY}
                    end;
                true ->
                    if
                        BattleAttr#battle_attr.clock_time =:= ?MON_STATE_SPEED_BIAS_3 ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY,clock_time = ?MON_STATE_SPEED_3};
                        BattleAttr#battle_attr.clock_time =:= ?MON_STATE_SPEED_BIAS_7 ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY,clock_time = ?MON_STATE_SPEED_7};
                        true ->
                            NewBattAttr = BattleAttr#battle_attr{x = NextX, y = NextY}
                    end
            end,


            NewMonRcd = MonRcd#temp_mon_layout{battle_attr = NewBattAttr,pos_x = NextX, pos_y = NextY,move_path= LeftPath},
            lib_mon:update_monster_warn_area(NewMonRcd#temp_mon_layout.id,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,NextX,NextY,
                NewMonRcd#temp_mon_layout.monrcd#temp_npc.warn_range),
            NewMonRcd;
        true ->
            MonRcd#temp_mon_layout{move_path = []}
    end.
