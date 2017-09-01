%%%--------------------------------------
%%% @Module  : db_agent_system_config
%%% @Author  : water
%%% @Created : 2013.01.25
%%% @Description:  玩家游戏系统配置
%%%--------------------------------------
-module(db_agent_system_config).

%%
%% Include files
%%

%%
%% Exported Functions
%%

-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%%
%% API Functions
%%
%%查询玩家的游戏系统配置数据
get_system_config(PlayerId) ->
    case ?DB_MODULE:select_row(system_config, "*", [{uid, PlayerId}], [], [1]) of
        [] -> [];
        SysConf -> list_to_tuple([system_config|SysConf])
    end.

%%初始化数据库玩家系统配置数据
insert_system_config(SysConfig) ->
    ValueList = lists:nthtail(1, tuple_to_list(SysConfig)),
    FieldList = record_info(fields, system_config),
    ?DB_MODULE:insert(system_config, FieldList, ValueList).

%%更新玩家数据库系统配置数据
update_system_config(SysConfig) ->
    [_|ValueList] = lists:nthtail(1,tuple_to_list(SysConfig)),
    [_|FieldList] = record_info(fields, system_config),
    ?DB_MODULE:update(system_config, FieldList, ValueList, "uid", SysConfig#system_config.uid).

    


