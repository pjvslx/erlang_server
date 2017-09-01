%%%------------------------------------------------    
%%% File    : data_battle.erl    
%%% Author  : water
%%% Desc    : 战斗伤害计算参数公式
%%%------------------------------------------------
-module(data_battle).     
-compile(export_all).

-include("battle.hrl").
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

%%断言以及打印调试信息宏
%%不需要时启用 -undefine行
%-define(battle_debug, 1).
-undefine(battle_debug).  
-ifdef(battle_debug).
-define(MYTRACE(Str), io:format(Str), ?INFO_MSG(Str, [])).
-define(MYTRACE(Str, Args), io:format(Str, Args), ?INFO_MSG(Str, Args)).
  
-else.
-define(MYTRACE(Str), void).
-define(MYTRACE(Str, Args), void). 
-endif.

%%向下取整,不小于0
round_down(Val) ->
    case Val > 0 of
        true  -> util:floor(Val);
        false -> 0
    end.

%%获取伤害值计算系数
get_coef(?BATTLE_TYPE_PVE) ->  	%%玩家VS怪物
    [10000, 0.865, 0.5, 90000];
get_coef(?BATTLE_TYPE_PVP) -> 	%%玩家VS玩家
    [10000, 0.5, 0.865, 90000];
get_coef(_) ->            		%%不知类型,随便算算
    [10000, 0.865, 0.5, 90000].

%%根据暴击等级(等)计算暴击系数
get_crit_coef(_) ->
    1.5.
%%计算玩家当前失去的生命值百分比
get_lost_hp(HpMax,CurrentHp)-> 
	LostPrecent = (HpMax-CurrentHp)/max(1,HpMax)*100,
	util:ceil(LostPrecent).

%%获取buff伤害
get_buff_damage(BattleType, Aer, Der, DamageTimes, DamageVal) ->    
    [Coef1, _Coef2, _Coef3, _Coef4] = get_coef(BattleType),  
            case is_hit(Aer#battle_attr.hit_ratio, Der#battle_attr.dodge_ratio,0) of
                true  ->   %%命中
                    case is_crit(Aer#battle_attr.crit_ratio, Der#battle_attr.tough_ratio,0) of
                        true  -> 
                            %%属性伤害
                            FmdDamage = case Aer#battle_attr.career of
                                ?CAREER_F ->   
                                    crit_fattack_damage(BattleType, Aer, Der) * 
                                    ((Coef1 - Der#battle_attr.avoid_fattack_ratio)/Coef1) * 
                                    ((Coef1 - Der#battle_attr.avoid_crit_fattack_ratio)/Coef1);
                                ?CAREER_M -> 
                                    crit_mattack_damage(BattleType, Aer, Der) *   
                                    ((Coef1 - Der#battle_attr.avoid_mattack_ratio)/Coef1) *
                                    ((Coef1 - Der#battle_attr.avoid_crit_mattack_ratio)/Coef1);
                                ?CAREER_D -> 
                                    crit_dattack_damage(BattleType, Aer, Der) * 
                                    ((Coef1 - Der#battle_attr.avoid_dattack_ratio)/Coef1) *
                                    ((Coef1 - Der#battle_attr.avoid_crit_dattack_ratio)/Coef1) ;
                                _Other -> 
                                    0
                            end,
                            %%普攻伤害
                            Damage = crit_attack_damage(BattleType, Aer, Der) * ((Coef1 - Der#battle_attr.avoid_attack_ratio)/Coef1) *
                            ((Coef1 - Der#battle_attr.avoid_crit_attack_ratio)/Coef1), 
                            TotalDamage = round_down((Aer#battle_attr.abs_damage + Damage + FmdDamage)*DamageTimes)+DamageVal, 
						     {?DAMAGE_TYPE_CRIT,  TotalDamage};
                        false -> 
                            %%属性伤害
                            FmdDamage = case Aer#battle_attr.career of
                                ?CAREER_F -> 
                                    fattack_damage(BattleType, Aer, Der) *
                                    ((Coef1 - Der#battle_attr.avoid_fattack_ratio)/Coef1);
                                ?CAREER_M -> 
                                    mattack_damage(BattleType, Aer, Der) *
                                    ((Coef1 - Der#battle_attr.avoid_mattack_ratio)/Coef1);
                                ?CAREER_D -> 
                                    dattack_damage(BattleType, Aer, Der) * 
                                    ((Coef1 - Der#battle_attr.avoid_dattack_ratio)/Coef1);
                                _Other    -> 
                                    0
                            end,
                            %%普攻伤害
                            Damage = attack_damage(BattleType, Aer, Der) * ((Coef1 - Der#battle_attr.avoid_attack_ratio)/Coef1), 
                            TotalDamage = round_down((Aer#battle_attr.abs_damage + Damage + FmdDamage)*DamageTimes)+DamageVal, 
							  {?DAMAGE_TYPE_NORMAL, TotalDamage}
                    end;
                false -> %%不命中 
                    {?DAMAGE_TYPE_MISSED, 0} 
            end .
%%伤害计算过程
%% Aer 攻方战斗属性
%% Der 守方战斗属性
%% SkillId, SkillLv 技能ID, 
%% 返回值: {伤害类型, 伤害值}
%% get_damage(BattleType, Aer, Der, SkillId, SkillLv) ->  
%%     [Coef1, _, _, _] = get_coef(BattleType),
%%     SkillTpl = tpl_skill:get(SkillId),
%%     if
%%         is_record(SkillTpl,temp_skill) ->
%%             case is_hit(Aer#battle_attr.hit_ratio, Der#battle_attr.dodge_ratio,SkillTpl#temp_skill.is_hit) of
%%                 true  ->   %%命中
%%                     case is_crit(Aer#battle_attr.crit_ratio, Der#battle_attr.tough_ratio,SkillTpl#temp_skill.is_crit) of
%%                         true  -> 
%%                             %%属性伤害
%%                             FmdDamage = case Aer#battle_attr.career of
%%                                 ?CAREER_F ->   
%%                                     crit_fattack_damage(BattleType, Aer, Der) * 
%%                                     ((Coef1 - Der#battle_attr.avoid_fattack_ratio)/Coef1) * 
%%                                     ((Coef1 - Der#battle_attr.avoid_crit_fattack_ratio)/Coef1);
%%                                 ?CAREER_M -> 
%%                                     crit_mattack_damage(BattleType, Aer, Der) *   
%%                                     ((Coef1 - Der#battle_attr.avoid_mattack_ratio)/Coef1) *
%%                                     ((Coef1 - Der#battle_attr.avoid_crit_mattack_ratio)/Coef1);
%%                                 ?CAREER_D -> 
%%                                     crit_dattack_damage(BattleType, Aer, Der) * 
%%                                     ((Coef1 - Der#battle_attr.avoid_dattack_ratio)/Coef1) *
%%                                     ((Coef1 - Der#battle_attr.avoid_crit_dattack_ratio)/Coef1) ;
%%                                 _Other -> 
%%                                     0
%%                             end,
%%                             %%普攻伤害
%%                             Damage = crit_attack_damage(BattleType, Aer, Der) * ((Coef1 - Der#battle_attr.avoid_attack_ratio)/Coef1) *
%%                             ((Coef1 - Der#battle_attr.avoid_crit_attack_ratio)/Coef1),
%%                             %%技能伤害
%%                             SkillDamage = crit_skill_damage(Aer, SkillId, SkillLv),
%%                             TotalDamage = round_down(Aer#battle_attr.abs_damage + Damage + SkillDamage + FmdDamage),
%%                          
%% 						 	?MYTRACE("CRIT: Fmddamage: ~p damage: ~p skill: ~p,  total: ~p~n", [FmdDamage,  Damage,  SkillDamage, TotalDamage]),
%%                             ?MYTRACE("Aer: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Aer)]),
%%                             ?MYTRACE("Der: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Der)]),
%%                             ?BATTLE_DEMAFE_TRACE(crit,FmdDamage,Damage,SkillDamage,TotalDamage),
%%                             {?DAMAGE_TYPE_CRIT,  TotalDamage};
%%                         false -> 
%%                             %%属性伤害
%%                             FmdDamage = case Aer#battle_attr.career of
%%                                 ?CAREER_F -> 
%%                                     fattack_damage(BattleType, Aer, Der) *
%%                                     ((Coef1 - Der#battle_attr.avoid_fattack_ratio)/Coef1);
%%                                 ?CAREER_M -> 
%%                                     mattack_damage(BattleType, Aer, Der) *
%%                                     ((Coef1 - Der#battle_attr.avoid_mattack_ratio)/Coef1);
%%                                 ?CAREER_D -> 
%%                                     dattack_damage(BattleType, Aer, Der) * 
%%                                     ((Coef1 - Der#battle_attr.avoid_dattack_ratio)/Coef1);
%%                                 _Other    -> 
%%                                     0
%%                             end,
%%                             %%普攻伤害
%%                             Damage = attack_damage(BattleType, Aer, Der) * ((Coef1 - Der#battle_attr.avoid_attack_ratio)/Coef1),
%%                             %%技能伤害
%%                             SkillDamage = skill_damage(SkillId, SkillLv),
%%                             TotalDamage = round_down(Aer#battle_attr.abs_damage + Damage + SkillDamage + FmdDamage),
%% 						      ?MYTRACE("NORMAL: Fmddamage: ~p damage: ~p skill: ~p,  total: ~p~n", [FmdDamage,  Damage,  SkillDamage, TotalDamage]),
%%                             ?MYTRACE("Aer: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Aer)]),
%%                             ?MYTRACE("Der: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Der)]),
%%                             ?BATTLE_DEMAFE_TRACE(normal,FmdDamage,Damage,SkillDamage,TotalDamage),
%%                             {?DAMAGE_TYPE_NORMAL, TotalDamage}
%%                     end;
%%                 false -> %%不命中
%%                     ?MYTRACE("MISS: ~n"),
%%                     ?MYTRACE("Aer: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Aer)]),
%%                     ?MYTRACE("Der: ~s~n", [tool:recinfo(record_info(fields, battle_attr), Der)]),
%%                     {?DAMAGE_TYPE_MISSED, 0} 
%%             end;
%%         true ->
%%             {?DAMAGE_TYPE_MISSED, 0}
%%     end.


%%计算是否可以暴击,
%% AerCrit为攻击暴击等级, Der为守方坚韧等级
%% 返回 true为暴击, false为一般攻击
is_crit(_,_,?SKILL_IS_CRIT)->
    true;
is_crit(AerCrit, DerTough,_) ->
    CritRatio = round_down(10000 * AerCrit/ (AerCrit + DerTough * 10 + 1)),
    CritCmp = util:rand(1, 10000),
    ?MYTRACE("is_crit: AerCrit: ~p, DerTough: ~p, CritRatio: ~p,  Random: ~p  ", [AerCrit, DerTough, CritRatio, CritCmp]),
    ?MYTRACE("return: ~p~n", [(CritCmp =< CritRatio)]),
    CritRatio >= CritCmp.

%%计算是否可以命中,
%% AerHit为攻击方命中等级, DerDodge为守方躲闪等级
%% 返回 true为命中, false为不命中 
is_hit(_,_,?SKILL_IS_HIT)->
    true;
is_hit(AerHit, DerDodge,_) ->
    HitRatio = round_down(10000  - (2500 + AerHit*10000/(AerHit + DerDodge + 1))),
    HitCmp = util:rand(1, 10000),
    ?MYTRACE("is_hit: AerHit: ~p, DerDodge: ~p, HitRatio: ~p,  Random: ~p  ", [AerHit, DerDodge, HitRatio, HitCmp]),
    ?MYTRACE("return: ~p~n", [(HitRatio >= HitCmp)]),
    HitRatio =< HitCmp.

%%普攻伤害值
%%参数: 
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
attack_damage(BattleType, Aer, Der) ->  %%怪造成的伤害
    [Coef1, Coef2, _Coef3, Coef4] = get_coef(BattleType),
    AerAttack = Aer#battle_attr.attack *(Coef1 + Aer#battle_attr.attack_ratio)/Coef1,
    DerDefense = Der#battle_attr.real_defense * (Coef1 + Der#battle_attr.defense_ratio)/Coef1 - Aer#battle_attr.ignore_defense,
    if AerAttack >= DerDefense ->
            round_down((AerAttack - DerDefense) * Coef2) + 
            round_down((Der#battle_attr.real_defense * (Coef1 + Der#battle_attr.defense_ratio) - Coef1*Aer#battle_attr.ignore_defense)/Coef4);
        true ->
            round_down(AerAttack * (Coef1 + Aer#battle_attr.attack_ratio)/Coef4)
    end.


%%技能伤害值
%%参数: 
%%      SkillId,    技能ID
%%      SkillLv,    技能等级
%%返回: 伤害值
%% skill_damage(SkillId, SkillLv) ->
%%     {SkillDamage, SkillCoef} = data_skill:get_abs_damage(SkillId, SkillLv),
%%     Damage = round_down(SkillDamage * SkillCoef), 
%%     round_down(Damage).

%%仙攻伤害值
%%参数: 
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
fattack_damage(BattleType, Aer, Der) ->
    [Coef1, _Coef2, Coef3, Coef4] = get_coef(BattleType),
    AerFAttack = Aer#battle_attr.fattack *(Coef1 + Aer#battle_attr.fattack_ratio)/Coef1,
    DerFDefense = Der#battle_attr.fdefense * (Coef1 + Der#battle_attr.fdefense_ratio)/Coef1 - Aer#battle_attr.ignore_fdefense,
    if AerFAttack >= DerFDefense ->
            round_down((AerFAttack - DerFDefense) * Coef3) + 
            round_down((Der#battle_attr.fdefense * (Coef1 + Der#battle_attr.fdefense_ratio) - Coef1*Aer#battle_attr.ignore_fdefense)/Coef4);
        true ->
            round_down(AerFAttack * (Coef1 + Aer#battle_attr.fattack_ratio)/Coef4)
    end.

%%魔攻伤害值
%%参数: 
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
mattack_damage(BattleType, Aer, Der) ->
    [Coef1, _Coef2, Coef3, Coef4] = get_coef(BattleType),
    AerMAttack = Aer#battle_attr.mattack *(Coef1 + Aer#battle_attr.mattack_ratio)/Coef1,
    DerMDefense = Der#battle_attr.mdefense * (Coef1 + Der#battle_attr.mdefense_ratio)/Coef1 - Aer#battle_attr.ignore_mdefense,
    if AerMAttack >= DerMDefense ->
            round_down((AerMAttack - DerMDefense) * Coef3) + 
            round_down((Der#battle_attr.mdefense * (Coef1 + Der#battle_attr.mdefense_ratio) - Coef1*Aer#battle_attr.ignore_mdefense)/Coef4);
        true ->
            round_down(AerMAttack * (Coef1 + Aer#battle_attr.mattack_ratio)/Coef4)
    end.

%%妖攻伤害值
%%参数: 
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
dattack_damage(BattleType, Aer, Der) ->
    [Coef1, _Coef2, Coef3, Coef4] = get_coef(BattleType),
    AerDAttack = Aer#battle_attr.dattack *(Coef1 + Aer#battle_attr.dattack_ratio)/Coef1,
    DerDDefense = Der#battle_attr.ddefense * (Coef1 + Der#battle_attr.ddefense_ratio)/Coef1 - Aer#battle_attr.ignore_ddefense,
    if AerDAttack >= DerDDefense ->
            round_down((AerDAttack - DerDDefense) * Coef3) + 
            round_down((Der#battle_attr.ddefense * (Coef1 + Der#battle_attr.ddefense_ratio) - Coef1*Aer#battle_attr.ignore_ddefense)/Coef4);
        true ->
            round_down(AerDAttack * (Coef1 + Aer#battle_attr.dattack_ratio)/Coef4)
    end.

%%暴击伤害值
%%参数: 
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
crit_attack_damage(BattleType, Aer, Der) ->
    CritCoef = get_crit_coef(Aer#battle_attr.crit_ratio),
    round_down(attack_damage(BattleType, Aer, Der) * CritCoef).     

%%技能暴击伤害值
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%      SkillId,    技能ID
%%      SkillLv,    技能等级
%% %%返回: 伤害值
%% crit_skill_damage(Aer, SkillId, SkillLv) ->
%%     CritCoef = get_crit_coef(Aer#battle_attr.crit_ratio),
%%     round_down(skill_damage(SkillId, SkillLv) * CritCoef).     

%%仙攻暴攻伤害值
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
crit_fattack_damage(BattleType, Aer, Der) ->
    CritCoef = get_crit_coef(Aer#battle_attr.crit_ratio),
    round_down(fattack_damage(BattleType, Aer, Der) * CritCoef). 

%%魔攻暴击伤害值
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
crit_mattack_damage(BattleType, Aer, Der) ->
    CritCoef = get_crit_coef(Aer#battle_attr.crit_ratio),
    round_down(mattack_damage(BattleType, Aer, Der) * CritCoef). 

%%妖攻暴击伤害值
%%      BattleType, 战斗类型(PVP, PVE)
%%      Aer,        攻击战斗属性
%%      Der,        守方战斗属性
%%返回: 伤害值
crit_dattack_damage(BattleType, Aer, Der) ->
    CritCoef = get_crit_coef(Aer#battle_attr.crit_ratio),
    round_down(dattack_damage(BattleType, Aer, Der) * CritCoef). 

%----------------------
%-	新技能计算公式
%----------------------
get_damage(BattleType, Aer, Der, SkillId, SkillLv)->
	case is_hit(Aer#battle_attr.hit_ratio, Der#battle_attr.dodge_ratio,0) of
		true  ->   %%命中
			TplSkillAttr = tpl_skill_attr:get(SkillId, SkillLv), 
			[Coef1,Coef2,Coef3,Coef4,Coef5,Coef6,Coef7,Coef8] = get_coef_by_type(BattleType,TplSkillAttr),
			%?TRACE("param ~p ~n",[[Coef1,Coef2,Coef3,Coef4,Coef5,Coef6,Coef7,Coef8]]),
			case is_crit(Aer#battle_attr.crit_ratio, Der#battle_attr.tough_ratio,0) of
				true  -> %%暴击 
					AttrDamage = cal_attr_damage(Aer,Der,Coef1),
					BreakDefendDamage  = cal_break_defend_rate(Aer,Coef2),
					FmdDamage = cal_fmd_damage(Aer,Der,Coef3,Coef4),
					CommonDamage = AttrDamage+BreakDefendDamage+FmdDamage, 
					TotalDamage = util:ceil(Aer#battle_attr.abs_damage +Coef8+CommonDamage*Coef5*math:pow(SkillLv,Coef6)*Coef7),
				%	?TRACE("AttrDamage ~p BreakDefendDamage ~p FmdDamage ~p TotalDamage ~p AbsDemage ~p~n",[AttrDamage,BreakDefendDamage,FmdDamage,TotalDamage,Aer#battle_attr.abs_damage ]),
					{?DAMAGE_TYPE_CRIT, TotalDamage};
				false->
				 	AttrDamage = cal_attr_damage(Aer,Der,Coef1),
					BreakDefendDamage  = cal_break_defend_rate(Aer,Coef2),
					FmdDamage = cal_fmd_damage(Aer,Der,Coef3,Coef4),
					CommonDamage = AttrDamage+BreakDefendDamage+FmdDamage,
					TotalDamage = util:ceil(Aer#battle_attr.abs_damage +Coef8+CommonDamage*Coef5*math:pow(SkillLv,Coef6)),
					%?TRACE("AttrDamage ~p BreakDefendDamage ~p FmdDamage ~p TotalDamage ~p AbsDemage ~p~n",[AttrDamage,BreakDefendDamage,FmdDamage,TotalDamage,Aer#battle_attr.abs_damage ]),
					{?DAMAGE_TYPE_NORMAL, TotalDamage}
			end;
		false->
			{?DAMAGE_TYPE_MISSED,0}
	end.
%%根据战斗类型获取战斗参数
get_coef_by_type(?BATTLE_TYPE_PVE,TplSkillAttr)->
	TplSkillAttr#temp_skill_attr.pve_param;
get_coef_by_type(?BATTLE_TYPE_PVP,TplSkillAttr)->
	TplSkillAttr#temp_skill_attr.pvp_param;
get_coef_by_type(_,TplSkillAttr)->
	TplSkillAttr#temp_skill_attr.pve_param.
%%计算普攻伤害
cal_attr_damage(Aer,Der,Coef1)->
	%?TRACE("Attrack ~p Dedend ~p ~n",[Aer#battle_attr.attack,Der#battle_attr.real_defense]),
	DamageVal1 = max((Aer#battle_attr.attack-Der#battle_attr.real_defense),0),
	DamageVal1*Coef1.
%%计算破防伤害
cal_break_defend_rate(Aer,Coef2)->
	Aer#battle_attr.attack * Coef2.
%%计算属攻伤害
cal_fmd_damage(Aer,Der,Coef3,Coef4)->
	{FmdDamage,FmdDefend} = case Aer#battle_attr.career of
								?CAREER_F ->  
									{Aer#battle_attr.fattack,Der#battle_attr.fdefense};
								?CAREER_M -> 
									{Aer#battle_attr.mattack,Der#battle_attr.mdefense};
								?CAREER_D -> 
									{Aer#battle_attr.dattack,Der#battle_attr.ddefense};
								_->
									{0,1}
							end,
	%?TRACE("FmdDamage ~p FmdDefend ~p ~n",[FmdDamage,FmdDefend]),
	FmdDamage*FmdDamage*Coef4/(FmdDamage+FmdDefend*Coef3).