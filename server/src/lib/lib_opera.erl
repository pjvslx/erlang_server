-module(lib_opera).

-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").  

-export([
        	load_opera/1,
			get_opera/1,
			save_opera/1,
			update_opera/1,
			notify_opera_dialogue/3,
			notify_opera_animation/3,
			stop_scene_mon_ai/1,
			start_scene_mon_ai/1
         ]).

load_opera(UId) ->
	OperaRcd2 = case get_opera(UId) of
			OperaRcd when is_record(OperaRcd,?ETS_OPERA) ->
				OperaRcd ;
			_ ->
				db_agent_opera:select_opera(UId) 
	end ,
	ets:insert(?ETS_OPERA, OperaRcd2),
	ok.

get_opera(UId) ->
	case ets:lookup(?ETS_OPERA, UId) of
		[] ->
			[] ;
		[OperaRcd|_] ->
			OperaRcd
	end .

save_opera(OperaRcd) ->
	ets:insert(?ETS_OPERA, OperaRcd) .

update_opera(UId) ->
	case get_opera(UId) of
		OperaRcd when is_record(OperaRcd,?ETS_OPERA) ->
			ets:delete(?ETS_OPERA, UId) ,
			db_agent_opera:update_opera(OperaRcd) ;
		_ ->
			skip
	end.

%%通知前端播放剧情对话
notify_opera_dialogue(UId,PidSend,OperaId) ->
	case get_opera(UId) of
		OperaRcd when is_record(OperaRcd,?ETS_OPERA) ->
			case lists:member(OperaId, OperaRcd#opera.operaDialogue) of
				false -> 
					Status = lib_player:get_player(UId),
					lib_leader:open_func(UId,3,OperaId),
					OperaRcd2 = OperaRcd#opera{operaDialogue = OperaRcd#opera.operaDialogue ++ [OperaId]},
					save_opera(OperaRcd2),
					{ok,DataBin} = pt_12:write(12031, [OperaId]) ,
					lib_send:send_to_sid(PidSend, DataBin),
					stop_scene_mon_ai(UId),
					true;
				_ ->
					false
			end;
		_ ->
			db_agent_opera:select_opera(UId), 
			false
	end.

%%通知前端播放剧情
notify_opera_animation(UId,PidSend,OperaId) ->
	case get_opera(UId) of
		OperaRcd when is_record(OperaRcd,?ETS_OPERA) ->
			case lists:member(OperaId, OperaRcd#opera.operaAnimation) of
				false -> 
					OperaRcd2 = OperaRcd#opera{operaAnimation = OperaRcd#opera.operaAnimation ++ [OperaId]},
					save_opera(OperaRcd2), 
%% 					{ok,DataBin} = pt_23:write(23005, [OperaId]) ,
					{ok,DataBin} = pt_12:write(12032, [OperaId]) ,
					lib_send:send_to_sid(PidSend, DataBin),
					true;
				_ ->
					false
			end;
		_ ->
			db_agent_opera:select_opera(UId), 
			false
	end.

stop_scene_mon_ai(UId) ->
	case lib_scene:get_scene_player(UId) of
		Status when is_record(Status,player) ->
			case lib_scene:is_dungeon_scene(Status#player.scene) of
				true ->
					mod_dungeon:stop_scene_mon_ai(Status#player.other#player_other.pid_dungeon,UId);
				false ->
					%%mod_scene:stop_scene_mon_ai(Status#player.other#player_other.pid_scene,UId)
					skip
			end;
		_ ->
			skip
	end.

start_scene_mon_ai(UId) ->
	case lib_scene:get_scene_player(UId) of
		Status when is_record(Status,player) ->
			case lib_scene:is_dungeon_scene(Status#player.scene) of
				true ->
					mod_dungeon:start_scene_mon_ai(Status#player.other#player_other.pid_dungeon,UId);
				false ->
					%%mod_scene:start_scene_mon_ai(Status#player.other#player_other.pid_scene,UId)
					skip
			end;
		_ ->
			skip
	end.
