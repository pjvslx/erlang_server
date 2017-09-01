%%--------------------------------------
%% @Module: pp_mount
%% Author:  water
%% Created: Tue Jan 29 2013
%% Description: 座骑
%%--------------------------------------
-module(db_agent_mount).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%%获取玩家座骑记录
get_mount(PlayerId) ->
    case ?DB_MODULE:select_row(mount, "*", [{uid, PlayerId}], [], [1]) of
        [] -> [];
        R  -> Mount = list_to_tuple([mount|R]),
              Mount#mount{
                            skill_list = util:bitstring_to_term(Mount#mount.skill_list),
                            fashion_list = util:bitstring_to_term(Mount#mount.fashion_list),
                            old_fashion_list = util:bitstring_to_term(Mount#mount.old_fashion_list)
                         }
    end.

%%新建玩家座骑记录
insert_mount(Mount) ->
    MountForDB = Mount#mount{
                        skill_list = util:term_to_string(Mount#mount.skill_list),
                        fashion_list = util:term_to_string(Mount#mount.fashion_list),
                        old_fashion_list = util:term_to_string(Mount#mount.old_fashion_list)
                       },
    ValueList = lists:nthtail(1, tuple_to_list(MountForDB)),
    FieldList = record_info(fields, mount),
    ?DB_MODULE:insert(mount, FieldList, ValueList).

%%更新座骑记录
update_mount(Mount) ->
    MountForDB = Mount#mount{
						fashion = Mount#mount.fashion,
                        skill_list = util:term_to_string(Mount#mount.skill_list),
                        fashion_list = util:term_to_string(Mount#mount.fashion_list),
                        old_fashion_list = util:term_to_string(Mount#mount.old_fashion_list)
                       },
    [_Uid|ValueList] = lists:nthtail(1, tuple_to_list(MountForDB)),
    [uid|FieldList] = record_info(fields, mount),
    ?DB_MODULE:update(mount, FieldList, ValueList, uid, Mount#mount.uid).
%%更新座骑技能
update_mount_skill(Mount)->
	SkillList = util:term_to_string(Mount#mount.skill_list),
	?DB_MODULE:update(mount,[{skill_list, SkillList}, {skill_times, Mount#mount.skill_times}],[{uid, Mount#mount.uid}]).
%%更新座骑技能以及等级
update_mount_skill_level(Mount) ->
	SkillList = util:term_to_string(Mount#mount.skill_list),
	FashionList = util:term_to_string(Mount#mount.fashion_list),
	?DB_MODULE:update(mount,[{skill_list, SkillList}, {skill_times, Mount#mount.skill_times},
							 {level, Mount#mount.level},
							 {star, Mount#mount.star},
							 {exp, Mount#mount.exp},
							 {fashion,Mount#mount.fashion},
							 {fashion_list,FashionList}],[{uid, Mount#mount.uid}]).

%%更新座骑技能升级次数
update_mount_skill_times(Mount) ->
    ?DB_MODULE:update(mount,[{skill_times, Mount#mount.skill_times}],[{uid, Mount#mount.uid}]).

%%更新座骑状态
update_mount_state(Mount) ->
    ?DB_MODULE:update(mount,[{state, Mount#mount.state},{fashion,Mount#mount.fashion}],[{uid, Mount#mount.uid}]).

%%更新座骑的等级,经验,星级
update_mount_level(Mount) ->
		FashionList = util:term_to_string(Mount#mount.fashion_list),
    ?DB_MODULE:update(mount,[{level, Mount#mount.level},
                             {star, Mount#mount.star},
                             {exp, Mount#mount.exp},
							 {fashion,Mount#mount.fashion},
							 {fashion_list,FashionList}
                            ],[{uid, Mount#mount.uid}]).

%%更新座骑
update_mount_force(Mount) ->
    ?DB_MODULE:update(mount,[{force, Mount#mount.force}],[{uid, Mount#mount.uid}]).

%%更新座骑使用的外观
update_mount_fashion(Mount) ->
    Fashion = Mount#mount.fashion,
    ?DB_MODULE:update(mount,[{fashion, Fashion}],[{uid, Mount#mount.uid}]).

%%更新座骑幻化
update_mount_fashion_list(Mount) ->
    FashionList = util:term_to_string(Mount#mount.fashion_list),
    OldFashionList = util:term_to_string(Mount#mount.old_fashion_list),
    ?DB_MODULE:update(mount,[{fashion_list, FashionList}, {old_fashion_list, OldFashionList}],[{uid, Mount#mount.uid}]).

%%更新座骑星级,经验
update_mount_exp(Mount) ->
    Star = Mount#mount.star,
    Exp = Mount#mount.exp,
    ?DB_MODULE:update(mount,[{star, Star}, {exp, Exp}],[{uid, Mount#mount.uid}]).

%%获取所有坐骑外观
get_all_mount_facade()->
	 ?DB_MODULE:select_all(temp_mount_attr,"select distinct mount_model from temp_mount_attr").

get_level_start_info_by_facade(Facade)->
	Sql = io_lib:format("select level,star from temp_mount_attr where mount_model=~p limit 0,1", [Facade]), 
	?DB_MODULE:select_all(temp_mount_attr,Sql).

