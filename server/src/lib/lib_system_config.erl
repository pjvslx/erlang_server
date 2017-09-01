%%%--------------------------------------
%%% @Module  : lib_system_config
%%% @Author  : water
%%% @Created : 2013.01.25
%%% @Description:  玩家游戏系统配置
%%%--------------------------------------
-module(lib_system_config).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%%玩家进程初始化调用
%%放入进程字典
init_system_config(Status) ->
%%	io:format("init_system_config~p ~n", [Status]),  
	SysConfig = get_system_config(Status#player.id),
  	put(system_config, SysConfig),
    %%更新玩家相应状态
    Status.

%%获取配置(玩家进程调用)
get_system_config(PlayerId) ->
    case get(system_config) of
        SysConfig when is_record(SysConfig, system_config) ->
            SysConfig;
        _Other1 ->
	        case db_agent_system_config:get_system_config(PlayerId) of
                SysConfig when is_record(SysConfig, system_config) ->
                    SysConfig;
	        	_Other2 ->
                    SysConfig = #system_config{uid = PlayerId},
	        		db_agent_system_config:insert_system_config(SysConfig),
                    SysConfig
	        end
    end.

%%更新玩家配置数据(限玩家进程调用)
update_system_config(Status, Data) ->
    case Data of
        [ShieldRole, ShieldSkill, ShieldRela, ShieldTeam, ShieldChat, FashEffect, Music, SoundEffect] ->
            SysConfig = get_system_config(Status#player.id),
            NewSysConfig = SysConfig#system_config{
                                            shield_role = ShieldRole,
                                            shield_skill = ShieldSkill,
                                            shield_rela = ShieldRela,
                                            shield_team = ShieldTeam,
                                            shield_chat = ShieldChat,  
                                            fasheffect = FashEffect,
                                            music = Music,                             
                                            soundeffect = SoundEffect
                                         },
            put(system_config, NewSysConfig),
			spawn(fun() -> save_system_config() end) ,
            %%更新玩家相应状态
            Status;
        _Other ->
            Status
    end.

%%下线玩家配置(限玩家进程调用)
save_system_config() ->
	SysConfig = get(system_config),
	db_agent_system_config:update_system_config(SysConfig).






