%% Author: Administrator
%% Created:
%% Description: TODO: Add description to db_agent_pet
-module(db_agent_pet).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).

%% 加载玩家宠物
select_pet_by_uid(PlayerId) ->
	case ?DB_MODULE:select_row(pet, "*", [{uid, PlayerId}], [], [1]) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			PetInfo = list_to_tuple([pet|DataList]),
			PetInfo#pet{
						skill_list = util:bitstring_to_term(PetInfo#pet.skill_list),
						facade_list = util:bitstring_to_term(PetInfo#pet.facade_list),
						suit_list = util:bitstring_to_term(PetInfo#pet.suit_list)
					   };
		_ ->
			[]
	end .

%% 宠物改名
rename_pet(PlayerId, PetName) ->
	?DB_MODULE:update(pet, ["name"], [PetName], "uid", PlayerId).

%% 更新宠物状态
update_pet_status(PlayerId, Status) ->
	?DB_MODULE:update(pet, ["status"], [Status], "uid", PlayerId).

%% 更新宠物属攻类型
update_pet_attr_type(PlayerId, AttrType) ->
	?DB_MODULE:update(pet, ["attack_type"], [AttrType], "uid", PlayerId).

%% 幻化
update_pet_facade_type(PlayerId, Facade) ->
	?DB_MODULE:update(pet, ["current_facade"], [Facade], "uid", PlayerId).

update_pet_facadelist(PlayerId, FacadeList) ->
	NewFacadeList = util:term_to_bitstring(FacadeList),
	?DB_MODULE:update(pet, ["facade_list"], [NewFacadeList], "uid", PlayerId).

%% 增加宠物外观
update_pet_facade_list(PlayerId, FacadeList) ->
	FacadeListBin = util:term_to_bitstring(FacadeList),
	?DB_MODULE:update(pet, ["facade_list"], [FacadeListBin], "uid", PlayerId).

%% 更新宠物品阶
update_pet_quality(PlayerId, QualityLv, FailTimes) ->
	?DB_MODULE:update(pet, ["quality_lv", "fail_times"], [QualityLv, FailTimes], "uid", PlayerId).

%% 更新宠物进阶失败次数
update_pet_quality_times(PlayerId, FailTimes) ->
	?DB_MODULE:update(pet, ["fail_times"], [FailTimes], "uid", PlayerId).

%% 更新宠物成长属性
update_pet_growth(PlayerId, GrowthVal, GrowthProgress, SkillHoles) ->
	?DB_MODULE:update(pet, ["growth_lv", "growth_progress", "skill_hole"], [GrowthVal, GrowthProgress, SkillHoles], "uid", PlayerId).

%% 更新宠物资质属性
update_pet_aptitude(PlayerId, AptitudeLv, AptitudeProgress, SkillHoles) ->
	?DB_MODULE:update(pet, ["aptitude_lv", "aptitude_progress", "skill_hole"], [AptitudeLv, AptitudeProgress, SkillHoles], "uid", PlayerId).

%% 更新宠物属性
update_pet_attr(PlayerId, Attack, AttrAttack, Hit, Crit, SkillHole, Fighting) ->
	?DB_MODULE:update(pet, ["attack", "attr_attack", "hit", "crit", "skill_hole", "fighting"], [Attack, AttrAttack, Hit, Crit, SkillHole, Fighting], "uid", PlayerId).

%% 更新宠物开启技能槽总数
update_pet_skill_holes(PlayerId, SkillHoles) ->
	?DB_MODULE:update(pet, ["skill_hole"], [SkillHoles], "uid", PlayerId).

%% 更新宠物技能
update_pet_skill(PlayerId, SkillList) ->
	SkillListBin = util:term_to_bitstring(SkillList),
	?DB_MODULE:update(pet, ["skill_list"], [SkillListBin], "uid", PlayerId).

%%生成宠物添加默认值
create_pet(PetInfo) ->
	ValueList = lists:nthtail(1, tuple_to_list(PetInfo)),
    FieldList = record_info(fields, pet),
	?DB_MODULE:insert(pet, FieldList, ValueList).

%%删除宠物
del_pet(PetInfo) ->
	?DB_MODULE:delete(pet, [{uid, PetInfo#pet.uid}]).