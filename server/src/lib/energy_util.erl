-module(energy_util).
-include("record.hrl").
-include("common.hrl"). 
-include("debug.hrl").  
-include("battle.hrl").
-compile(export_all).

%%刷新玩家战斗状态的能量值
get_player_recover_energy(?PLAYER_BATTLE_STATE,Energy)-> 
	RefleshTime = Energy#energy.last_reflesh_time,
	NowTime = util:unixtime(),
	Timepass =  NowTime-RefleshTime,
	EnergyVal = if Timepass >= 1 ->       
					   {NewCoverInfo,NewEnergyVal,FreezeSecond} = calculate_reflesh_energy( Energy#energy.battle_recover,Timepass,Energy#energy.energy_val,Energy#energy.max_energy,Energy#energy.freeze_second),
					 	AddPerCentEnergy = Timepass*Energy#energy.max_energy*Energy#energy.recover_percent/100, 
					    {reflesh,Energy#energy{
											  battle_recover = NewCoverInfo,
											  energy_val = max(0,min(Energy#energy.max_energy,NewEnergyVal+AddPerCentEnergy)),
											  last_reflesh_time = NowTime,
											  freeze_second = FreezeSecond
											 }};
				   true->
					   skip
				end,
	EnergyVal;   
%%刷新玩家正常状态的能量值
get_player_recover_energy(?PLAYER_NORMAL_STATE,Energy) -> 
	RefleshTime = Energy#energy.last_reflesh_time, 
	NowTime = util:unixtime(),
	Timepass =  NowTime-RefleshTime, 
	EnergyVal = if Timepass >= 1 ->  
					    AddPerCentEnergy = util:ceil(Timepass*Energy#energy.max_energy*Energy#energy.recover_percent/100), 
					   NewAddVal = Energy#energy.max_energy*Energy#energy.normal_recover*Timepass/100+AddPerCentEnergy,
					   NewEnergyVal = max(0,min(Energy#energy.max_energy,Energy#energy.energy_val + NewAddVal)),
					   {reflesh,Energy#energy{
											  energy_val = NewEnergyVal,
											  last_reflesh_time = NowTime
											 }};
				   true-> 
					   skip
				end,
	EnergyVal;
get_player_recover_energy(_,_) ->  
	skip.

%%计算玩家进入战斗后每秒的能量值改变
calculate_reflesh_energy(CoverInfo,0,EnergyVal,_,FreezeSecond) ->  
	{CoverInfo,EnergyVal,FreezeSecond}; 
calculate_reflesh_energy(CoverInfo,Index,EnergyVal,MaxEnergy,0)->
	{SecondIndex,A3,C3,A4,C4,A5} = CoverInfo, 
 	NewAddVal = (max(A3-SecondIndex,1)*C3+min(SecondIndex-A4,-1)*C4 )/ 100* MaxEnergy+(util:floor(EnergyVal/MaxEnergy)-1)*util:ceil(A5*EnergyVal), 
	NewEnergyVal = max(0,min(MaxEnergy,EnergyVal+ NewAddVal)),
 	calculate_reflesh_energy({ SecondIndex+1,A3,C3,A4,C4,A5},Index-1,NewEnergyVal,MaxEnergy,0);
calculate_reflesh_energy(CoverInfo,Index,EnergyVal,MaxEnergy,FreezeSecond)->%%加入暂停能量值衰减buff逻辑
 	{SecondIndex,A3,C3,A4,C4,A5} = CoverInfo, 
	calculate_reflesh_energy({ SecondIndex+1,A3,C3,A4,C4,A5},Index-1,EnergyVal,MaxEnergy,FreezeSecond-1).

%%玩家攻击时刷新能量球数值
get_attack_energy(_,_,0,Energy)->
	{Energy#energy.energy_val,0};
get_attack_energy(LvAbs,DefendHitPointMax,Damage,Energy)->  
	{A1,B1,C1} = Energy#energy.attack, 
 	NewAddVal = (min(Damage / DefendHitPointMax,1)*A1 / max(LvAbs - B1,1)+C1)*Energy#energy.max_energy *Energy#energy.attack_callback_rate, 
	{min(Energy#energy.max_energy,Energy#energy.energy_val+NewAddVal),NewAddVal}.

%%玩家爆击时刷新能量球数值
get_crit_energy(AttrEnergy,Energy) when Energy#energy.crit =/= 0-> 
	NewAddVal = AttrEnergy+Energy#energy.crit*Energy#energy.max_energy / 100*Energy#energy.attack_callback_rate,
 	min(Energy#energy.max_energy,Energy#energy.energy_val+NewAddVal ) ;
get_crit_energy(AttrEnergy,Energy)->
	min(Energy#energy.max_energy,Energy#energy.energy_val+AttrEnergy ).

%%玩家被攻击时回复的能量值
get_injured_energy(0,BattleAttr)->
	BattleAttr#battle_attr.energy#energy.energy_val;
get_injured_energy(Damage,BattleAttr)->
	Energy = BattleAttr#battle_attr.energy,
	{A2,C2} = Energy#energy.injured,  
	NewAddVal = (1-A2 / (min(Damage / BattleAttr#battle_attr.hit_point_max,1)+A2))*Energy#energy.max_energy*C2,
  	min(Energy#energy.max_energy,Energy#energy.energy_val+NewAddVal*Energy#energy.injured_rate/1000).
%%按百分比回复能量
cover_percent_energy(BattleAttr,Percent)-> 
	NewEnergy = BattleAttr#battle_attr.energy#energy{  
													 recover_percent = BattleAttr#battle_attr.energy#energy.recover_percent + Percent
													 },
	BattleAttr#battle_attr{energy = NewEnergy}.
%% %%停止按百分比回复能量
%% stop_cover_percent_energy(BattleAttr)->
%% 	NewEnergy = BattleAttr#battle_attr.energy#energy{ 
%% 													 is_auto_recovering = false
%% 													 },
%% 		BattleAttr#battle_attr{energy = NewEnergy}.