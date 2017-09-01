%%%--------------------------------------
%%% @Module  : pp_skill
%%% @Author  : water
%%% @Created : 2013.01.18 
%%% @Description:  技能学习升级
%%%--------------------------------------
-module(pp_skill).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).


%% API Functions
handle(Cmd, Status, Data) ->
    NewStatus = Status#player{switch = Status#player.switch bor ?SW_SKILL_BIT},
    handle_cmd(Cmd, NewStatus, Data).

%%--------------------------------------
%%Protocol: 21000 获取技能列表
%%--------------------------------------
handle_cmd(21000, Status, _) ->
    {AllSkill,SkillPoint} = lib_skill:get_skill_info(Status),   
    pack_and_send(Status, 21000, [AllSkill,SkillPoint]);

%%--------------------------------------
%%Protocol: 21001 学习技能
%%--------------------------------------
handle_cmd(21001, Status, [SkillId])-> 
 	case Status#player.switch band ?SW_SKILL_BIT =:= ?SW_SKILL_BIT of
		true -> 
			case lib_skill:check_skill_id(SkillId) of 
				true ->
			
							case lib_skill:learn_skill(Status, SkillId) of
								{false, Reason} ->
									?TRACE("[SKILL_LEARN] player: ~p learn skill  :~p fail reason : ~p ~n", [Status#player.id,SkillId,Reason]),
									pack_and_send(Status, 21001, [Reason]);
								{true, NewStatus} ->  
									pack_and_send(Status, 21001, [1, SkillId,NewStatus#player.other#player_other.skill_point]),
									%扣钱, 刷新属性
									%NewStatus = lib_player:send_player_attribute2(Status, 5);
									{ok, NewStatus}
							end;
				false ->
					?TRACE("[SKILL_LEARN] error skill id :~p ~n", [SkillId]),
					pack_and_send(Status, 21001, [0])  %%无效的技能ID
			end;
		false ->
			?TRACE("[SKILL_LEARN] player not open skill mod Data:~p ~n", [Status#player.switch]),
			pack_and_send(Status, 21001, [0])  %%玩家没有开通技能模块
	end;

%%--------------------------------------
%%Protocol: 21002 升级技能
%%--------------------------------------
handle_cmd(21002, Status, [SkillId,SkillPoint])->
	case Status#player.switch band ?SW_SKILL_BIT =:= ?SW_SKILL_BIT of
		true ->
			case lib_skill:check_skill_id(SkillId) of
				true ->
					case lib_skill:check_skill_type(SkillId) of
						true ->  
							case  lib_skill:check_skill_point(Status#player.other,SkillPoint) of
								true ->
									case lib_skill:upgrade_skill(Status, SkillId,SkillPoint) of
										{false, Reason} ->
											pack_and_send(Status, 21002, [Reason]);
										{true, NewLv, NewStatus,SkillPointInfo} ->
											pack_and_send(Status, 21002, [1, SkillId, NewLv,SkillPointInfo]),
											%扣钱, 刷新属性
											%NewStatus = lib_player:send_player_attribute2(Status, 5);
											{ok, NewStatus}
									end; 
								false ->
									pack_and_send(Status, 21001, [7]) %技能点不足
							end;
						false ->
							pack_and_send(Status, 21001, [6]) %该技能类型不能升级
					end;
				false ->
					pack_and_send(Status, 21002, [0])  %%无效的技能ID
			end;
		false ->
			pack_and_send(Status, 21002, [0])  %%无效的技能ID
	end;

%%--------------------------------------
%%Protocol: 21003 使用技能(新)
%%--------------------------------------
handle_cmd(21003, Status, [SkillId,SAction,RoleType,RoleId,SesssionId,X,Y])->    
		case Status#player.switch band ?SW_SKILL_BIT =:= ?SW_SKILL_BIT of
		true ->
			case lib_skill:check_skill_id(SkillId) of
				true ->    
					case battle_util:check_fightable(Status#player.battle_attr,SkillId) of %检测玩家状态(是否被定身/沉默等)
						true ->  
							case lib_skill:check_skill_usable(Status, SkillId) of  %检测技能能否施放1.能量值 2.cd
								{true,_} ->  
								 BattleAttr = Status#player.battle_attr#battle_attr{direct_x = X,direct_y = Y},
								 case lib_scene:is_dungeon_scene(Status#player.scene) of
												true ->    
													mod_dungeon:start_player_attack(Status#player.other#player_other.pid_dungeon, 
																					Status#player{battle_attr = BattleAttr}, RoleId, RoleType, SkillId,SAction,SesssionId) ;
												false ->  
													mod_scene:start_player_attack(Status#player.other#player_other.pid_scene, 
																				  Status#player{battle_attr = BattleAttr}, RoleId, RoleType, SkillId,SAction,SesssionId) 
											end  ;
								{false,_} ->
									?TRACE("[WARNING] can not use skill ~n",[]), 
									pack_and_send(Status, 21003, [0,SkillId,0,0]) 
							end ;
						false ->
							lib_player:send_tips(3102008, [], Status#player.other#player_other.pid_send) ,
							?TRACE("[WARNING] player -> ~p can not fight ~n",[Status#player.id]),
							pack_and_send(Status, 21003, [0,SkillId,0,0]) 
					end ;
				false -> 
					?TRACE("[BATTLE_WARNING] unknow skill id -> ~p  ~n",[SkillId]),
					pack_and_send(Status, 21003, [0,SkillId,0,0]) 			%%无效的技能ID
			end ;
		false -> 
			?TRACE("[WARNING] player -> ~p not open mod_skill ~n",[Status#player.id]),
			pack_and_send(Status, 21003, [0,SkillId,0,0]) 				  			%%用户没有开通技能模块
	end ;
%%--------------------------------------
%%Protocol: 21004 技能洗点
%%--------------------------------------
handle_cmd(21004, Status,[])->    
	case lib_skill:clean_all_skill_point(Status) of
		{ok,NewStatus}->
			pack_and_send(Status, 21004, [100,NewStatus#player.other#player_other.skill_list,NewStatus#player.other#player_other.skill_point]),
			{ok,NewStatus};
		{false,Reason} ->
			pack_and_send(Status, 21004, [Reason])
	end;
		 
handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

 
pack_and_send(Status, Cmd, Data) ->
%%     ?TRACE("pp_skill send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_21:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
     
