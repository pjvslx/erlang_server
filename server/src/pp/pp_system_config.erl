%%%--------------------------------------
%%% @Module  : pp_system_config
%%% @Author  : water
%%% @Created : 2013.01.25
%%% @Description:  玩家游戏系统配置
%%%--------------------------------------
-module(pp_system_config).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

%%
%% Exported Functions
%%
-export([handle/3]).

%% -----------------------------------------------------------------
%% 34001 读取设置信息
%% -----------------------------------------------------------------
handle(34001, Status, _) ->
    SysConfig = lib_system_config:get_system_config(Status#player.id),
	{ok, BinData} = pt_34:write(34001, [SysConfig#system_config.shield_role, 
                                        SysConfig#system_config.shield_skill,
                                        SysConfig#system_config.shield_rela,
                                        SysConfig#system_config.shield_team,
                                        SysConfig#system_config.shield_chat,
                                        SysConfig#system_config.fasheffect,
                                        SysConfig#system_config.music,
                                        SysConfig#system_config.soundeffect
                                       ]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);

handle(34002, Status, Data) ->
    {ok, lib_system_config:update_system_config(Status, Data)};

handle(34010, Status, _) ->
    State = case lib_world_level:get_state() of 
                true -> 1;
                _    -> 0
            end,
    {ok, BinData} = pt_34:write(34010, [State, 
                                        data_config:get_world_config(min_world_lv),
                                        data_config:get_world_config(exp_min_lv),
                                        data_config:get_world_config(exp_max_lv),
                                        util:floor(data_config:get_world_config(percent)*100)
                                       ]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
    
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERROR_MSG("pp_system_config no match", []),
    {error, "pp_system_config no match"}.
