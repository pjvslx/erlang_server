-module(lib_dungeon_exp).
-include("common.hrl").
-include("debug.hrl").
-include("record.hrl").
-compile(export_all).

-define(TRIGGER_ANIMATION,1).
-define(TRIGGER_DIE_ACTION,2).
-define(TRIGGER_BLOCK,3).
-define(TRIGGER_DIALOGUE,4).
-define(TRIGGER_MONSTER,5).
-define(TRIGGER_TALK,6).
-define(TRIGGER_STOP_ACTION,7).
-define(TRIGGER_MOVE_CAMERA,8).
-define(TRIGGER_ADD_OBJ,9).
-define(TRIGGER_MOVE_OBJ,10).
-define(TRIGGER_SHAKE,11).
-define(TRIGGER_NPC_FLY,12).
-define(TRIGGER_END_DUNGEON,13).
-define(TRIGGER_SCALE_CAMERA,14).

-define(EXP_LEVEL,99).%%特定等级，待配置
-define(EXP_MOUNT_STATE,1002).%%特定坐骑外形id,待配置
-define(EXP_PET_FACADE,2005).%%特定宠物外形id,待配置

enter_dungeon(Status,DunId) ->
	%%DunId->特殊副本
	case DunId of
		?EXP_DUNGEON ->
			?TRACE("[lib_dungeon_exp]::enter_dungeon::~p~n",[DunId]),
			gen_server:cast(Status#player.other#player_other.pid, enter_dungeon_exp);
		_ ->
			skip
	end.

leave_dungeon(Status,PreAttr) ->
	%%DunId->特殊副本
	DunId = Status#player.scene div 100,
	case DunId of
		?EXP_DUNGEON ->
			?TRACE("[lib_dungeon_exp]::leave_dungeon::~p~n",[DunId]),
			gen_server:cast(Status#player.other#player_other.pid, {leave_dungeon_exp,PreAttr}),
			send_level_info(Status,Status#player.level);
		_ ->
			skip
	end.

check_save_in_dungeon_exp(Status) ->
	case Status#player.scene div 100 =:= ?EXP_DUNGEON of
		true ->
			case lib_dungeon:get_dungeon_daily(Status#player.id) of
				DunRcd when is_record(DunRcd,dungeon_daily) andalso DunRcd#?ETS_DUNGEON_DAILY.sid > 0 ->
					case DunRcd#?ETS_DUNGEON_DAILY.pre_attr of
						[Level] ->
							Status2 = lib_player:join_2_level(Status,Level,false),
							%%lib_skill:clean_all_skill(Status2),
							{_,SkillPointTotal} =  Status#player.other#player_other.skill_point,
							NewSkillList = data_skill:get_default_skill(Status#player.career),
							NewSkill = #skill{
								uid = Status#player.id,
								skill_point = {0,SkillPointTotal},
								cur_skill_list = NewSkillList,
								skill_list = NewSkillList
							},
							db_agent_skill:update_skill(NewSkill),
							Status2;
						_ ->
							Status
					end;
				_ ->
					Status
			end;
		false ->
			Status
	end.

get_pet_facade(Status) ->
	DunId = Status#player.scene div 100,
	case DunId of
		?EXP_DUNGEON ->
			?EXP_PET_FACADE; 
		_ ->
			Status#player.other#player_other.pet_facade
	end.

get_mount_state(Status) ->
	DunId = Status#player.scene div 100,
	case DunId of
		?EXP_DUNGEON ->
			?EXP_MOUNT_STATE; 
		_ ->
			Status#player.other#player_other.mount_fashion
	end.

get_equip_state(Status) ->
	DunId = Status#player.scene div 100,
	case DunId of
		?EXP_DUNGEON ->
			[Weapon, Armor, Fashion, WwaponAcc, Wing] = Status#player.other#player_other.equip_current,
			Weapon2 = util:string_to_term("22110" ++ util:term_to_string(Status#player.career) ++ "204"),  %%特定武器id,待配置
			[Weapon2,Armor,Fashion,WwaponAcc,Wing];
		_ ->
			Status#player.other#player_other.equip_current
	end.

send_level_info(Status,Level) ->
	ExpNextLevel = data_player:next_level_exp(Status#player.career, Status#player.level), 
	Data = [ Status#player.force,
		Status#player.level,
		Level,
		Status#player.exp,
		ExpNextLevel,   
		Status#player.battle_attr#battle_attr.hit_point,
		Status#player.battle_attr#battle_attr.hit_point_max,
		Status#player.battle_attr#battle_attr.combopoint,
		Status#player.battle_attr#battle_attr.combopoint_max,
		Status#player.battle_attr#battle_attr.energy#energy.energy_val,
		Status#player.battle_attr#battle_attr.energy#energy.max_energy,
		Status#player.battle_attr#battle_attr.anger,
		Status#player.battle_attr#battle_attr.anger_max,
		Status#player.battle_attr#battle_attr.attack,
		Status#player.battle_attr#battle_attr.defense,
		Status#player.battle_attr#battle_attr.abs_damage,
		Status#player.battle_attr#battle_attr.fattack,
		Status#player.battle_attr#battle_attr.mattack,
		Status#player.battle_attr#battle_attr.dattack,
		Status#player.battle_attr#battle_attr.fdefense,
		Status#player.battle_attr#battle_attr.mdefense,
		Status#player.battle_attr#battle_attr.ddefense,
		Status#player.battle_attr#battle_attr.speed,
		Status#player.battle_attr#battle_attr.attack_speed,
		Status#player.battle_attr#battle_attr.hit_ratio,
		Status#player.battle_attr#battle_attr.dodge_ratio,
		Status#player.battle_attr#battle_attr.crit_ratio,
		Status#player.battle_attr#battle_attr.tough_ratio
	],
	{ok, BinData} = pt_13:write(13007, Data),
	lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

notify_level_up(Status) ->
	DunId = Status#player.scene div 100,
	case DunId of
		?EXP_DUNGEON ->
			?TRACE("[lib_dungeon_exp]::notify_level_up::~p~n",[DunId]),
			send_level_info(Status,?EXP_LEVEL); 
		_ ->
			skip
	end.

%%物件触发begin
%%1直接触发
%%2剧情结束
%%3副本怪物死亡
trigger_dungeon_object(Status,DunObjId,EventType,TrigState) ->
	case get_obj_state(DunObjId) of
		ObjState when ObjState > 0 ->
			skip;
		_ ->
			do_next_state(DunObjId)
	end,
	check_and_action(Status,DunObjId,EventType,TrigState).

trigger_call_back(Status,ConditionType) ->
	case Status of 
		Player when is_record(Player,player) ->
			case lib_dungeon:get_dungeon_daily(Player#player.id) of
				DunRcd when is_record(DunRcd,dungeon_daily) ->
					case tpl_dungeon_obj:get_by_dun_id(DunRcd#?ETS_DUNGEON_DAILY.sid) of
						DunObjList when length(DunObjList) > 0 ->
							DunObjIds = lists:map(fun(T) -> T#temp_dungeon_obj.obj_id end, DunObjList),
							?TRACE("trigger_call_back::DunObjIds~p~n",[DunObjIds]),
							lists:map(fun(DunObjId) -> 
									case get_obj_state(DunObjId) of
										ObjState when ObjState > 0 ->
							  				check_and_action(Player,DunObjId,ConditionType,0);
										_ ->
											skip
									end
							end,lists:usort(DunObjIds));
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

check_and_action(Status,DunObjId,EventType,TrigState)->
	DunRcd = lib_dungeon:get_dungeon_daily(Status#player.id) ,
	ObjState = get_obj_state(DunObjId),
	%%触发完成状态
	case ObjState - TrigState =< 1 orelse TrigState =:= 0 of
		true ->
		case tpl_dungeon_obj:get(DunRcd#?ETS_DUNGEON_DAILY.sid,DunObjId,ObjState) of
			EventState when is_record(EventState,temp_dungeon_obj) ->
				Flag = case EventState#temp_dungeon_obj.condition of
					?CONDITION_NULL ->
						EventType =:= ?CONDITION_NULL orelse EventType =:= ?CONDITION_NULLEND;
					?CONDITION_END ->
						EventType =:= ?CONDITION_END orelse EventType =:= ?CONDITION_NULLEND;
					?CONDITION_MON_DEAD ->
						case EventType =:= ?CONDITION_MON_DEAD of 
							true ->
								CheckMonList = EventState#temp_dungeon_obj.condition_param,
								MonIds = lists:map(fun(M) ->
										 			M#temp_mon_layout.monid
											end,lib_mon:get_monsters()),
								not lists:any(fun({DunObjId2,Num}) -> lists:member(DunObjId2, MonIds) end, CheckMonList);
								%%TODO:怪物死亡数量
							false ->
								false
						end;
					_ ->
						false
				end,
				case Flag of
					true ->
						do_action(Status,DunObjId,EventState);
					false ->
						skip
				end;
			_ ->
				skip
		end;
		false ->
			skip
	end.
	
do_action(Status,DunObjId,EventState) ->
	put(next_trigger_type,?CONDITION_NULL),
	ObjState = get_obj_state(DunObjId),
	case EventState#temp_dungeon_obj.event of
		?TRIGGER_ANIMATION ->
			case EventState#temp_dungeon_obj.event_param of 
				[ObjId,ActName,IsForever] ->
					%%{ok,DataBin} = pt_23:write(23041, [DunObjId,?TRIGGER_ANIMATION]) ,
					{ok,DataBin} = pt_23:write(23044, [DunObjId,ObjState,ObjId,IsForever,ActName]) ,
					?TRACE("TRIGGER_ANIMATION::23044~n"),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin),
					case IsForever =:= 1 of
						false ->
							put(next_trigger_type,?CONDITION_NULLEND);
						true ->
							skip
					end;
				_ ->
					skip
			end;
		?TRIGGER_DIE_ACTION ->
			case EventState#temp_dungeon_obj.event_param of 
				[ObjId] ->
					{ok,DataBin} = pt_23:write(23041, [DunObjId,ObjState,ObjId,?TRIGGER_DIE_ACTION]) ,
					?TRACE("TRIGGER_DIE_ACTION::23041~p~n",[ObjId]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin),
					put(next_trigger_type,?CONDITION_NULLEND);
				_ ->
					skip
			end;
		?TRIGGER_BLOCK ->
			case EventState#temp_dungeon_obj.event_param of 
				[ObjId] ->
					{ok,DataBin} = pt_23:write(23041, [DunObjId,ObjState,ObjId,?TRIGGER_BLOCK]) ,
					?TRACE("TRIGGER_BLOCK::23041::~p~n",[ObjId]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin),
					put(next_trigger_type,?CONDITION_NULLEND);
				_ ->
					skip
			end;
		?TRIGGER_DIALOGUE ->
			case EventState#temp_dungeon_obj.event_param of
				[DialogueId] ->
					case lib_opera:notify_opera_dialogue(Status#player.id,Status#player.other#player_other.pid_send,DialogueId) of
						false ->
							put(next_trigger_type,?CONDITION_NULLEND);
						true ->
							skip
					end;
				_ ->
					skip
			end;
		?TRIGGER_MONSTER ->
			%%lib_dungeon_monster:load_monster(Status#player.scene,EventState#temp_dungeon_obj.event_param) ,
			lib_dungeon_monster:create_monsters(EventState#temp_dungeon_obj.event_param,Status) ,
			MonsterList = lib_mon:get_monsters(),
			NewMonsterList = lists:map(fun(M) ->
						  			{M#temp_mon_layout.x,
									 M#temp_mon_layout.y,
									 M#temp_mon_layout.monid}
				 					end , MonsterList) ,  
			DunRcd = lib_dungeon:get_dungeon_daily(get(uid)) ,
			NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{monsters = NewMonsterList} ,
			lib_dungeon:save_dungeon_daily(NewDunRcd),
			?TRACE("TRIGGER_MONSTER::12002~p~n",[NewMonsterList]),
			{ok,DataBin} = pt_12:write(12002, [DunRcd#?ETS_DUNGEON_DAILY.sid,[],lib_mon:get_monsters(),[]]) ,
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin),
			put(next_trigger_type,?CONDITION_NULLEND);
		?TRIGGER_TALK ->	
			case EventState#temp_dungeon_obj.event_param of 
				[DiaId,Sec] ->
					{ok,DataBin} = pt_23:write(23045, [DunObjId,ObjState,DiaId,Sec]) ,
					?TRACE("TRIGGER_TALK::23045::DunObjId::~p~n:DiaId::~p~n",[DunObjId,DiaId]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
					%%erlang:send_after(Sec,self(),{'trigger_dungeon_state',Status,DunObjId,?CONDITION_NULLEND,EventState#temp_dungeon_obj.action});
				_ ->
					skip
			end;
		?TRIGGER_STOP_ACTION ->
			case EventState#temp_dungeon_obj.event_param of 
				[StopSec] ->
					{ok,DataBin} = pt_23:write(23046, [DunObjId,ObjState,StopSec]) ,
					?TRACE("TRIGGER_STOP_ACTION::23046~n"),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
				_ ->
					skip
			end;
		?TRIGGER_MOVE_CAMERA ->
			case EventState#temp_dungeon_obj.event_param of 
				[PosX,PosY,Speed,StopSec] ->
					?TRACE("TRIGGER_MOVE_CAMERA::23047~n"),
					{ok,DataBin} = pt_23:write(23047, [DunObjId,ObjState,PosX,PosY,Speed,StopSec]) ,
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin) ;
				_ ->
					skip
			end;
		?TRIGGER_ADD_OBJ ->
			case EventState#temp_dungeon_obj.event_param of 
				[ObjId] ->
					case lib_dungeon:get_dungeon_daily(get(uid)) of
						DunRcd when is_record(DunRcd,dungeon_daily) ->
							ObjState2 = DunRcd#?ETS_DUNGEON_DAILY.obj_state,
							NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{obj_state = ObjState2 ++ [{ObjId,0}]},
							lib_dungeon:save_dungeon_daily(NewDunRcd);
						_ ->
							skip
					end,
					{ok,DataBin} = pt_23:write(23048, [DunObjId,ObjState,ObjId]) ,
					?TRACE("TRIGGER_ADD_OBJ::23048~n"),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin),
					put(next_trigger_type,?CONDITION_NULLEND);
				_ ->
					skip
			end;
		?TRIGGER_MOVE_OBJ->
			case EventState#temp_dungeon_obj.event_param of 
				ObjList when length(ObjList) > 0 ->
					{ok,DataBin} = pt_23:write(23049, [DunObjId,ObjState,ObjList]) ,
					?TRACE("TRIGGER_MOVE_OBJ::23049~n"),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
				_ ->
					skip
			end;
		?TRIGGER_SHAKE ->
			case EventState#temp_dungeon_obj.event_param of 
				[Amp,CostTime,Times] ->
					{ok,DataBin} = pt_23:write(23050, [DunObjId,ObjState,Amp,CostTime,Times]) ,
					?TRACE("TRIGGER_SHAKE::23050~n"),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
				_ ->
					skip
			end;
		?TRIGGER_NPC_FLY->
			case EventState#temp_dungeon_obj.event_param of 
				[NpcId,Time,TarX,TarY] ->
					?TRACE("TRIGGER_NPC_FLY::23051~n"),
					{ok,DataBin} = pt_23:write(23051, [DunObjId,ObjState,NpcId,Time,TarX,TarY]) ,
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
				_ ->
					skip
			end;
		?TRIGGER_END_DUNGEON ->
					?TRACE("TRIGGER_END_DUNGEON::~n"),
			case EventState#temp_dungeon_obj.event_param of 
				[] ->
					DunRcd = lib_dungeon:get_dungeon_daily(get(uid)) ,
					lib_dungeon:send_finish_data(DunRcd,Status#player.other#player_other.pid_send);
				_ ->
					skip
			end;
		?TRIGGER_SCALE_CAMERA ->
			case EventState#temp_dungeon_obj.event_param of 
				[CameraHeight,TargetX,TargetY,MoveTime,StopTime] ->
					?TRACE("TRIGGER_SCALE_CAMERA::~n"),
					{ok,DataBin} = pt_23:write(23052, [DunObjId,ObjState,CameraHeight,TargetX,TargetY,MoveTime,StopTime]) ,
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
				_ ->
					skip
			end;
		_ ->
			?TRACE("[lib_dungeon error] do_action::no match:~p~n",[EventState#temp_dungeon_obj.event])
	end,
	do_next_state(DunObjId),
	trigger_dungeon_object(Status,DunObjId,get(next_trigger_type),0),
	erase(next_trigger_type),
	ok.

get_obj_state(DunObjId) ->
	case lib_dungeon:get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd,dungeon_daily) ->
			case lists:keyfind(DunObjId,1,DunRcd#dungeon_daily.obj_state) of
				false ->
					0;
				{OId,State} ->
					State
			end;
		_ ->
			skip
	end.

do_next_state(DunObjId) ->
	case lib_dungeon:get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd,dungeon_daily) ->
			NewDunRcd = case lists:keyfind(DunObjId,1,DunRcd#dungeon_daily.obj_state) of
				false ->
					ObjState = DunRcd#?ETS_DUNGEON_DAILY.obj_state,
					DunRcd#?ETS_DUNGEON_DAILY{obj_state = ObjState ++ [{DunObjId,1}]};
				{OId,State} ->
					ObjState = lists:keydelete(OId,1,DunRcd#?ETS_DUNGEON_DAILY.obj_state),
					DunRcd#?ETS_DUNGEON_DAILY{obj_state = ObjState ++ [{DunObjId,State+1}]}
			end,
			lib_dungeon:save_dungeon_daily(NewDunRcd);
		_ ->
			skip
	end.

%%put_kill_monster(MonsterId) ->
%%	case get(kill_monster)of
%%		undefined ->
%%			put(kill_monster,[{MonsterId,1}]);
%%		MonList ->
%%			MonList3 = case lists:keyfind(MonsterId,1,MonList) of
%%				false ->
%%					MonList ++ [{MonsterId,1}]
%%				{MonsterId,Num} ->
%%					MonList2 = lists:keydelete(MonsterId,1,MonList)
%%					MonList2 ++ [{MonsterId,Num+1}]
%%			end,
%%			put(kill_monster,MonList3)
%%	end,
%%	ok.
%%
%%get_kill_monster() ->
%%	case get(kill_monster) of
%%		undefined ->
%%			[];
%%		MonList ->
%%			MonList
%%	end.

notify_dungeon_state(Status) ->
	%%TODO:断线重连的处理
	DunRcd = lib_dungeon:get_dungeon_daily(get(uid)) ,
	case tpl_dungeon_obj:get_by_dun_id(DunRcd#?ETS_DUNGEON_DAILY.sid) of
		DunObjList when length(DunObjList) > 0 ->
			ObjState = DunRcd#?ETS_DUNGEON_DAILY.obj_state,
			TObjList = lists:foldl(fun(T,Result) -> 
									case T of
										{ObjId,State} ->
											case State > 0 of
												true ->
													Result ++ [ObjId];
												false ->
													Result
											end;
										_ ->
											Result
									end
							end,[],ObjState),
			DunDunObjIds = lists:map(fun(T) -> T#temp_dungeon_obj.obj_id end, DunObjList),
			UObjList = lists:filter(fun(OId) -> 
										case lists:keyfind(OId,1,ObjState) of
											false ->
												true;
											_ ->
												false
										end
									end,lists:usort(DunDunObjIds)),
			InVisibleList = lists:filter(fun(OId) ->
										case lists:keyfind(OId,1,ObjState) of
											false ->
												case tpl_dungeon_obj:get(DunRcd#?ETS_DUNGEON_DAILY.sid,OId,1) of
													Temp when is_record(Temp,temp_dungeon_obj) ->
														Temp#temp_dungeon_obj.create =< 0;
													_ ->
														false
												end;
											_ ->
												false	
										end
									end,UObjList),
			{ok,DataBin} = pt_23:write(23042, [TObjList,UObjList--InVisibleList,InVisibleList]) , 
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, DataBin);
		_ ->
			skip
	end.
%%物件触发end
