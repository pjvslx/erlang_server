
-module(db_agent_skill).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%% 获取玩家技能记录
get_skill(PlayerId) ->  
    case ?DB_MODULE:select_row(skill, "*", [{uid, PlayerId}], [], [1]) of
        [] -> [];
        R  -> Skill = list_to_tuple([skill|R]),
              Skill#skill{
                            skill_list = util:bitstring_to_term(Skill#skill.skill_list),
                            cur_skill_list = util:bitstring_to_term(Skill#skill.cur_skill_list),
							skill_point = util:bitstring_to_term(Skill#skill.skill_point)
                       	    }
    end.

%% 新建玩家技能记录，并返回技能记录Record
insert_skill(Skill) ->  
	SkillForDB = Skill#skill{
							 skill_list = util:term_to_string(Skill#skill.skill_list),
							 cur_skill_list = util:term_to_string(Skill#skill.cur_skill_list),
							 skill_point =  util:term_to_string(Skill#skill.skill_point)
							},
	ValueList = lists:nthtail(1, tuple_to_list(SkillForDB)),
	FieldList = record_info(fields, skill),
	?DB_MODULE:insert(skill, FieldList, ValueList).

%% 更新技能学习记录
update_skill(Skill) ->
    SkillForDB = Skill#skill{
                             skill_list = util:term_to_string(Skill#skill.skill_list),
                             cur_skill_list = util:term_to_string(Skill#skill.cur_skill_list),
							 skill_point =  util:term_to_string(Skill#skill.skill_point)
                            },
    [_Uid|ValueList] = lists:nthtail(1, tuple_to_list(SkillForDB)),
    [uid|FieldList] = record_info(fields, skill),
    ?DB_MODULE:update(skill, FieldList, ValueList, uid, Skill#skill.uid).

