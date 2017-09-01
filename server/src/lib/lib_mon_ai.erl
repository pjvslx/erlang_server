%% Author: Administrator
%% Created:
%% Description: TODO: Add description to lib_mon_ai
-module(lib_mon_ai).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("battle.hrl").
-include("log.hrl").
-include("debug.hrl").

%%
%% Exported Functions
%%
-export([handle_mon_ai/3, init_mon_ai_data/1, update_mon_fight_time/1,concatPatrol/1,back_init_ai/1,change_to_fight_ai/1,cal_patrol_path/1]).


%%
%% API Functions
%%
%% 触发怪物AI
%% MonAiId怪物AI编号
%% MonRcd 怪物信息
handle_mon_ai(MonAiId, MonRcdId,PlayerStatus) ->
    MonRcd = lib_mon:get_monster(MonRcdId),
    if
        is_record(MonRcd,temp_mon_layout) ->
            case (MonAiId > 0) andalso tpl_mon_ai:get(MonAiId) of %%tpl_mon_ai:get(MonAIRcd)获取怪物的ai信息
                MonAIRcd when is_record(MonAIRcd, temp_mon_ai) ->
                    %%判定是否可以进入现有AI
                    case check_mon_ai(MonAIRcd#temp_mon_ai.ai_trigger, MonRcd, PlayerStatus) of
                        true -> % 触发AI
                            NewMonRcd2 = trigger_monster_ai(MonAIRcd, MonRcd, PlayerStatus),%%根据ai动作类型更新怪物ai信息
                            NewMonRcd3 = update_mon_info(MonAIRcd, NewMonRcd2);%%更新ai的行为列表
                        false ->
                            NewMonRcd3 = MonRcd
                    end,
                    lib_mon:save_monster(NewMonRcd3);
                _ -> 
                    ?ERROR_MSG("handle_mon_ai ERROR OCCURE:MonAiId Error,MonAi Not Exists[~p]!~n",[MonAiId]),
                    MonRcd
            end;
        true ->
            skip
    end.

%% 更新怪物开始战斗时间
update_mon_fight_time(MonRcd) ->
    case MonRcd#temp_mon_layout.start_fight_time =:= 0 of
        true -> MonRcd#temp_mon_layout{start_fight_time = util:unixtime()};
        false -> MonRcd
    end.

%% 怪物死后,复活，初始化怪物身上AI数据
init_mon_ai_data(MonRcd) ->
    MonRcd#temp_mon_layout{round_times = 0,
        ai_skill_id = 0,
        start_fight_time = 0,
        ai_handle_list = [],
        hate_seq = 10000
    }.
%%
%% Local Functions
%%
update_mon_info(MonAIRcd, MonRcd) ->
    case MonAIRcd#temp_mon_ai.trigger_flag =:= 1 of
        true -> 
            case MonAIRcd#temp_mon_ai.ai_trigger of
                {round, _} ->
                    MonRcd#temp_mon_layout{ai_handle_list = [{round} | MonRcd#temp_mon_layout.ai_handle_list]};
                {fight, _} ->
                    MonRcd#temp_mon_layout{ai_handle_list = [{fight} | MonRcd#temp_mon_layout.ai_handle_list]};
                {mon_hp_lower, _} ->
                    MonRcd#temp_mon_layout{ai_handle_list = [{mon_hp_lower} | MonRcd#temp_mon_layout.ai_handle_list]};
                {player_hp_lower, _} ->
                    MonRcd#temp_mon_layout{ai_handle_list = [{player_hp_lower} | MonRcd#temp_mon_layout.ai_handle_list]};
                {mon_buff, BuffTid} ->
                    case lists:keyfind(mon_buff, 1, MonRcd#temp_mon_layout.ai_handle_list) of
                        {mon_buff, BuffList} ->
                            AIList = lists:keyreplace(mon_buff, 1, MonRcd#temp_mon_layout.ai_handle_list, {mon_buff, [BuffTid | BuffList]}),							
                            MonRcd#temp_mon_layout{ai_handle_list = AIList};
                        _ -> MonRcd#temp_mon_layout{ai_handle_list = [{mon_buff, [BuffTid]} | MonRcd#temp_mon_layout.ai_handle_list]}
                    end;
                {player_buff, BuffTid} ->
                    case lists:keyfind(player_buff, 1, MonRcd#temp_mon_layout.ai_handle_list) of
                        {player_buff, BuffList} ->
                            AIList = lists:keyreplace(player_buff, 1, MonRcd#temp_mon_layout.ai_handle_list, {mon_buff, [BuffTid | BuffList]}),							
                            MonRcd#temp_mon_layout{ai_handle_list = AIList};
                        _ -> MonRcd#temp_mon_layout{ai_handle_list = [{player_buff, [BuffTid]} | MonRcd#temp_mon_layout.ai_handle_list]}
                    end;
                {player_dead} ->
                    MonRcd#temp_mon_layout{ai_handle_list = [{player_dead} | MonRcd#temp_mon_layout.ai_handle_list]};
                _ -> MonRcd
            end;
        false -> MonRcd
    end.

%% AI类型:
%% 1怪物喊话
%% 2怪物释放某技能
%% 3选取仇恨列表第n位为目标
%% 4怪物在自己身旁召唤同伴
%% 5怪物在角色身旁召唤同伴
%% 6怪物漫游
%% 7怪物巡逻
%% 8怪物逃跑
%% 9怪物巡逻2(改变出生点)
trigger_monster_ai(MonAIRcd, MonRcd, PlayerStatus) ->
    NowLongTime = util:longunixtime(),
    if
        %% -----------------------------------------------------------------------------------
        %%                                   怪物喊话
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 1 ->
            do_speek(MonRcd,MonAIRcd,NowLongTime);

        %% -----------------------------------------------------------------------------------
        %%                                   怪物释放某技能
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 2 ->
            %{[SkillId, SkillLv]} = MonAIRcd#temp_mon_ai.skill ,
            RandNum = util:rand(0,100),
            %TargetSkill = {},%格式由原来的{[SkillId,SkillLv]}改为[{SkillId,SkillLv,RandNum}, ...]
            TargetSkill = get_one_by_rand(RandNum,MonAIRcd#temp_mon_ai.skill),
            case size(TargetSkill) =:= 3 of
                true ->
                    {SkillId, SkillLv,_} = TargetSkill;
                false ->
                    SkillId = 0,
                    SkillLv = 0
            end,
            NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
            NewMonRcd#temp_mon_layout{ai_skill_id = SkillId, ai_skill_lv = SkillLv} ;

        %% -----------------------------------------------------------------------------------
        %%                                   选取仇恨列表第n位为目标
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 3 ->
            case MonAIRcd#temp_mon_ai.target of
                {attack_target, Seq} ->
                    HateList = lists:reverse(lists:keysort(2, MonRcd#temp_mon_layout.hate_list)) ,
                    case Seq > length(HateList) of
                        true ->
                            {TUId,_,_} = lists:last(HateList) ;
                        false ->
                            {TUId,_,_} = lists:nth(Seq, HateList) 

                    end ,
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd#temp_mon_layout{target_uid = TUId} ;
                _ -> 
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd
            end;

        %% -----------------------------------------------------------------------------------
        %%                                   怪物在自己身旁召唤同伴
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 4 ->
            case MonAIRcd#temp_mon_ai.target of
                {call_mon, Info} -> % Info = [{monid, num,Rx,Ry}, {monid, num,Rx,Ry}]
                    createAllMon(0,MonRcd,PlayerStatus,Info),
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd;
                _ ->
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd
            end;

        %% -----------------------------------------------------------------------------------
        %%                                   怪物在玩家身旁召唤同伴
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 5 andalso is_record(PlayerStatus,player) ->
            case MonAIRcd#temp_mon_ai.target of
                {call_player, Info} -> % Info = [{monid, num,Rx,Ry}, {monid, num,Rx,Ry}]
                    createAllMon(1,MonRcd,PlayerStatus,Info),
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd;
                _ ->
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd
            end;

        %% -----------------------------------------------------------------------------------
        %%                                   漫游
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 6 ->
            do_surround(MonRcd,MonAIRcd,NowLongTime);

        %% -----------------------------------------------------------------------------------
        %%                                   巡逻
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 7 ->%%巡逻
            do_patrol(MonRcd,MonAIRcd,NowLongTime,1);

        %% -----------------------------------------------------------------------------------
        %%                                   逃跑
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 8 ->
            do_runaway(MonRcd,MonAIRcd,PlayerStatus);
        %% -----------------------------------------------------------------------------------
        %%                                   巡逻2
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 9 ->%%巡逻2(重置出生点)
            do_patrol(MonRcd,MonAIRcd,NowLongTime,2);
        %% -----------------------------------------------------------------------------------
        %%                                   召回
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 10 ->%%召回
            NewNpcRcd = MonRcd#temp_mon_layout.monrcd#temp_npc{hit_point = 0},
            NewMonRcd = MonRcd#temp_mon_layout{monrcd = NewNpcRcd},

            {ok,DataBin} =  pt_12:write(12043, [NewMonRcd#temp_mon_layout.id]),
        	case lib_scene:is_dungeon_scene(NewMonRcd#temp_mon_layout.scene_id) of
		        true ->
                    if
                        is_record(PlayerStatus,player) ->
                            spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, DataBin) end ) ;
                        true ->
                            skip
                    end;
		        false ->
			        mod_scene_agent:send_to_matrix(NewMonRcd#temp_mon_layout.scene_id, NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, DataBin,"")
            end,
            NewMonRcd;

        %% -----------------------------------------------------------------------------------
        %%                                   怪物在指定坐标召唤同伴
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 11 ->
            case MonAIRcd#temp_mon_ai.target of
                {call_player, Info} -> % Info = [{monid, num,Rx,Ry}, {monid, num,Rx,Ry}]
                    createAllMon(2,MonRcd,PlayerStatus,Info),
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd;
                _ ->
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd
            end;
        %% -----------------------------------------------------------------------------------
        %%                   怪物搜索一定范围内的其他怪物并对其释放技能
        %% -----------------------------------------------------------------------------------
        MonAIRcd#temp_mon_ai.ai_type =:= 12 ->
            case MonAIRcd#temp_mon_ai.target of
                {attack_surround_mon, Info} -> % Info = N 
                    {RoundWidth,SkillId,SkillLv} = Info,
                    SkillTpl = tpl_skill:get(SkillId),
                    Fun = battle_util:get_relation_charge_fun(SkillTpl#temp_skill.relation_type),
                    {_,MonsterList} = lib_scene:get_matrix_defenders(
                        ?ELEMENT_MONSTER,
                        MonRcd#temp_mon_layout.scene_id,
                        MonRcd#temp_mon_layout.pos_x,
                        MonRcd#temp_mon_layout.pos_y,
                        RoundWidth,
                        1,Fun,{10}),
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd#temp_mon_layout{ai_skill_id = SkillId, ai_skill_lv = SkillLv} ;
                _ ->
                    MonRcd
            end;
       true ->
            MonRcd
    end.

%% -------------------------------触发AI的条件-----------------------------------

%% 怪物第几次攻击后
check_mon_ai({round, Times}, MonRcd, _PlayerStatus) ->
    case Times =< (MonRcd#temp_mon_layout.round_times + 1) of
        true ->
            %case lists:keyfind(round, 1, MonRcd#temp_mon_layout.ai_handle_list) of
            %    false -> true;
            %    _ -> false
            %end;
            true;
        false ->
            false
    end;

%% 怪物进入战斗若干秒后
check_mon_ai({fight, FightSecond}, MonRcd, _PlayerStatus) ->
    FightTime = util:unixtime() - MonRcd#temp_mon_layout.start_fight_time,
    if
        FightTime >= FightSecond ->
            %case lists:keyfind(fight, 1, MonRcd#temp_mon_layout.ai_handle_list) of
            %    false -> true;
            %    _ -> false
            %end;
            true;
        true -> false
    end;

%% 怪物HP< =x%
check_mon_ai({mon_hp_lower, HpVal}, MonRcd, _PlayerStatus) ->
    HP = HpVal/10000 * MonRcd#temp_mon_layout.battle_attr#battle_attr.hit_point_max,
    if
        HP >= MonRcd#temp_mon_layout.battle_attr#battle_attr.hit_point ->
            %%case lists:keyfind(mon_hp_lower, 1, MonRcd#temp_mon_layout.ai_handle_list) of
            %%    false -> true;
            %%    _ -> false
            %end;
            true;
        true -> false
    end;

%% 怪物目标HP < =x%
check_mon_ai({player_hp_lower, HpVal}, MonRcd, PlayerStatus) when is_record(PlayerStatus,player) ->
    HP = HpVal/10000 * PlayerStatus#player.battle_attr#battle_attr.hit_point_max,
    if
        HP >= PlayerStatus#player.battle_attr#battle_attr.hit_point ->
            %%case lists:keyfind(player_hp_lower, 1, MonRcd#temp_mon_layout.ai_handle_list) of
            %%    false -> true;
            %%    _ -> false
            %%end;
            true;
        true -> false
    end;

%% 怪物有某buff
check_mon_ai({mon_buff, BuffId}, MonRcd, _PlayerStatus) ->	
    case lists:keyfind(BuffId, 1, MonRcd#temp_mon_layout.buff_list) of
        {BuffId, ExpireTime} ->
            case util:unixtime() > ExpireTime of
                true -> false;
                false ->
                    %case lists:keyfind(mon_buff, 1, MonRcd#temp_mon_layout.ai_handle_list) of
                    %    false -> true;
                    %    {mon_buff, BuffList} ->
                    %        lists:keymember(BuffId, 1, BuffList) =:= false
                    %end
                    true
            end;
        false -> false
    end;

%% 怪物目标有某buff
check_mon_ai({player_buff, BuffId}, MonRcd, PlayerStatus) when is_record(PlayerStatus,player)  ->
    PlayeBuffList = PlayerStatus#player.battle_attr#battle_attr.buff1 ++ PlayerStatus#player.battle_attr#battle_attr.buff2,
    case lists:keyfind(BuffId, 1, PlayeBuffList) of
        {BuffId,_, ExpireTime} ->
            case util:unixtime() > ExpireTime/1000 of
                true -> false;
                false ->
                    %case lists:keyfind(player_buff, 1, MonRcd#temp_mon_layout.ai_handle_list) of
                    %    false -> true;
                    %    {player_buff, BuffList} ->
                    %        lists:keymember(BuffId, 1, BuffList) =:= false
                    %end
                    true
            end;
        {BuffId,_,_CD, Times} ->
            case Times < 1 of
                true -> false;
                false ->
                    %case lists:keyfind(player_buff, 1, MonRcd#temp_mon_layout.ai_handle_list) of
                    %    false -> true;
                    %    {player_buff, BuffList} ->
                    %        lists:keymember(BuffId, 1, BuffList) =:= false
                    %end
                    true
            end;
        false -> false
    end;

%% 怪物死亡
check_mon_ai({mon_dead}, MonRcd, _PlayerStatus) ->
    MonRcd#temp_mon_layout.battle_attr#battle_attr.hit_point =:= 0;

%% 怪物目标死亡
check_mon_ai({player_dead}, _MonRcd, PlayerStatus)  when is_record(PlayerStatus,player) ->
    PlayerStatus#player.battle_attr#battle_attr.hit_point =:= 0;

%%怪物路径走完
check_mon_ai({move_path_zero,1},MonRcd,_PlayerStatus) ->
    length(MonRcd#temp_mon_layout.move_path) =:= 0;

%%如果没有triggle条件，则返回true
check_mon_ai(_,_,_) ->
    true.

%%重置AI属性
back_init_ai(MonId) ->
    MonRcd = lib_mon:get_monster(MonId),
    case is_record(MonRcd,temp_mon_layout) of
        true ->
            NewTempNpc = MonRcd#temp_mon_layout.monrcd#temp_npc{ai_id = MonRcd#temp_mon_layout.battle_attr#battle_attr.ai_init_id},
            NewMonRcd = MonRcd#temp_mon_layout{
                monrcd= NewTempNpc,
                round_times = 0,
                target_uid = 0,
                ai_skill_id = 0,
                ai_skill_lv = 0,
                ai_handle_list = []
            },
            lib_mon:save_monster(NewMonRcd),
            NewMonRcd;
        false ->
            MonRcd
    end.

%%使得怪物进入战斗ai
change_to_fight_ai(MonId) ->
    MonRcd = lib_mon:get_monster(MonId),
    case is_record(MonRcd,temp_mon_layout) of
        true ->
            NewTempNpc = MonRcd#temp_mon_layout.monrcd#temp_npc{ai_id = MonRcd#temp_mon_layout.monrcd#temp_npc.fight_ai_id},
            NewMonRcd = MonRcd#temp_mon_layout{monrcd= NewTempNpc,refresh_time = 0},
            lib_mon:save_monster(NewMonRcd);
        false ->
            skip
    end.

%%召唤N个同类怪物
%%Type  0:在怪物身边召唤怪物   1:在玩家身边召唤怪物
%%      2:在指定坐标点召唤怪物(Rx,Ry)
createSameMon(Type,_,_,_,0,_,_) ->
    skip;
createSameMon(Type,MonRcd,PlayerStatus,CalledMonId,N,Rx,Ry)->
    if
        Type =:= 0 ->
            TargetPosOriX = MonRcd#temp_mon_layout.pos_x + util:rand(-Rx,Rx),
            TargetPosOriY = MonRcd#temp_mon_layout.pos_y + util:rand(-Rx,Rx);
        Type =:= 1 ->
            TargetPosOriX = PlayerStatus#player.battle_attr#battle_attr.x + util:rand(-Rx,Rx),
            TargetPosOriY = PlayerStatus#player.battle_attr#battle_attr.y + util:rand(-Rx,Rx);
        true ->
            TargetPosOriX = Rx,
            TargetPosOriY = Ry 
    end,
    
    case lib_scene:check_dest_position(MonRcd#temp_mon_layout.scene_id div 100,[TargetPosOriX,TargetPosOriY],1) of
        {ok,FX1,FX2} ->
            TargetPosX = FX1,
            TargetPosY = FX2;
        fail ->
            TargetPosX = TargetPosOriX,
            TargetPosY = TargetPosOriY
    end,
            
    case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of true ->
            {PosDifX,PosDifY} = {util:rand(-1,1),util:rand(-1,1)},
            gen_server:cast(PlayerStatus#player.other#player_other.pid_dungeon,
                {apply_cast, lib_mon, create_monster,[CalledMonId,PlayerStatus,
                        TargetPosX + PosDifX,
                        TargetPosY + PosDifY,0]});
        false ->
            {PosDifX,PosDifY} = {util:rand(-1,1),util:rand(-1,1)},
            gen_server:cast(PlayerStatus#player.other#player_other.pid_scene,
                {apply_cast, lib_mon, create_monster,[CalledMonId,PlayerStatus,
                        TargetPosX + PosDifX,
                        TargetPosY + PosDifY,0]})
    end,
    createSameMon(Type,MonRcd,PlayerStatus,CalledMonId,N-1,Rx,Ry).

%%召唤多种怪物(每种怪物的个数也不一样)
createAllMon(_,MonRcd,PlayerStatus,[]) ->
    skip;
createAllMon(Type,MonRcd,PlayerStatus,[FirstInfo | LeftInfo]) ->
    if
        size(FirstInfo) =:= 2 ->
            {CalledMonId,CalledMonNum} = FirstInfo,
            Rx = 3,
            Ry = 0;
        true ->
            {CalledMonId,CalledMonNum,Rx,Ry} = FirstInfo
    end,
    createSameMon(Type,MonRcd,PlayerStatus,CalledMonId,CalledMonNum,Rx,Ry),
    createAllMon(Type,MonRcd,PlayerStatus,LeftInfo).

%% -----------------------------------------------------------------------------------
%%                                   说话
%% -----------------------------------------------------------------------------------
do_speek(MonRcd,MonAIRcd,NowLongTime) ->
    {ok, BinData} = pt_12:write(12030, [MonRcd#temp_mon_layout.id,MonAIRcd#temp_mon_ai.id]) ,%%MonAIRcd#temp_mon_ai.id
    case lib_scene:is_dungeon_scene(MonRcd#temp_mon_layout.scene_id) of
        true ->
            PlayerId = get(uid),
            PlayerStatus2 = lib_player:get_player(PlayerId),
            lib_send:send_to_sid(PlayerStatus2#player.other#player_other.pid_send,BinData);
        false ->
            mod_scene_agent:send_to_matrix(MonRcd#temp_mon_layout.scene_id,MonRcd#temp_mon_layout.pos_x,
                MonRcd#temp_mon_layout.pos_y,BinData)
    end,
    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai).

%% -----------------------------------------------------------------------------------
%%                                   漫游
%% -----------------------------------------------------------------------------------
do_surround(MonRcd,MonAIRcd,NowLongTime) ->
    OldMovePath = MonRcd#temp_mon_layout.move_path,
    if
        length(OldMovePath) > 0 -> %%如果正在漫游
            if
                length(OldMovePath) =:= 1 ->
                    NewMonRcdTemp = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd = NewMonRcdTemp#temp_mon_layout{refresh_time = 3000 + NowLongTime};%%停顿3秒
                true ->
                    NewMonRcd = MonRcd
            end,
            NewMonRcd2 = lib_mon_state:move_action(NewMonRcd,OldMovePath);
        NowLongTime - MonRcd#temp_mon_layout.refresh_time > 0 ->
            MonRcd#temp_mon_layout.pid ! {'player_leaving',0},
            OriX = MonRcd#temp_mon_layout.x,
            OriY = MonRcd#temp_mon_layout.y,
            {surround_width,MoveRange} = MonAIRcd#temp_mon_ai.target,%%数据格式需要配对
            RandAddX = util:rand(-MoveRange,MoveRange),
            TargetX = RandAddX + OriX,
            RandAddY = util:rand(-trunc(math:sqrt(MoveRange*MoveRange - RandAddX*RandAddX)),
                trunc(math:sqrt(MoveRange*MoveRange - RandAddX*RandAddX))),
            TargetY = RandAddY + OriY,
            case lib_scene:check_dest_position(MonRcd#temp_mon_layout.scene_id div 100,[TargetX,TargetY],1) of
                {ok,TargetX1,TargetY1} ->
                    MovePath = lib_mon:get_move_path({MonRcd#temp_mon_layout.pos_x,MonRcd#temp_mon_layout.pos_y}, 
                        {TargetX1,TargetY1},10000),
                    {ok,Data} = pt_22:write(22006,[?ELEMENT_MONSTER,MonRcd#temp_mon_layout.id,
                            ?BUFF_EFFECT_MOVE_SPEED,?COMMON_MOVE_SURROUND]),%%修正移动速度为漫游速度
                    NewBattleAttr = MonRcd#temp_mon_layout.battle_attr#battle_attr{
                        clock_time = ?MON_STATE_SPEED_3,
                        speed = ?COMMON_MOVE_SURROUND
                    },
                    NewMonRcd =MonRcd#temp_mon_layout{move_path = MovePath,battle_attr = NewBattleAttr},
                    case lib_scene:is_dungeon_scene(NewMonRcd#temp_mon_layout.scene_id) of
                        true ->
                            PlayerId = get(uid),
                            PlayerStatus = lib_player:get_player(PlayerId),
                            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data),
                            spawn(fun() -> lib_mon_state:broad_monster_move(PlayerStatus, NewMonRcd#temp_mon_layout.id,
                                            NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end);
                        false ->
                            mod_scene_agent:send_to_matrix(NewMonRcd#temp_mon_layout.scene_id,
                                NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, Data),
                            spawn(fun() -> lib_mon_state:broad_monster_move(NewMonRcd#temp_mon_layout.scene_id, NewMonRcd#temp_mon_layout.id,
                                            NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end)
                    end,
                    NewMonRcd;
                fail ->
                    MonRcd
            end;
        true ->
            MonRcd        
    end.

%% -----------------------------------------------------------------------------------
%%                                   巡逻
%% -----------------------------------------------------------------------------------
do_patrol(MonRcd,MonAIRcd,NowLongTime,PatrolType)->
    OldMovePath = MonRcd#temp_mon_layout.move_path,
    if
        length(OldMovePath) > 0 -> %%如果正在巡逻
            if
                length(OldMovePath) =:= 1 ->
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai);
                true ->
                    NewMonRcd = MonRcd
            end,
            NewMonRcd1 = lib_mon_state:move_action(NewMonRcd,OldMovePath),
            if
                PatrolType =:= 2 ->%%改变出生点
                    NewMonRcd2 = NewMonRcd1#temp_mon_layout{x = NewMonRcd1#temp_mon_layout.pos_x,y = NewMonRcd1#temp_mon_layout.pos_y};
                true ->
                    NewMonRcd2 = NewMonRcd1
            end;
        true ->
            MonRcd#temp_mon_layout.pid ! {'player_leaving',0},
            NewMonRcd = MonRcd,%lib_mon_ai:back_init_ai(MonRcd#temp_mon_layout.id),
            {patrol_path,MovePath2} = MonAIRcd#temp_mon_ai.target,%%数据格式需要配对,
            [{FirstPatrolPosX,FirstPatrolPosY} | _] = MovePath2,
            MovePath0 = lib_mon:get_move_path({NewMonRcd#temp_mon_layout.pos_x,NewMonRcd#temp_mon_layout.pos_y},
                {NewMonRcd#temp_mon_layout.x,NewMonRcd#temp_mon_layout.y}, 10000),
            MovePath1 = lib_mon:get_move_path({NewMonRcd#temp_mon_layout.x,NewMonRcd#temp_mon_layout.y},
                {FirstPatrolPosX,FirstPatrolPosY},10000),
            MovePath = MovePath0 ++ MovePath1 ++ cal_patrol_path(MovePath2),

            {ok,Data} = pt_22:write(22006,[?ELEMENT_MONSTER,NewMonRcd#temp_mon_layout.id,
                    ?BUFF_EFFECT_MOVE_SPEED,?COMMON_MOVE_PATROL]),%%通知前端修正移动速度为巡逻速度
            case lib_scene:is_dungeon_scene(NewMonRcd#temp_mon_layout.scene_id) of
                true ->
                    PlayerId = get(uid),
                    PlayerStatus = lib_player:get_player(PlayerId),
                    spawn(fun() -> lib_mon_state:broad_monster_move(PlayerStatus, NewMonRcd#temp_mon_layout.id,
                                    NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end),
                    lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data) ;
                false ->
                    spawn(fun() -> lib_mon_state:broad_monster_move(NewMonRcd#temp_mon_layout.scene_id, NewMonRcd#temp_mon_layout.id,
                                    NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end),
                    mod_scene_agent:send_to_matrix(NewMonRcd#temp_mon_layout.scene_id,NewMonRcd#temp_mon_layout.pos_x, 
                        NewMonRcd#temp_mon_layout.pos_y, Data)
            end,

            NewMonRcd2 =NewMonRcd#temp_mon_layout{move_path = MovePath,battle_attr = NewMonRcd#temp_mon_layout.battle_attr#battle_attr{clock_time = ?MON_STATE_SPEED_3}}%%后端修正移动速度为巡逻速度
    end.

%% -----------------------------------------------------------------------------------
%%                                  逃跑 
%% -----------------------------------------------------------------------------------
do_runaway(MonRcd,MonAIRcd,PlayerStatus) ->
    OldMovePath = MonRcd#temp_mon_layout.move_path,
    if
        length(OldMovePath) > 0 -> %%如果正在逃跑
            if
                length(OldMovePath) =:= 1 ->
                    NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
                    NewMonRcd;
                true ->
                    NewMonRcd = MonRcd
            end,
            NewMonRcd2 = lib_mon_state:move_action(NewMonRcd,OldMovePath);
        MonRcd#temp_mon_layout.state =:= ?MON_STATE_4_FIGHT andalso is_record(PlayerStatus,player) ->%%开始逃跑
            MonRcd#temp_mon_layout.pid ! {'player_leaving',0},
            NewMonRcd = MonRcd,%lib_mon_ai:back_init_ai(MonRcd#temp_mon_layout.id),
            OriMonX = NewMonRcd#temp_mon_layout.pos_x,
            OriMonY = NewMonRcd#temp_mon_layout.pos_y,

            OriPlayerX = PlayerStatus#player.battle_attr#battle_attr.x,
            OriPlayerY = PlayerStatus#player.battle_attr#battle_attr.y,

            {runaway_width,ReturnStep} = MonAIRcd#temp_mon_ai.target,%%数据格式需要配对,
            if
                OriMonX =:= OriPlayerX andalso OriMonY =/= OriPlayerY ->
                    TargetX = OriMonX,
                    TargetY = trunc(OriMonY - ReturnStep*(OriPlayerY - OriMonY)/abs(OriPlayerY - OriMonY));
                OriMonX =:= OriPlayerX andalso OriMonY =:= OriPlayerY ->
                    TargetX = OriMonX,
                    TargetY = OriMonY - ReturnStep;
                OriMonX =/= OriPlayerX andalso OriMonY =:= OriPlayerY ->
                    TargetX = trunc(OriMonX - ReturnStep*(OriPlayerX - OriMonX)/abs(OriPlayerX - OriMonX)),
                    TargetY = OriMonY;
                OriMonX =/= OriPlayerX andalso OriMonY =/= OriPlayerY ->
                    TargetX = trunc(OriMonX - ReturnStep*(OriPlayerX - OriMonX)/abs(OriPlayerX - OriMonX)),
                    TargetY = trunc(OriMonY - ReturnStep*(OriPlayerY - OriMonY)/abs(OriPlayerY - OriMonY))
            end,

            case lib_scene:check_dest_position(NewMonRcd#temp_mon_layout.scene_id div 100,[TargetX,TargetY],1) of
                {ok,TargetX1,TargetY1} ->
                    MovePath = lib_mon:get_move_path({NewMonRcd#temp_mon_layout.pos_x,NewMonRcd#temp_mon_layout.pos_y}, 
                        {TargetX1,TargetY1},10000),
                    %{ok,Data} = pt_22:write(22006,[?ELEMENT_MONSTER,NewMonRcd#temp_mon_layout.id,
                    %        ?BUFF_EFFECT_MOVE_SPEED,?COMMON_MOVE_SPEED]),%%通知前端修正移动速度为正常速度
                    case lib_scene:is_dungeon_scene(NewMonRcd#temp_mon_layout.scene_id) of
                        true ->
                            spawn(fun() -> lib_mon_state:broad_monster_move(PlayerStatus, NewMonRcd#temp_mon_layout.id,
                                            NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end);
                        %lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, Data) ;
                        false ->
                            spawn(fun() -> lib_mon_state:broad_monster_move(NewMonRcd#temp_mon_layout.scene_id, NewMonRcd#temp_mon_layout.id,
                                            NewMonRcd#temp_mon_layout.pos_x, NewMonRcd#temp_mon_layout.pos_y, MovePath) end)
                            %mod_scene_agent:send_to_matrix(NewMonRcd#temp_mon_layout.scene_id,NewMonRcd#temp_mon_layout.pos_x,
                            %    MonRcd#temp_mon_layout.pos_y, Data)
                    end,
                    NewMonRcd#temp_mon_layout{move_path = MovePath};
                fail ->
                    NewMonRcd
            end;
        true ->%%逃跑结束
            NewMonRcd = changeNewAI(MonRcd,MonAIRcd,MonAIRcd#temp_mon_ai.next_ai),
            NewMonRcd#temp_mon_layout{target_uid = 0,state = ?MON_STATE_1_GUARD}
    end.

%%-----------------------------------------------------------------------------------------------


%%通过概率来选定同组元素的其中一个元素
get_one_by_rand(_,[]) ->
    {};
get_one_by_rand(_,{}) ->%%兼容
    {};
get_one_by_rand(_,{_}) ->%%兼容
    {};
get_one_by_rand(RandNum,[OneEle | T]) ->
    if
        size(OneEle) =:= 2 ->
            {_,Num} = OneEle;
        size(OneEle) =:= 3 ->
            {_,_,Num} = OneEle;
        true ->
            {_,_,_,Num} = OneEle
    end,
    if
        Num >= RandNum ->
            OneEle;
        true ->
            get_one_by_rand(RandNum-Num,T)
    end.

concatPatrol(Intval) ->
    Val1 = Intval div 1000,
    Val2 = Intval rem 1000,
    {Val1,Val2}.

cal_patrol_path([]) ->
    [];
cal_patrol_path([{_,_}]) ->
    [];
cal_patrol_path([{A1,A2},{B1,B2}]) ->
    lib_mon:get_move_path({A1,A2},{B1,B2},10000);
cal_patrol_path([{A1,A2},{B1,B2} | C]) ->
    Path = lib_mon:get_move_path({A1,A2},{B1,B2},10000),
    Path ++ cal_patrol_path([{B1,B2} | C]).


%%转换AI
changeNewAI(MonRcd,MonAIRcd,NextAiId) ->
    CurAiId = MonAIRcd#temp_mon_ai.id,
    if
        is_list(NextAiId) andalso length(NextAiId) > 0 ->
            %%通过概率来选定同组AI的其中一个AI作为NextAI
            RandNum = util:rand(0,100),
            TargetAi = get_one_by_rand(RandNum,NextAiId),
            if
                is_tuple(TargetAi) andalso size(TargetAi) =:= 2 ->
                    {ReturnAi,_} = TargetAi;
                true ->
                    ReturnAi = CurAiId
            end;
        is_binary(NextAiId) ->%%处理next_ai是一个大于零的整数
            NextAI2 = binary_to_list(NextAiId),
            if
                length(NextAI2) > 0 ->
                    NextAI3 = list_to_integer(NextAI2),
                    if
                        NextAI3 =:= -1 ->
                            ReturnAi = 0;
                        NextAI3 > 0 ->
                            ReturnAi = NextAI3;
                        MonAIRcd#temp_mon_ai.ai_type =:= 8 orelse MonAIRcd#temp_mon_ai.ai_type =:= 7->
                            ReturnAi = MonRcd#temp_mon_layout.battle_attr#battle_attr.ai_init_id;
                        true ->
                            ReturnAi = CurAiId
                    end;
                true ->
                    if
                        MonAIRcd#temp_mon_ai.ai_type =:= 8 orelse MonAIRcd#temp_mon_ai.ai_type =:= 7->
                            ReturnAi = MonRcd#temp_mon_layout.battle_attr#battle_attr.ai_init_id;
                        true ->
                            ReturnAi = CurAiId
                    end
            end;
        true ->
            ReturnAi = CurAiId
    end,
    if
        ReturnAi =/= CurAiId ->
            MonNpc = MonRcd#temp_mon_layout.monrcd#temp_npc{ai_id = ReturnAi},
            NewMonRcd = MonRcd#temp_mon_layout{round_times = 0,monrcd = MonNpc};
        true ->
            NewMonRcd = MonRcd
    end,
    NewMonRcd.
