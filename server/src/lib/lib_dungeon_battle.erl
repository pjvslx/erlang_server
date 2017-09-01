%%%--------------------------------------
%%% @Module  : lib_dungeon_battle
%%% @Author  : chenzhm
%%% @Created : 2013.01.18
%%% @Description:战斗处理 
%%%--------------------------------------
-module(lib_dungeon_battle).
-export([start_player_attack/4,
		 start_mon_attack/6,
		 check_fightable/2,
		 start_pet_attack/4]).

-include("debug.hrl").
-include("common.hrl").
-include("record.hrl").
-include("battle.hrl").


%% 玩家发起攻击前的检查
check_fightable(PlayerStatus,SkillId) ->
	if
		PlayerStatus#player.battle_attr#battle_attr.hit_point =< 0 ->
			[false,3] ;
		true ->
			[true,PlayerStatus]
	end .



%% %%@spec 获取玩家的攻击技能
%% get_attack_skill(Index,SkillId,SkillList,Career) ->
%% 	case lists:keyfind(SkillId, Index, SkillList) of
%% 		false ->
%% 			%% 取职业的默认技能
%% 			data_skill:get_default_skill(Career) ;
%% 		{_SkillId, Lv} ->
%% 			{SkillId, Lv}
%% 	end .


%%@ 副本中的怪物发起战斗
start_mon_attack(MonLayoutStatus, PlayerStatus, SkillId, SkillLv, _Dest, _DestY) ->
	SkillTpl = tpl_skill:get(SkillId) ,
	{AttackArea, _AttackTargetNum} = data_skill:get_skill_aoe(SkillId),
	AttackBattleAttr = battle_util:init_battle_info(MonLayoutStatus, ?ELEMENT_MONSTER),
	if
		SkillTpl#temp_skill.target_type =:= ?DEST_SINGLE  ->
			{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x, PlayerStatus#player.battle_attr#battle_attr.y} ,
			DefendPlayerList = [PlayerStatus] ;
		SkillTpl#temp_skill.target_type =:= ?DEST_ATTACK ->
			{PostX,PostY} = {MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.x, MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.y} ,
			DefendPlayerList = [PlayerStatus] ;
		SkillTpl#temp_skill.target_type =:= ?DEST_DEFEND ->  
			{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x,PlayerStatus#player.battle_attr#battle_attr.y} ,
			DefendPlayerList = [PlayerStatus] ;
		SkillTpl#temp_skill.target_type =:= ?DEST_GROUND ->
			{PostX,PostY} = battle_util:get_attack_postion(MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.x, 
														   MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.y,
														   SkillTpl) ,
			DefendPlayerList = [PlayerStatus] ;
		true ->
			{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x,PlayerStatus#player.battle_attr#battle_attr.y} ,
			DefendPlayerList = []
	end ,
	BattleWithPlayer = lib_battle:fight_with_player(AttackBattleAttr,DefendPlayerList,[],AttackArea, SkillId, SkillLv) ,
	{ok,DataBin} =  pt_20:write(20003, [MonLayoutStatus#temp_mon_layout.id, 
										MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.hit_point, 
										MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.magic, 
										SkillId, SkillLv, 
										PostX,PostY, 
										BattleWithPlayer]) ,
	
	spawn(fun() -> send_battle_result(PlayerStatus, DataBin) end ) .






%%@ 副本中的宠物发起战斗
start_pet_attack(PlayerStatus, MonstrerId, SkillId,_SessionId) ->
	PetInfo = battle_util:get_status(PlayerStatus#player.id, ?ELEMENT_PET),
	PetStatus = battle_util:init_pet_battle_info(PlayerStatus, PetInfo),
	MonLayoutStatus = battle_util:get_status(MonstrerId, ?ELEMENT_MONSTER),
	NowTime = util:longunixtime() ,
	if
		not is_record(PetStatus,pet) ->				%% 玩家不存在
			skip ;
		not is_record(MonLayoutStatus,temp_mon_layout) -> 	%% 怪物不存在
			skip ;
		NowTime < MonLayoutStatus#temp_mon_layout.sing_expire ->
			skip ;
		true -> 
			{NewSkillId, SkillLv} = battle_util:get_attack_skill(1,SkillId,PetStatus#pet.skill_list,?CAREER_PET) ,
			AttackBattleAttr = battle_util:init_battle_info(PetStatus, ?ELEMENT_PET) ,
			{AttackArea, AttackTargetNum} = data_skill:get_skill_aoe(SkillId) ,
			case AttackTargetNum >  1 of
				true ->
					DefendMonLoyoutList = 
						lib_dungeon_monster:get_monsters(MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.x ,
													 MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.y ,
													 AttackArea) ;
				false ->
					DefendMonLoyoutList = [MonLayoutStatus] 
			end ,
			execute_pet_fight(PlayerStatus,AttackBattleAttr,DefendMonLoyoutList,[],AttackArea, NewSkillId, SkillLv) 
	end .

execute_pet_fight(PlayerStatus,_AttackBattleAttr,[],BattleResult,_AttackArea, SkillId, SkillLv) ->
	{ok,DataBin} =  pt_20:write(23013, [PlayerStatus#player.id, 
										SkillId, SkillLv, 
										PlayerStatus#player.battle_attr#battle_attr.x, 
										PlayerStatus#player.battle_attr#battle_attr.y, 
										BattleResult]),
	spawn(fun() -> send_battle_result(PlayerStatus, DataBin) end) ;
execute_pet_fight(PlayerStatus, AttackBattleAttr, [MonLayoutStatus | LeftList], BattleResult, AttackArea, SkillId, SkillLv) ->
	DefendBattleAttr = battle_util:init_battle_info(MonLayoutStatus, ?ELEMENT_MONSTER) ,
	case lib_battle:single_attack(AttackBattleAttr, DefendBattleAttr, AttackArea, SkillId, SkillLv, ?ELEMENT_PLAYER, ?ELEMENT_MONSTER) of
		{0,0,_} ->		%% 不在攻击范围
			NewBattleResult =  BattleResult ;
		{DamageType,DamageValue,NewDefendBattleAttr} ->
			[BattleResultTpl] = save_attacked_monlayout(PlayerStatus,MonLayoutStatus,NewDefendBattleAttr,DamageType,DamageValue) ,
			NewBattleResult = [BattleResultTpl | BattleResult]
	end ,
	execute_pet_fight(PlayerStatus, AttackBattleAttr, LeftList, NewBattleResult, AttackArea, SkillId, SkillLv) .	




%%@ 副本中的人物发起战斗
start_player_attack(PlayerStatus, MonstrerId, PreSkillId, SAction) ->
	AttactBattleAttr = PlayerStatus#player.battle_attr ,
	{SkillId, SkillLv} = battle_util:get_attack_skill(1, PreSkillId, PlayerStatus#player.other#player_other.skill_list, PlayerStatus#player.career) ,
	SkillTpl = tpl_skill:get(SkillId) ,
	{AttackArea, AttackTargetNum} = data_skill:get_skill_aoe(SkillId) ,
	
	if
		SkillTpl#temp_skill.target_type =:= ?DEST_SINGLE  ->
			Distance = data_skill:get_skill_distance(SkillId) ,
			case battle_util:get_status(MonstrerId, ?ELEMENT_MONSTER) of
				DMonlayout when is_record(DMonlayout,temp_mon_layout) ->
					{PostX,PostY} = {DMonlayout#temp_mon_layout.battle_attr#battle_attr.x,DMonlayout#temp_mon_layout.battle_attr#battle_attr.y} ,
					DefendMonLayoutStatusList = [DMonlayout] ;
				_ ->
					{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x, PlayerStatus#player.battle_attr#battle_attr.y} ,
					DefendMonLayoutStatusList = [] 
			end ;
		SkillTpl#temp_skill.target_type =:= ?DEST_ATTACK ->
			Distance = AttackArea ,
			{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x, PlayerStatus#player.battle_attr#battle_attr.y} ,
			{_DefendPlayerStatusList,DefendMonLayoutStatusList} =
				battle_util:get_defend_list(PlayerStatus#player.id, PlayerStatus#player.scene, 
											PlayerStatus#player.battle_attr#battle_attr.x, 
											PlayerStatus#player.battle_attr#battle_attr.y, AttackArea, ?ELEMENT_MONSTER, AttackTargetNum) ;
		true ->
			Distance = data_skill:get_skill_distance(SkillId) ,
			{PostX,PostY} = {PlayerStatus#player.battle_attr#battle_attr.x, PlayerStatus#player.battle_attr#battle_attr.y} ,
			DefendMonLayoutStatusList = []
	end ,
	BattleWithMonster = fight_with_monster(PlayerStatus,AttactBattleAttr,DefendMonLayoutStatusList,[],Distance, SkillId, SkillLv) ,
	{ok,DataBin} =  pt_20:write(20001, [PlayerStatus#player.id, 
										PlayerStatus#player.battle_attr#battle_attr.hit_point, 
										PlayerStatus#player.battle_attr#battle_attr.magic, SkillId,  SkillLv, SAction,
										PostX,PostY, 
										BattleWithMonster]),
	spawn(fun() -> send_battle_result(PlayerStatus, DataBin) end ) .



%% 跟怪物战斗逻辑
fight_with_monster(_PlayerStatus,_AttactBattleAttr,[],BattleResult,_Distance, _SkillId, _SkillLv) ->
	BattleResult ;
fight_with_monster(PlayerStatus,AttactBattleAttr,[MonLayoutStatus | LeftList],BattleResult,Distance, SkillId, SkillLv) ->
	NowTime = util:longunixtime() ,
	if
		is_record(MonLayoutStatus,temp_mon_layout) andalso NowTime >= MonLayoutStatus#temp_mon_layout.sing_expire ->
			DefendBattleAttr = battle_util:init_battle_info(MonLayoutStatus, ?ELEMENT_MONSTER) ,
			case lib_battle:single_attack(AttactBattleAttr, DefendBattleAttr, Distance, SkillId, SkillLv, ?ELEMENT_PLAYER, ?ELEMENT_MONSTER) of
				{0,0,_} ->		%% 不在攻击范围
					NewBattleResult =  BattleResult ;
				{DamageType,DamageValue,NewDefendBattleAttr} ->
					[BattleResultTpl] = save_attacked_monlayout(PlayerStatus,MonLayoutStatus,NewDefendBattleAttr,DamageType,DamageValue) ,
					NewBattleResult = [BattleResultTpl | BattleResult]
			end ;
		true ->
			NewBattleResult = BattleResult
	end ,
	fight_with_monster(PlayerStatus,AttactBattleAttr,LeftList,NewBattleResult,Distance, SkillId, SkillLv) .

%%战斗结束后回写怪物数据
save_attacked_monlayout(PlayerStatus,MonLayoutStatus,BattleAttr,DamageType,DamageValue) ->
	LeftHp = max(0, BattleAttr#battle_attr.hit_point - DamageValue) ,
	NewDamageValue = BattleAttr#battle_attr.hit_point - LeftHp ,
	NewBattleAttr = BattleAttr#battle_attr{ hit_point = LeftHp } ,
	NewMonLayoutStatus = MonLayoutStatus#temp_mon_layout{battle_attr = NewBattleAttr} ,
	lib_dungeon_monster:save_monster(PlayerStatus,NewMonLayoutStatus,LeftHp) ,
	
	BattleResult = [{?ELEMENT_MONSTER, 
					 MonLayoutStatus#temp_mon_layout.id, 
					 LeftHp, 
					 MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.magic, 
					 NewDamageValue, 0, DamageType}] ,
	BattleResult .




%%战斗结束后回写玩家数据
%% save_attacked_player(PlayerStatus,BattleAttr,DamageType,DamageValue) ->
%% 	LeftHp = max(0, BattleAttr#battle_attr.hit_point - DamageValue) ,
%% 	NewDamageValue = BattleAttr#battle_attr.hit_point - LeftHp ,
%% 	NewBattleAttr = BattleAttr#battle_attr{hit_point = LeftHp } ,
%% 	gen_server:cast(PlayerStatus#player.other#player_other.pid, {battle_callback, NewDamageValue,NewBattleAttr}),
%% 	
%% 	BattleResult = [{?ELEMENT_PLAYER, 
%% 					 PlayerStatus#player.id, 
%% 					 LeftHp, 
%% 					 PlayerStatus#player.battle_attr#battle_attr.magic, 
%% 					 NewDamageValue, 0, DamageType}] ,
%% 	BattleResult .



get_mon_attack_result(DefendBattleResult) ->
	F = fun(Info, Result) ->
		{DefendType, DefendId, Hp, _Mp, _NewHpDamege, _MpDamege, _DamageType} = Info,
		if
			Hp > 0 -> Result;
			true -> [{DefendId, DefendType}] ++ Result
		end
	end,
	lists:foldl(F, [], DefendBattleResult).


%% DefendBattleResult 受击者列表
send_battle_result(PlayerStatus, DataBin) ->
	lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, DataBin) .
