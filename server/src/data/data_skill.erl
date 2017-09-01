%%%------------------------------------------------    
%%% File    : data_skill.erl    
%%% Author  : water
%%% Desc    : 技能参数
%%            技能模板参考tpl_skill.erl
%%%------------------------------------------------        
-module(data_skill).     
-compile(export_all).

-include("common.hrl").
-include("record.hrl").

%% 技能ID及等级在玩家结构player.other#player_other.skill_list
%%获取玩家默认技能ID, 等级 
get_default_skill(Career) ->
    case Career of  
        ?CAREER_F -> [{1,1},{36,1}];
        ?CAREER_M -> [{43,1},{44,1}];  
        ?CAREER_D -> [{50,1},{51,1}];
		?CAREER_PET -> [{6,1}]
    end.
  
%%获取攻击目标类型
get_target_type(SkillId) ->
	Skill = tpl_skill:get(SkillId),
    Skill#temp_skill.target_type .

%% %%获取技能类型
%% get_type(SkillId) -> 
%%     Skill = tpl_skill:get(SkillId),
%%     Skill#temp_skill.type.

%%判断技能是否普攻
is_normal_attr(SkillId) -> 
	io:format("is_normal_attr~p ~n",[SkillId]),
    Skill = tpl_skill:get(SkillId), 
    Skill#temp_skill.is_normal_attr =:=1.

%% %%技能绝对伤害值  
%% get_abs_damage(SkillId, SkillLv) ->
%%     SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
%%     {SkillAttr#temp_skill_attr.abs_damage,1}.

%%技能释放距离
get_skill_distance(SkillId) ->
    Skill = tpl_skill:get(SkillId),
    Skill#temp_skill.distance.

%%技能释放AOE距离及数量
%%返回格式 {AOE距离, AOE目标数量}
get_skill_aoe(SkillId) ->
    Skill = tpl_skill:get(SkillId),
    {Skill#temp_skill.aoe_dist, Skill#temp_skill.aoe_tnum}.

%% 获取技能的攻击距离和数量
get_attack_dist(SkillId) ->
	Skill = tpl_skill:get(SkillId) , 
			{Skill#temp_skill.aoe_dist, Skill#temp_skill.aoe_tnum}  .

%% %%返回技能是否使用连击点
%% %%返回true/false
%% get_combopoint_usage(SkillId) ->
%%     Skill = tpl_skill:get(SkillId),
%%     Skill#temp_skill.use_combopoint >= 1.

%%使用技能需要的法力值,怒气值
%%返回格式: {法力值,怒气值}
%% get_skill_cost(SkillId, SkillLv) ->
%%     SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
%%     {SkillAttr#temp_skill_attr.cost_magic, SkillAttr#temp_skill_attr.cost_anger}.

%%技能释放后CD时间
get_skill_cd(SkillId) ->
    Skill = tpl_skill:get(SkillId),
    Skill#temp_skill.cd_all.

%%技能升级需要铜钱及历练值
get_upgrade_cost(SkillId, SkillLv) ->
	%%     SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
	%%     {SkillAttr#temp_skill_attr.cost_coin, SkillAttr#temp_skill_attr.cost_emp}.
	ok .

%%获取学习技能所需要玩家等级
get_learn_level(SkillId, Lv) ->
    Skill = tpl_skill_attr:get(SkillId, Lv),
    Skill#temp_skill_attr.learn_level.

%%获取学习技能所需要学习的技能列表
%%返回格式为[{SkillId1, Level1},...]
get_require_skill_list(SkillId, Lv) ->
    Skill = tpl_skill_attr:get(SkillId, Lv),
    Skill#temp_skill_attr.require_list.

%%返回技能有吟唱时间
get_sing(SkillId) ->
    Skill = tpl_skill:get(SkillId),
    {Skill#temp_skill.sing_break, Skill#temp_skill.sing_time}.
%%技能是否受公共cd影响
get_is_cd_all(SkillId)->
	  Skill = tpl_skill:get(SkillId),
	  Skill#temp_skill.is_cd_all.
