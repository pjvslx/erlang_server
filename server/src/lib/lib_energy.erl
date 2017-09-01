-module(lib_energy).
-include("record.hrl").
-include("common.hrl"). 
-include("debug.hrl").  
-include("battle.hrl").
-compile(export_all).
-define(EnergyRecord,battle_attr#battle_attr.energy#energy).
  
%%初始化玩家能量球信息
init_energy(Lv,Career,BattleAttr,TempAttr)->
	 case tpl_energy:get(Career,Lv) of
					 Energy when is_record(Energy,temp_energy)->
						 {A1,B1,C1,D1,E1} = Energy#temp_energy.combat_recover, 
						 MaxEnergy =  TempAttr#temp_combat_attr.fundamental_energy, 
						 #energy{
								 attack = Energy#temp_energy.attack,
								 injured = Energy#temp_energy.injured,
								 crit = Energy#temp_energy.crit,
								 battle_recover =	 {0,A1,B1,C1,D1,E1},
								 normal_recover = Energy#temp_energy.normal_recover,
								 last_reflesh_time = util:unixtime(), 
								 max_energy = MaxEnergy,
								 energy_val = get_player_init_energy(Career,MaxEnergy)
								};
					 _->%%找不到对应职业的玩家，随便来一发
						?ERROR_MSG("can not init energy career ~p lv ~p ~n",[Career,Lv]),
						{}
				 end.

get_player_init_energy(?CAREER_D,MaxEnergy)->
	MaxEnergy;
get_player_init_energy(_,_)->
	0.

%% start_player_player_leader(Ps)->
%% 	Ps#player.battle_attr#battle_attr.energy#energy.
%%刷新玩家的能量值
reflesh_energy(Ps)->  
		   case  do_reflesh_energy(Ps) of
			   skip ->
				   Ps;  
			   NewEnergy when is_record(NewEnergy,energy)->  
				   NewBattleAttr = Ps#player.battle_attr#battle_attr{energy = NewEnergy}, 
				   Ps#player{battle_attr = NewBattleAttr}
		   end. 

do_reflesh_energy(Ps)->
	case  energy_util:get_player_recover_energy(Ps#player.status,Ps#player.battle_attr#battle_attr.energy) of
		skip -> skip;
		{reflesh,NewEnergy} ->
			NewEnergy
	end.
 
%%脱离战斗时重置玩家战斗回复能量信息
reset_player_battle_cover_energy(BattleAttr)->
	Energy = BattleAttr#battle_attr.energy,
	{_,A3,C3,A4,C4,A5} = Energy#energy.battle_recover,
	NewEnergy  = Energy#energy{
							   battle_recover = {0,A3,C3,A4,C4,A5},
							   freeze_second = 0
							  },
	BattleAttr#battle_attr{
						   energy = NewEnergy
						  }.

trigger_attr_energy(0,{},_,_,Ps)->
	Ps;
%%暴击回复能量值
trigger_attr_energy(DefendLv,DefendBattleAttr,?DAMAGE_TYPE_CRIT,Damage,Ps) ->  
	{_,AttrEnergy} = energy_util:get_attack_energy(abs(DefendLv-Ps#player.level),DefendBattleAttr#battle_attr.hit_point_max,Damage, Ps#player.battle_attr#battle_attr.energy), 
	NewEnergyVal = energy_util:get_crit_energy(AttrEnergy,Ps#player.battle_attr#battle_attr.energy),
 	do_merge_energy(Ps,NewEnergyVal);

%%普通攻击回复能量值
trigger_attr_energy(DefendLv,DefendBattleAttr,?DAMAGE_TYPE_NORMAL,Damage,Ps)-> 
	{NewEnergyVal,_} = energy_util:get_attack_energy(abs(DefendLv-Ps#player.level),DefendBattleAttr#battle_attr.hit_point_max,Damage, Ps#player.battle_attr#battle_attr.energy),
 	do_merge_energy(Ps,NewEnergyVal).

%%受攻击时回复能量值
trigger_define_energy(0,Ps)->
	Ps;
trigger_define_energy(Damage,Ps)->  
	NewEnergyVal = energy_util:get_injured_energy(Damage, Ps#player.battle_attr),
 	do_merge_energy(Ps,NewEnergyVal).


%%将最新能量值合并到玩家记录上
do_merge_energy(Ps,EnergyVal)->
	NewEnergy = Ps#player.battle_attr#battle_attr.energy#energy{
						  energy_val = EnergyVal
						  }, 
	NewBattleAttr = Ps#player.battle_attr#battle_attr{
													  energy = NewEnergy
													 },
	Ps#player{
			  battle_attr = NewBattleAttr
			 }.

%%玩家每次攻击时的回调函数
reflesh_attack_energy(DefinePlayers,DefineMonsters,Ps)->
 	{DefendLv,DefendBattleAttr,DamegeType,DamegeVal} = get_damege_info(DefinePlayers++DefineMonsters),
    trigger_attr_energy(DefendLv,DefendBattleAttr,DamegeType,DamegeVal,Ps).

%%通过检测伤害数据，确定本次攻击的伤害类型与伤害值
get_damege_info(DamegeList)->
	F = fun(DamegeItem,{DefendType,DefendId,DamegeType,DamegeVal})->
				case DamegeItem of
					{NewDefendType,NewDefendId,_,_,NewDamegeVal,_,DamegeType} ->
						if NewDamegeVal>DamegeVal ->
							   {NewDefendType,NewDefendId,DamegeType,NewDamegeVal};
						   true ->
							   {DefendType,DefendId,DamegeType,DamegeVal}
						end;
					{NewDefendType,NewDefendId,_,_,NewDamegeVal,_,?DAMAGE_TYPE_CRIT}->
						{NewDefendType,NewDefendId,?DAMAGE_TYPE_CRIT,NewDamegeVal};
					{NewDefendType,NewDefendId,_,_,NewDamegeVal,_,?DAMAGE_TYPE_NORMAL}->
						if DamegeType =:= ?DAMAGE_TYPE_CRIT ->
							   {NewDefendType,NewDefendId,DamegeType,DamegeVal};
						   true ->
							   {NewDefendType,NewDefendId,?DAMAGE_TYPE_NORMAL,NewDamegeVal}
						end;
					_->
						{DefendType,DefendId,DamegeType,DamegeVal}
				end
		end,  
	{FinalDefendType,FinalDefendId,FinalDamegeType,FinalDamegeVal} = lists:foldl(F, {0,0,?DAMAGE_TYPE_MISSED,0}, DamegeList),
	{DefendLv,DefendBattleAttr} = battle_util:get_battle_info(FinalDefendId,FinalDefendType),
	{DefendLv,DefendBattleAttr,FinalDamegeType,FinalDamegeVal}.
%%置满能量值
filling_energy(BattleAttr)->
	NewEnergy = BattleAttr#battle_attr.energy#energy{
													 energy_val = BattleAttr#battle_attr.energy#energy.max_energy
													},
	BattleAttr#battle_attr{ 
						   energy = NewEnergy
						  }.

