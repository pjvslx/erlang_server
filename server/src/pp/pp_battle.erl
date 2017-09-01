%%%-------------------------------------------------------------------
%%% Module  : pp_battle
%%% Author  : 
%%% Description : 战斗
%%%-------------------------------------------------------------------
-module(pp_battle).

%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").


%%--------------------------------------------------------------------
%% External exports
-export([handle/3]).

%% 发动攻击 - 玩家VS怪 
%% Id 怪物ID
%% SkillId 技能ID
%% handle(20001, PlayerStatus, [MonId, SkillId, SAction]) ->
%% 	case tool:is_operate_ok(lists:concat([pp_20001]), 700) of
%% 		true ->
%% 			case lib_battle:check_fightable(PlayerStatus,SkillId) of 
%% 				[true,NewStatus] ->
%% 					mod_scene:start_player_attack(NewStatus#player.other#player_other.pid_scene, 
%% 												  NewStatus#player.id, MonId, ?ELEMENT_MONSTER, SkillId, SAction) ;
%% 				[false,Code] ->
%% 					lib_battle:battle_fail(Code, PlayerStatus, ?ELEMENT_PLAYER)
%% 			end;
%% 		false ->
%% 			ok
%% 	end ;
%% 
%% %% 发动攻击 - 玩家VS玩家
%% %% DerId 被击方ID
%% %% SkillId 技能ID
%% handle(20002, PlayerStatus, [DerId, SkillId]) ->
%% 	?TRACE("20002, DerId:~p, SkillId:~p ~n", [DerId, SkillId]),
%% %% 	DerBattleResult = [[1, DerId, 100, 101, 10, 0, 0]],
%% %% 	{ok, BinData1} = pt_20:write(20001, [PlayerStatus#player.id, PlayerStatus#player.hit_point, PlayerStatus#player.magic, SkillId, 1, 50, 52, DerBattleResult]),
%% %% 	lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData1);
%% 	case PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 andalso PlayerStatus#player.id /= DerId of
%% 		true ->
%% 			% 检查技能合法性
%% %% 			case lib_skill:check_skill_usable(PlayerStatus, SkillId) of
%% %% 				true ->
%% 					mod_scene:start_player_attack(PlayerStatus#player.other#player_other.pid_scene, PlayerStatus#player.id, DerId, ?ELEMENT_PLAYER, SkillId);
%% %% 				false ->
%% %% 					lib_battle:battle_fail(6, PlayerStatus, ?ELEMENT_PLAYER)
%% %% 			end;				
%% 		false ->
%% 			?TRACE("20002, ac hp <= 0 or same player AerId:~p DerId:~p, SkillId:~p ~n", [PlayerStatus#player.id, DerId, SkillId]),
%% 			skip
%% 	end;

%% 发动攻击 - 宠物VS怪 
%% Id 怪物ID
%% SkillId 技能ID
handle(20004, PlayerStatus, [MonId, SkillId,SessionId]) -> 
	?TRACE(" =====pp_battle 20004,playerid:~p  MonId:~p, SkillId:~p ~n", [PlayerStatus#player.id, MonId, SkillId]),
	case tool:is_operate_ok(pp_20004, 700) andalso PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 of
		true -> 
			case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
				true ->    
					mod_dungeon:start_pet_attack(PlayerStatus, MonId, SkillId,SessionId) ;
				false ->    
					mod_scene:start_pet_attack(PlayerStatus#player.other#player_other.pid_scene, PlayerStatus#player.id, MonId, ?ELEMENT_MONSTER, SkillId,SessionId)
			end ; 
		false ->
			skip
	end ;
 
%% 开启怪物AI 
%% Id 怪物ID
handle(20009, PlayerStatus, [MonId]) ->
    Monster = lib_mon:get_monster(MonId),
    if
        is_record(Monster,temp_mon_layout) ->
            Pid = Monster#temp_mon_layout.pid,
            Pid ! {'scene_create'},
            SceneId = PlayerStatus#player.scene,
            case lib_scene:is_dungeon_scene(SceneId) of
                true ->
                    Pid ! {'player_showing_up',PlayerStatus#player.other#player_other.pid_dungeon,util:longunixtime()},
                    Pid ! {'player_coming',Monster,PlayerStatus#player.other#player_other.pid_scene,PlayerStatus};%%让怪物主动进入战斗
                false ->
                    Pid ! {'player_showing_up',PlayerStatus#player.other#player_other.pid_scene,util:longunixtime()},
                    Pid ! {'player_coming',Monster,PlayerStatus#player.other#player_other.pid_scene,PlayerStatus}%%让怪物主动进入战斗
            end;
        true ->
            skip
    end;


%% 发动攻击 - 宠物VS玩家
%% DerId 被击方ID
%% SkillId 技能ID
%% handle(20007, PlayerStatus, [DerId, SkillId,SessionId]) ->
%% 	?TRACE("20007, playerid:~p, DerId:~p, SkillId:~p ~n", [PlayerStatus#player.id, DerId, SkillId]),
%% 	case PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 andalso PlayerStatus#player.id /= DerId of
%% 		true ->
%% 			% 检查技能合法性
%% %% 			case lib_skill:check_skill_usable(PlayerStatus, SkillId) of
%% %% 				true ->    
%% 					mod_scene:start_pet_attack(PlayerStatus#player.other#player_other.pid_scene, PlayerStatus#player.id, DerId, ?ELEMENT_PLAYER, SkillId,SessionId);
%% %% 				false ->
%% %% 					lib_battle:battle_fail(6, PlayerStatus, ?ELEMENT_PLAYER)
%% %% 			end;				
%% 		false ->
%% 			?TRACE("20007, ac hp <= 0 or attack self or same player AerId:~p DerId:~p, SkillId:~p ~n", [PlayerStatus#player.id, DerId, SkillId]),
%% 			skip
%% 	end;

handle(_Cmd, _Status, _Data) ->
	?TRACE("[Battle Proto Error]cmd: ~p",[_Cmd]),
    {error, "pp_battle no match"}.
