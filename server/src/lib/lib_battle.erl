%%%--------------------------------------
%%% @Module  : lib_battle
%%% @Author  : jack
%%% @Created : 2013.01.18
%%% @Description:战斗处理 
%%%--------------------------------------
-module(lib_battle).
-export([do_player_begin_attack/7, 
		 do_pet_begin_attack/5,   
		 do_monster_begin_attack/4,
		 battle_fail/3, 
		 send_battle_data/4,
		 change_2_battle_state/1,
		 init_battle_player/0,
		 reflsh_battle_state/0,
		 get_battle_expired_time/1,
		 move_battle_data/2,
		 move_battle_data/1,
		 do_scene_battle_expired/1,
		 get_all_battle_player/0,
		 do_leave_battle/1,
		 do_try_leave_battle/2,
		 init_dungeon_battle/0,
		 erase_battle_player/1,
		 auto_trigger_skill/6,  
		 save_monster_in_scene/4,
		 auto_trigger_monster_skill/5,
		 pack_and_send/3,
         single_attack/7,
		 passive_hurt_call_back/4,
		 merge_battle_player/1,
		 apply_skill_effect/10]).  

-include("debug.hrl").  
-include("common.hrl").
-include("record.hrl").
-include("battle.hrl").  
		
%%初始化场景中处于战斗状态的玩家列表
init_battle_player()-> 
	put(battle_key,[]).
 
init_dungeon_battle()->
	put(dungeon_battle,true).

%------------------------
%-	玩家使用技能逻辑
%------------------------

get_pre_skill_info(PlayerStatus,PreSkillId,PreSkillLv)->
	 case PreSkillLv of
							  -1 ->
								  battle_util:get_attack_skill(1, PreSkillId, PlayerStatus#player.other#player_other.skill_list, PlayerStatus#player.career) ;
							  _->
								  {PreSkillId,PreSkillLv}  
						  end.  
%接口逻辑:
%	1.消耗能量值
%	2.处理各种buff
%	3.如果是主动伤害技能就调用伤害接口计算技能伤害
%	4.保存玩家数据    
do_player_begin_attack(OldPlayerStatus, DefendId, DefendType, PreSkillId,PreSkillLv,SAction,SesssionId)->    
	DefendStatus = battle_util:get_status(DefendId, DefendType), 
	case DefendStatus of
		[]->
			pp_skill:pack_and_send(OldPlayerStatus, 21003, [0,PreSkillId,0,0]);
		_->
			{SkillId, SkillLv}  = get_pre_skill_info(OldPlayerStatus,PreSkillId,PreSkillLv),   
			SkillTpl = tpl_skill:get(SkillId),
			SkillAttrTpl = tpl_skill_attr:get(SkillId, SkillLv), 
			MapId = OldPlayerStatus#player.scene div 100,    
			{RepelList,RushList,SelfBuff,TarBuff} = buff_util:filter_buff(SkillAttrTpl#temp_skill_attr.buff),  
			if RushList =/= [] ->
				   {BattleAttr,RushResult} = battle_util:do_rush(MapId,OldPlayerStatus#player.battle_attr,battle_util:get_attr_status(DefendStatus),RushList ,[]),
				   PidSendList = lib_send:get_range_pid_send(OldPlayerStatus#player.scene,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y),
				   gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast,buff_util,broadcast_new_skill_buff_4_mon,[PidSendList,?ELEMENT_PLAYER,OldPlayerStatus#player.id,BattleAttr,RushResult]});
			   true -> 
				   BattleAttr = OldPlayerStatus#player.battle_attr
			end,				
			PlayerStatus  = OldPlayerStatus#player{battle_attr = BattleAttr},
			case battle_util:check_define_status(DefendType,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,DefendStatus,SkillTpl,{PlayerStatus#player.camp}) of
				true ->      
					NewBattleAttr = BattleAttr#battle_attr{is_rush_success = ?BUFF_RUSH_DEFAULT},
					NewPlayerStatus1 = lib_energy:reflesh_energy(PlayerStatus#player{battle_attr = NewBattleAttr}),    
					NewPlayerStatus2 =  lib_skill:update_player_battle_attr(NewPlayerStatus1, PreSkillId,SkillLv) ,
					pp_skill:pack_and_send(NewPlayerStatus2, 21003, [1,PreSkillId,NewPlayerStatus2#player.battle_attr#battle_attr.energy#energy.energy_val,SesssionId]) ,  		 
					apply_skill_effect(NewPlayerStatus2,DefendStatus,DefendType,SkillTpl,SAction,SesssionId,SkillLv,RepelList,TarBuff,SelfBuff); 
				{false,ErrCode}->   
					lib_player:send_tips(ErrCode, [], PlayerStatus#player.other#player_other.pid_send), 
					pp_skill:pack_and_send(PlayerStatus, 21003, [0,PreSkillId,0,0])
			end
	end . 

%%应用技能效果
apply_skill_effect(PlayerStatus,DefendStatus,DefendType,SkillTpl,SAction,SesssionId,SkillLv,RepelList,TarBuff,SelfBuff)->
	DefendInfo= battle_util:get_defend_obj_lists(PlayerStatus,DefendStatus,DefendType,SkillTpl,PlayerStatus#player.scene),  
 	case SkillTpl#temp_skill.is_damage  of   
		?SKILL_TYPE_DEMAGE->    
			{NewPs1,DefendList}=start_player_attack(PlayerStatus,SkillTpl#temp_skill.sid,SkillLv,SkillTpl,SAction,DefendInfo,SesssionId),
	 		lib_skill:apply_skill_buff(?SKILL_TYPE_DEMAGE,DefendList,TarBuff,RepelList,NewPs1,{SkillTpl#temp_skill.sid,SkillLv,SesssionId});   
		?SKILL_TYPE_NODEMAGE ->    
			merge_battle_player(PlayerStatus#player.id), 
			NewPs = change_2_battle_state(PlayerStatus), 
			gen_server:cast(PlayerStatus#player.other#player_other.pid,{save_battle_attr,NewPs#player.battle_attr,NewPs#player.status}),
			{_,_,PostX,PostY} = DefendInfo,  
			NewDefendList = battle_util:make_defend_tpl_list(DefendInfo),
			{ok,DataBin} =  pt_20:write(20001, [NewPs#player.id, 
												NewPs#player.battle_attr#battle_attr.hit_point, 
												NewPs#player.battle_attr#battle_attr.energy#energy.energy_val, SkillTpl#temp_skill.sid,  SkillLv, SAction,
												PostX,PostY,SesssionId,
												NewDefendList]),     
			send_battle_data(NewPs,NewPs#player.battle_attr#battle_attr.x,NewPs#player.battle_attr#battle_attr.y, DataBin), 
			lib_skill:apply_skill_buff(?SKILL_TYPE_NODEMAGE,DefendInfo,TarBuff,RepelList,NewPs,{SkillTpl#temp_skill.sid,SkillLv,SesssionId});
		_-> 
			skip  
	end,    
	lib_skill:apply_self_skill_buff(PlayerStatus,SelfBuff,{SkillTpl#temp_skill.sid,SkillLv,SesssionId}).

%%自动触发后续技能逻辑
auto_trigger_skill(PlayerId,TargetId,TargetType,SkillId,SkillLv,SesssionId)->
	Ps = battle_util:get_status(PlayerId, ?ELEMENT_PLAYER),
	SkillTpl = tpl_skill:get(SkillId),
	case get_target(SkillTpl,{Ps#player.camp},Ps#player.battle_attr,TargetType,Ps#player.scene) of
		self ->
			do_player_begin_attack(Ps, Ps#player.id, ?ELEMENT_PLAYER, SkillId,SkillLv,0,SesssionId);
		{NewTargetId,NewTargetType}->
			do_player_begin_attack(Ps,NewTargetId,NewTargetType, SkillId,SkillLv,0,SesssionId);
		target ->
			do_player_begin_attack(Ps,TargetId,TargetType, SkillId,SkillLv,0,SesssionId); 
		_->
			skip
	end.  
%反伤被动分流
passive_hurt_call_back(AttrId,?ELEMENT_PLAYER,DemageVal,Ps) when Ps#player.battle_attr#battle_attr.hurt_call_back > 0 ->
 	DefendPlayerStatus = battle_util:get_status(AttrId, ?ELEMENT_PLAYER),
	NewDefinePs = change_2_battle_state(DefendPlayerStatus),
	NewDefinePs1 = lib_energy:reflesh_energy(NewDefinePs), 
	NewDamageValue = util:ceil(DemageVal*(Ps#player.battle_attr#battle_attr.hurt_call_back+Ps#player.battle_attr#battle_attr.passive_hurt_rate)/10000),
	NewDefinePs2 = lib_energy:trigger_define_energy(NewDamageValue,NewDefinePs1),
	{NewDamageValue1,NewDefendStatus} = lib_scene:save_player_damage(NewDefinePs2,NewDamageValue) ,
	gen_server:cast
	  (NewDefendStatus#player.other#player_other.pid, {battle_callback, NewDamageValue1,NewDefendStatus#player.battle_attr,NewDefendStatus#player.status,Ps#player.id,?ELEMENT_PLAYER,?HURT_NOT_CALL_BACK}),
	gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast,buff_util,broadcast_new_skill_buff, [Ps#player.scene,?ELEMENT_PLAYER, AttrId,NewDefendStatus#player.battle_attr,
																						   [{?BUFF_TYPE_DAMAGE,?DAMAGE_TYPE_NORMAL,{NewDamageValue1,NewDefendStatus#player.battle_attr#battle_attr.hit_point,-1,0}}]]});
																							 
passive_hurt_call_back(AttrId,?ELEMENT_MONSTER,DemageVal,Ps) when Ps#player.battle_attr#battle_attr.hurt_call_back > 0-> 
	DefendMonsterStatus = battle_util:get_status(AttrId, ?ELEMENT_MONSTER),
	NewDamageValue = util:ceil(DemageVal*(Ps#player.battle_attr#battle_attr.hurt_call_back+Ps#player.battle_attr#battle_attr.passive_hurt_rate)/10000),
	{{_,_,NewHp,_,_,_,_},Killed} = save_attacked_monlayout(Ps,DefendMonsterStatus,DefendMonsterStatus#temp_mon_layout.battle_attr,?DAMAGE_TYPE_NORMAL,NewDamageValue),
	case Killed of
		true ->  
			lib_mon:handle_monster_drop(Ps, [DefendMonsterStatus])  ;
		false ->
			skip
	end ,  
	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->     
			buff_util:broadcast_new_skill_buff_in_dungeon( ?ELEMENT_MONSTER,AttrId,Ps#player.other#player_other.pid_send, DefendMonsterStatus#temp_mon_layout.battle_attr,[{?BUFF_TYPE_DAMAGE,?DAMAGE_TYPE_NORMAL,{NewDamageValue,NewHp,-1,0}}]);
		false ->
			gen_server:cast(mod_scene_agent:get_agent_pid(), 
							{apply_cast,buff_util,broadcast_new_skill_buff,[Ps#player.scene,?ELEMENT_MONSTER, AttrId,DefendMonsterStatus#temp_mon_layout.battle_attr,[{?BUFF_TYPE_DAMAGE,?DAMAGE_TYPE_NORMAL,{NewDamageValue,NewHp,-1,0}}]]})
	end; 
passive_hurt_call_back(_,_,_,_)->
	skip.

%% @spec 人攻击怪物战斗类型，人打怪的时候，以自己为攻击原点
%% AttackRoleId 攻击方
%% DefendId 被击方
%% SkillId 技能ID
%% DefendType: 1表示人, 2表示怪 
start_player_attack(PlayerStatus,SkillId,SkillLv,SkillTpl,SAction,DefendsInfo,SesssionId) ->  
	{MonsterList,PlayerList,PostX,PostY} = DefendsInfo,
	if SkillTpl#temp_skill.is_share_damage =:= ?IS_SHARE_SKILL ->
		   ShareDamageRate = 1/max((length(MonsterList)+length(PlayerList)),1);
	   true ->
		   ShareDamageRate = 1
	end, 
	AttactBattleAttr = PlayerStatus#player.battle_attr , 
	NewPs = change_2_battle_state(PlayerStatus), 
	BattleWithPlayer = fight_with_player(PlayerStatus#player.id,?ELEMENT_PLAYER,AttactBattleAttr,PlayerList,[], SkillId, SkillLv,ShareDamageRate) ,
	{BattleWithMonster,KilledMonRcdList} = fight_with_monster(NewPs,AttactBattleAttr,MonsterList,BattleWithPlayer,[],SkillTpl#temp_skill.aoe_dist, SkillId, SkillLv,ShareDamageRate) ,
	lib_mon:handle_monster_drop(NewPs, KilledMonRcdList) ,
	merge_battle_player(NewPs#player.id),  
	StateChange = NewPs#player.status =:=PlayerStatus#player.status, 
	NewPs1 = player_fight_call_back(StateChange,SkillTpl#temp_skill.is_normal_attr, NewPs, BattleWithPlayer, BattleWithMonster),
    {ok,DataBin} =  pt_20:write(20001, [NewPs1#player.id, 
										NewPs1#player.battle_attr#battle_attr.hit_point, 
										NewPs1#player.battle_attr#battle_attr.energy#energy.energy_val, SkillId,  SkillLv, SAction,
										PostX,PostY,SesssionId,
										BattleWithMonster]),    
	send_battle_data(NewPs1,PostX,PostY, DataBin), 
	gen_server:cast(NewPs1#player.other#player_other.pid,{save_battle_attr,NewPs1#player.battle_attr,NewPs1#player.status}),
	{NewPs1,BattleWithMonster}. 

%%判断是否副本进程
check_if_dungeon()->
	case get(dungeon_battle) of
		true -> true;
		_->false
	end.

%--------------------------
%-     更改玩家战斗状态
%--------------------------

%%更改玩家状态到战斗状态
change_2_battle_state(Ps) when Ps#player.status =/= ?PLAYER_BATTLE_STATE->
	case check_if_dungeon() of  
		true-> skip;
		_-> 
			List = get_all_battle_player(), 
			put(battle_key,[Ps#player.id]++List)
	end,  
	NewPs = lib_energy:reflesh_energy(Ps),
	pack_and_send(NewPs, 20007,
				  [?PLAYER_BATTLE_STATE,NewPs#player.battle_attr#battle_attr.energy#energy.energy_val]),
	self()!{'reflesh_player_state',util:unixtime()},
	NewPs#player{status = ?PLAYER_BATTLE_STATE};
change_2_battle_state(Ps) -> 
	Ps.
change_2_normal_state(Ps) when Ps#player.status =:= ?PLAYER_BATTLE_STATE ->  
	NewPs = lib_energy:reflesh_energy(Ps),
	pack_and_send(NewPs, 20007,
				  [?PLAYER_NORMAL_STATE,NewPs#player.battle_attr#battle_attr.energy#energy.energy_val]),
	NewBattleAttr = lib_energy:reset_player_battle_cover_energy(NewPs#player.battle_attr),
	NewPs#player{status = ?PLAYER_NORMAL_STATE,battle_attr = NewBattleAttr};
change_2_normal_state(Ps) ->  
	Ps.
    
%--------------------------------
%-场景模块战斗状态玩家进程字典维护
%--------------------------------

%%玩家每一次攻击工具都刷新最近战斗时间
merge_battle_player(PlayerId)-> 
	put({battle_state,PlayerId},util:unixtime()).

%%玩家6秒内没有发起攻击或切换场景,迁移或移除玩家进程字典数据
erase_battle_player(PlayerId)->
	erase({battle_state,PlayerId}).

%%获取所有正在战斗的玩家
get_all_battle_player()->
	case get(battle_key) of
		List when is_list(List)->
			List;
		_-> 
			[]
	end.

%%角色切换场景时搬迁角色数据(source)
move_battle_data(Ps)-> 
	case get({battle_state,Ps#player.id}) of  
		Time when is_integer(Time)-> 
			erase_battle_player(Ps#player.id),
			NewPs = change_2_normal_state(Ps), 
			{Time,NewPs};
		_->
			{0,Ps}
	end.

%%角色切换场景时搬迁角色数据(target)
move_battle_data(PlayerId,Time) when is_integer(Time) andalso Time>0->
	if Time >0 ->
		   put({battle_state,PlayerId},Time),
		   List = get_all_battle_player(), 
		   put(battle_key,[PlayerId]++List);
	   true->
		   skip
	end;
move_battle_data(_,_)->
	skip.

%%刷新玩家战斗状态(场景进程用)
reflsh_battle_state()-> 
	List = get_all_battle_player(),    
	NewList = lists:foldl(fun do_try_leave_battle/2, [], List),
	put(battle_key,NewList),
	NewList =:= [].

%%令玩家脱离战斗(单人副本进程/角色死亡用)
do_leave_battle(Uid)->
	case get({battle_state,Uid}) of
		Time when is_integer(Time) -> 
			case lib_player:get_player(Uid) of
				Ps when is_record(Ps, player)->
					NewPs = change_2_normal_state(Ps), 	
					gen_server:cast(Ps#player.other#player_other.pid,{change_battle_status,?PLAYER_NORMAL_STATE,NewPs#player.battle_attr#battle_attr.energy}),
					erase_battle_player(Uid); 
				_->skip
			end;
		_->
			skip	
	end.

%%尝试让玩家脱离战斗
do_try_leave_battle(PlayerId,List)->
	case get({battle_state,PlayerId}) of
		Time when is_integer(Time) ->
			Now = util:unixtime(),
			if 
				Now- Time >=?BATTLE_EXPRIED_TIME -> 
					case lib_player:get_player(PlayerId) of
						Ps when is_record(Ps, player)->
							NewPs = change_2_normal_state(Ps),
							gen_server:cast(Ps#player.other#player_other.pid,{change_battle_status,?PLAYER_NORMAL_STATE,NewPs#player.battle_attr#battle_attr.energy}); 
						R-> 
							skip
					end, 
					erase_battle_player(PlayerId),
					List;
				true-> 
					[PlayerId]++List
			end;
		_-> 
			List	
	end. 
%%获取玩家最新进入战斗的时间
get_battle_expired_time(Ps)->
	ScenePid = Ps#player.other#player_other.pid_scene,
	if is_pid(ScenePid) -> 
		   gen_server:call(ScenePid, {apply_call, lib_battle, move_battle_data, [Ps]});
	   true->
		   0
	end.
%%强制令场景中的玩家脱离战斗
do_scene_battle_expired(Ps)->
	ScenePid = Ps#player.other#player_other.pid_scene,
	if is_pid(ScenePid) -> 
		   gen_server:cast(ScenePid, {apply_cast, lib_battle, move_battle_data, [Ps]});
	   true-> skip
	end.

do_monster_begin_attack(MonLayoutStatus, OldDefendStatus,SkillId,SkillLv)->
	DefendStatus = battle_util:get_status(OldDefendStatus#player.id, ?ELEMENT_PLAYER),
	SkillTpl = tpl_skill:get(SkillId),
	SkillAttrTpl = tpl_skill_attr:get(SkillId, SkillLv),  
	case battle_util:check_fightable(MonLayoutStatus#temp_mon_layout.battle_attr,SkillId) of
		true ->  
			case battle_util:check_define_status(?ELEMENT_PLAYER,MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.x,MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.y,DefendStatus,SkillTpl,{10}) of
				true ->    
				 	DefendInfo= battle_util:get_defend_obj_lists(MonLayoutStatus,DefendStatus,?ELEMENT_PLAYER, SkillTpl,MonLayoutStatus#temp_mon_layout.scene_id),  
					{RepelList,_,SelfBuff,TarBuff} = buff_util:filter_buff(SkillAttrTpl#temp_skill_attr.buff),  
					Now = util:unixtime(),
					lib_skill:apply_skill_buff(?SKILL_TYPE_NODEMAGE,{[MonLayoutStatus],[],0,0},SelfBuff,[],MonLayoutStatus,{SkillId,SkillLv,Now}),
					case SkillTpl#temp_skill.is_damage  of  
						?SKILL_TYPE_DEMAGE->    
							start_mon_attack(MonLayoutStatus, DefendInfo, SkillId, SkillLv,SkillTpl,TarBuff,RepelList); 
						?SKILL_TYPE_NODEMAGE ->  
					 		lib_skill:apply_skill_buff(?SKILL_TYPE_NODEMAGE,DefendInfo,TarBuff,RepelList,MonLayoutStatus,{SkillId,SkillLv,Now}),  
							{?ATTACK_SUCCESS, []} ;
						_->
							skip
					end;
				_->
				      skip
			end;
		_-> 
			?TRACE("[MONSTER_BATTLE] monster can not fight ~n ",[]), 
			skip 
	end.
%%怪物自动触发技能
auto_trigger_monster_skill(Monster,TargetId,TargetType,SkillId,SkillLv)-> 
	SkillTpl = tpl_skill:get(SkillId), 
	io:format("nono ~p ~n",[SkillId]),
	case get_target(SkillTpl,{10},Monster#temp_mon_layout.battle_attr,TargetType,Monster#temp_mon_layout.scene_id) of
		self ->
			do_monster_begin_attack(Monster, Monster,SkillId,SkillLv); 
		{NewTargetId,NewTargetType}->
			Target = battle_util:get_status(NewTargetId, NewTargetType),
			do_monster_begin_attack(Monster, Target,SkillId,SkillLv); 
		target ->
			Target = battle_util:get_status(TargetId,TargetType),
			do_monster_begin_attack(Monster, Target,SkillId,SkillLv); 
		_->
			skip    
	end.
%%@ 场景中的怪物发起战斗
start_mon_attack(MonLayoutStatus, DefendsInfo, SkillId, SkillLv,SkillTpl,TarBuff,RepelList) ->   

	AttackBattleAttr = battle_util:init_battle_info(MonLayoutStatus, ?ELEMENT_MONSTER),
	{_,PlayerList,PostX,PostY} = DefendsInfo, 
		if SkillTpl#temp_skill.is_share_damage =:= ?IS_SHARE_SKILL ->
		   ShareDamageRate = 1/ max(length(PlayerList),1);
	   true ->
		   ShareDamageRate = 1
	end,
	BattleWithPlayer = fight_with_player(MonLayoutStatus#temp_mon_layout.id,?ELEMENT_MONSTER,AttackBattleAttr,PlayerList,[], SkillId, SkillLv,ShareDamageRate) ,
	Now = util:unixtime(),
	{ok,DataBin} =  pt_20:write(20003, [MonLayoutStatus#temp_mon_layout.id, 
										MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.hit_point, 
										MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.magic, 
										SkillId, SkillLv, 
										PostX,PostY, Now,
										BattleWithPlayer]), 

	case BattleWithPlayer of
		[]->
			{?NOT_ATTACK_AREA,[]} ;
		_-> [FirstPs|_] = PlayerList,
			send_battle_data(FirstPs,PostX,PostY, DataBin),  
			lib_skill:apply_skill_buff(?SKILL_TYPE_DEMAGE,BattleWithPlayer,TarBuff,RepelList,MonLayoutStatus,{SkillId,SkillLv,Now}),
			{?ATTACK_SUCCESS, get_mon_attack_result(BattleWithPlayer)} 
	end. 

%%宠物发起战斗逻辑
do_pet_begin_attack(AttackUId, DefendId, DefendType, PreSkillId,SessionId)->    
	PlayerStatus = battle_util:get_status(AttackUId, ?ELEMENT_PLAYER),
	PetStatus = battle_util:get_status(AttackUId, ?ELEMENT_PET),
	%{SkillId, SkillLv} = {PreSkillId,1},
	{SkillId, SkillLv} = battle_util:get_attack_skill(1, PreSkillId, PetStatus#pet.skill_list,?CAREER_PET) , 
	AttackStatus = battle_util:init_pet_battle_info(PlayerStatus, PetStatus),
	SkillAttrTpl = tpl_skill_attr:get(SkillId, SkillLv), 
	{RepelList,_,SelfBuff,TarBuff} = buff_util:filter_buff(SkillAttrTpl#temp_skill_attr.buff),  
%	{AttactBattleAttr,_ } = lib_skill:update_attack_battle_attr(SelfBuff, SkillLv, AttackStatus#pet.battle_attr),
	SkillTpl = tpl_skill:get(SkillId), 
	DefendStatus = battle_util:get_status(DefendId, DefendType), 
	if is_record(DefendStatus, temp_mon_layout) ->
		   case battle_util:check_define_status(DefendType,PlayerStatus#player.battle_attr#battle_attr.x,PlayerStatus#player.battle_attr#battle_attr.y,DefendStatus,SkillTpl,{PlayerStatus#player.camp}) of
			   true ->   
				   DefendInfo= battle_util:get_defend_obj_lists(PlayerStatus,DefendStatus,DefendType,SkillTpl,PlayerStatus#player.scene),  
				   case SkillTpl#temp_skill.is_damage  of  
					   ?SKILL_TYPE_DEMAGE->    
						   DefendList = start_pet_attack(PlayerStatus,PetStatus, DefendInfo, SkillTpl,SkillLv,SessionId),
						    lib_skill:apply_skill_buff(?SKILL_TYPE_DEMAGE,DefendList,TarBuff,RepelList,PlayerStatus,{SkillId,SkillLv,util:unixtime()});
					   ?SKILL_TYPE_NODEMAGE ->  
						   lib_skill:apply_skill_buff(?SKILL_TYPE_NODEMAGE,DefendInfo,TarBuff,RepelList,PlayerStatus,{SkillId,SkillLv,util:unixtime()})
				   end,
				   write_back_pet_battle_data(PlayerStatus#player.other#player_other.pid,SelfBuff,SkillLv,PetStatus#pet.battle_attr);    
			   _->
				   pp_skill:pack_and_send(PlayerStatus, 21003, [0,PreSkillId,0,0])
		   end;
	   true->
		   ?ERROR_MSG("error monster state ~p ~n",[DefendStatus]) 
	end.

%% DefendType: 1表示人, 2表示怪
start_pet_attack(PlayerStatus,PetStatus, DefendInfo, SkillTpl,SkillLv,SessionId) -> 
	{MonsterList,PlayerList,PostX,PostY} = DefendInfo, 
	if SkillTpl#temp_skill.is_share_damage =:= ?IS_SHARE_SKILL ->
		   ShareDamageRate = 1/max( length(PlayerList),1);
	   true ->
		   ShareDamageRate = 1
	end,
 	BattleWithPlayer = fight_with_player(PlayerStatus#player.id,?ELEMENT_PLAYER,PetStatus#pet.battle_attr,PlayerList,[], SkillTpl#temp_skill.sid, SkillLv,ShareDamageRate) ,
 	{BattleWithMonster,KilledMonRcdList} = fight_with_monster
											 (PlayerStatus,PetStatus#pet.battle_attr,MonsterList,BattleWithPlayer,[],SkillTpl#temp_skill.aoe_dist, SkillTpl#temp_skill.sid, SkillLv,ShareDamageRate) ,
 	{ok,DataBin} =  pt_20:write(20004, [PlayerStatus#player.id, 
										SkillTpl#temp_skill.sid, SkillLv, 
										PostX,PostY, SessionId,
										BattleWithMonster]),
	?TRACE("Sc--------~p ~n ~p ~n", [{PlayerStatus#player.scene, PostX, PostY}, BattleWithMonster]),
	send_battle_data(PlayerStatus,PostX,PostY, DataBin) ,
	lib_mon:handle_monster_drop(PlayerStatus, KilledMonRcdList),
	BattleWithMonster. 





fight_with_player(AttrId,AttrType,_AttactBattleAttr,[],BattleResult, _SkillId, _SkillLv,_) ->
	BattleResult ;
fight_with_player(AttrId,AttrType,AttactBattleAttr,[DefendPlayerStatus|LeftList],BattleResult, SkillId, SkillLv,ShareDamageRate) ->
	if
		is_record(DefendPlayerStatus,player) ->   
			DefendBattleAttr = battle_util:init_battle_info(DefendPlayerStatus, ?ELEMENT_PLAYER) ,
			AerType = case AttactBattleAttr#battle_attr.career > 3 of
						  true -> ?ELEMENT_MONSTER;
						  false -> ?ELEMENT_PLAYER
					  end,
			case single_attack(AttactBattleAttr, DefendBattleAttr,0, SkillId, SkillLv, AerType, ?ELEMENT_PLAYER) of
				{0,0,_} ->		%% 不在攻击范围
					NewBattleResult =  BattleResult ;
				{DamageType,OldDamageValue,NewDefendBattleAttr} -> 
					DamageValue = util:ceil(OldDamageValue * ShareDamageRate),
					NewDefinePs = change_2_battle_state(DefendPlayerStatus),
					NewDefinePs1 = lib_energy:reflesh_energy(NewDefinePs), 
					NewDefinePs2 = lib_energy:trigger_define_energy(DamageValue,NewDefinePs1),
					merge_battle_player(NewDefinePs2#player.id),
					[BattleResultTpl] = save_attacked_player(AttrId,AttrType,NewDefinePs2,
															 NewDefendBattleAttr#battle_attr{energy = NewDefinePs2#player.battle_attr#battle_attr.energy},DamageType,DamageValue) ,
					NewBattleResult = [BattleResultTpl | BattleResult]
			end ;
		true ->
			NewBattleResult = BattleResult
	end ,  
	fight_with_player(AttrId,AttrType,AttactBattleAttr,LeftList,NewBattleResult, SkillId, SkillLv,ShareDamageRate) .

fight_with_monster(_PlayerStatus,_AttactBattleAttr,[],BattleResult,KilledMonRcdList,_AttackDist, _SkillId, _SkillLv,ShareDamageRate) ->
	{BattleResult,KilledMonRcdList} ;
fight_with_monster(PlayerStatus,AttactBattleAttr,[MonLayoutStatus | LeftList],BattleResult,KilledMonRcdList,AttackDist, SkillId, SkillLv,ShareDamageRate) ->
	NowTime = util:longunixtime() ,
	if
		is_record(MonLayoutStatus,temp_mon_layout) andalso MonLayoutStatus#temp_mon_layout.state =/= ?MON_STATE_6_DEAD 
        andalso NowTime >= MonLayoutStatus#temp_mon_layout.sing_expire ->
			DefendBattleAttr = battle_util:init_battle_info(MonLayoutStatus, ?ELEMENT_MONSTER) ,
		%	io:format("Func ~p ~n",[DefendBattleAttr#battle_attr.buff2]),
			case single_attack(AttactBattleAttr, DefendBattleAttr,0, SkillId, SkillLv, ?ELEMENT_PLAYER, ?ELEMENT_MONSTER) of
				{0,0,_} ->		%% 不在攻击范围
			 	NewKilledMonRcdList = KilledMonRcdList ,
					NewBattleResult =  BattleResult ;
				{DamageType,OldDamageValue,NewDefendBattleAttr} ->
		 		DamageValue =  util:ceil(OldDamageValue * ShareDamageRate),
				{BattleResultTpl,Killed} = save_attacked_monlayout(PlayerStatus,MonLayoutStatus,NewDefendBattleAttr,DamageType,DamageValue) ,
					case Killed of
						true ->
							NewKilledMonRcdList = [MonLayoutStatus|KilledMonRcdList] ;
						false ->
							NewKilledMonRcdList = KilledMonRcdList 
					end ,
					NewBattleResult = [BattleResultTpl | BattleResult]
			end ;
		true ->
			NewKilledMonRcdList = KilledMonRcdList ,
			NewBattleResult = BattleResult
	end ,
	fight_with_monster(PlayerStatus,AttactBattleAttr,LeftList,NewBattleResult,NewKilledMonRcdList,AttackDist, SkillId, SkillLv,ShareDamageRate) .

%%战斗结束后回写怪物数据
save_attacked_monlayout(PlayerStatus,MonLayoutStatus,BattleAttr,DamageType,DamageValue) ->
	LeftHp = max(0, BattleAttr#battle_attr.hit_point - DamageValue) ,
	NewDamageValue = BattleAttr#battle_attr.hit_point - LeftHp ,
	NewBattleAttr = BattleAttr#battle_attr{ hit_point = LeftHp } , 
	Now = util:longunixtime(),
	NewBattleAttr1 = lib_skill:reflesh_hurted_trigger_buff(NewBattleAttr,Now),  
	NewMonLayoutStatus = MonLayoutStatus#temp_mon_layout{battle_attr = NewBattleAttr1} , 
	lists:foreach(fun({SkillId,SkillLv,_})->
				  lib_skill:buff_trigger_single_monster_skill(NewMonLayoutStatus,PlayerStatus#player.id,?ELEMENT_PLAYER,SkillId,SkillLv)
				  end,NewBattleAttr1#battle_attr.hurted_buff), 
	save_monster_in_scene(PlayerStatus,NewMonLayoutStatus,LeftHp,NewDamageValue),
	BattleResult = {?ELEMENT_MONSTER, 
					 MonLayoutStatus#temp_mon_layout.id, 
					 LeftHp, 
					 MonLayoutStatus#temp_mon_layout.battle_attr#battle_attr.magic, 
					 DamageValue, 0, DamageType} ,
	{BattleResult, LeftHp =:= 0} .

%%回写宠物战斗数据
write_back_pet_battle_data(Pid,SelfBuffList,SkillLv,PetBattleAttr)->
	gen_server:cast(Pid, {pet_fight_call_back,SelfBuffList,SkillLv,PetBattleAttr}).


%%保存怪物数据到对应的场景
save_monster_in_scene(PlayerStatus,MonLayout,LeftHp,NewDamageValue)->
	case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
		true ->
            case LeftHp =:= 0 of % 人杀死怪
                true -> 
                    if
                        MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id > 0 ->
                            lib_mon_ai:handle_mon_ai(MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id, MonLayout#temp_mon_layout.id,PlayerStatus);
                        true ->
                            skip
                    end,
                    gen_fsm:send_all_state_event(MonLayout#temp_mon_layout.pid,stop);
                false ->  
                    MonLayout#temp_mon_layout.pid ! {'player_coming',MonLayout,
                        PlayerStatus#player.other#player_other.pid_dungeon,PlayerStatus}%%通知怪物被打
            end,
            
            if
                %%如果怪物的血量为零且该怪物身上有怪物AI，则该怪物延迟一秒死亡
                LeftHp =:= 0 andalso MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id > 0 ->
                    erlang:send_after(1000,PlayerStatus#player.other#player_other.pid_dungeon,{'delay_save_dead_monster',PlayerStatus,MonLayout});
                true ->
                    lib_dungeon_monster:save_monster(PlayerStatus,MonLayout,LeftHp)
            end;
		false ->
            NowTime = util:unixtime(),
			case LeftHp =:= 0 of % 人杀死怪   
				true ->
                    if
                        MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id > 0 ->
                            lib_mon_ai:handle_mon_ai(MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id, MonLayout#temp_mon_layout.id,PlayerStatus);
                        true ->
                            skip
                    end,

                    MonLayoutTemp = MonLayout#temp_mon_layout{state = ?MON_STATE_6_DEAD},
                    if
                        %%如果怪物的血量为零且该怪物身上有怪物AI，则该怪物延迟一秒死亡
                        LeftHp =:= 0 andalso MonLayout#temp_mon_layout.monrcd#temp_npc.dead_ai_id > 0 ->
                            erlang:send_after(1000,PlayerStatus#player.other#player_other.pid_scene,{'delay_save_dead_monster',MonLayoutTemp,PlayerStatus,NewDamageValue});
                        true ->
                            MonLayout#temp_mon_layout.pid ! {'player_leaving',0},
                            lib_mon:save_monster(MonLayoutTemp,PlayerStatus,NewDamageValue, LeftHp)
                    end,

                    
                    NewBattle = buff_util:clear_dead_buff(MonLayout#temp_mon_layout.battle_attr),
                    if
                        MonLayout#temp_mon_layout.revive_time > 0 ->
                            erlang:send_after(MonLayout#temp_mon_layout.monrcd#temp_npc.dead_delay_time + MonLayout#temp_mon_layout.revive_time*1000,
                                PlayerStatus#player.other#player_other.pid_scene,
                                {'mon_revive',PlayerStatus,MonLayout#temp_mon_layout{battle_attr = NewBattle},NowTime}
                            );
                        true ->%%如果怪物的revive_time =:= 0，则默认该怪物不可复活
                            skip
                    end,
					lib_task:call_event(PlayerStatus,kill,{MonLayout#temp_mon_layout.monid,1});
				false ->
                    if
                        MonLayout#temp_mon_layout.state =/= ?MON_STATE_4_FIGHT ->
                            lib_mon:save_monster(MonLayout#temp_mon_layout{
                                                                 state = ?MON_STATE_4_FIGHT,
                                                                 target_uid = PlayerStatus#player.id
                                                             },
                                                 PlayerStatus,NewDamageValue, LeftHp
                                             ),
						      MonLayout#temp_mon_layout.pid ! {'player_coming',MonLayout,PlayerStatus#player.other#player_other.pid_scene,PlayerStatus};
                        true ->
						     lib_mon:save_monster(MonLayout,PlayerStatus,NewDamageValue, LeftHp)
                    end
            end
    end.  
%%战斗结束后回写玩家数据
save_attacked_player(AttrId,AttrType,DefendStatus,BattleAttr,DamageType,DamageValue) ->  
	{NewDamageValue,NewDefendStatus} = lib_scene:save_player_damage(DefendStatus#player{battle_attr = BattleAttr},DamageValue) ,
    gen_server:cast(NewDefendStatus#player.other#player_other.pid, {battle_callback, DamageValue,NewDefendStatus#player.battle_attr,NewDefendStatus#player.status,AttrId,AttrType,?HURT_CALL_BACK}),
 	BattleResult = [{?ELEMENT_PLAYER, 
					 NewDefendStatus#player.id, 
					 NewDefendStatus#player.battle_attr#battle_attr.hit_point, 
					 NewDefendStatus#player.battle_attr#battle_attr.energy#energy.energy_val, 
					 NewDamageValue, 0, DamageType}] , 
	BattleResult .
 


get_mon_attack_result(DefendBattleResult) ->
	F = fun(Info, Result) ->
		{_DefendType, DefendId, Hp, _Mp, _NewHpDamege, _MpDamege, _DamageType} = Info,
		if
			Hp > 0 -> [{DefendId, 1}] ++ Result;
			true -> [{DefendId, 0}] ++ Result
		end
	end,
	lists:foldl(F, [], DefendBattleResult).



%% 战斗发起失败
%% Code 错误码
%% AttackRole 攻击方
%% AttackType 1人, 2怪
battle_fail(Code, AttackRole, AttackType) ->
    if
		AttackType =:= ?ELEMENT_PLAYER ->
            {ok, BinData} = pt_20:write(20005, [Code, AttackRole#player.id]),
            lib_send:send_to_sid(AttackRole#player.other#player_other.pid_send, BinData);
		AttackType =:= ?ELEMENT_PET ->
			PlayerStatus = battle_util:get_status(AttackRole#pet.uid, ?ELEMENT_PLAYER),
            {ok, BinData} = pt_20:write(20005, [Code, PlayerStatus#player.id]),
            lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData);
   		true ->
            skip
    end. 




%% 处理战斗结果
send_battle_data(PlayerStatus, PostX, PostY, DataBin) ->
	case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
		true ->
			spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, DataBin) end ) ;
		false ->
			mod_scene_agent:send_to_matrix(PlayerStatus#player.scene, PostX, PostY, DataBin,"")
	end .
%% 单攻运算，所有战斗形式通用
single_attack(AttackBattleAttr, DefendBattleAttr,_AttackArea,SkillId, SkillLv, AttackType, DefendType) -> 
	BattleType = battle_util:get_battle_type(AttackType, DefendType), 
	%% 计算单个受击者伤害    
	{DamageType, DamegeNum} = data_battle:get_damage(BattleType, AttackBattleAttr, DefendBattleAttr, SkillId, SkillLv),	
	{DamageType, DamegeNum , DefendBattleAttr}  .

%%玩家主动攻击后回调->尝试刷新玩家能量值与更新玩家状态
player_fight_call_back(_,?SKILL_NORMAL_ATTR,Ps,DamegePlayers,DamegeMonstors)->  
	lib_energy:reflesh_attack_energy(DamegePlayers, DamegeMonstors, Ps); 
	%NewPs;
player_fight_call_back(false,_,Ps,_,_)-> 
	Ps#player{status = ?PLAYER_BATTLE_STATE};
player_fight_call_back(_,_,Ps,_,_)-> 
	Ps.

%%获取技能施放目标
get_target(SkillTpl,RelationInfo,BattleAttr,TargetType,SceneId)->
	case SkillTpl#temp_skill.target_type of
		?SKILL_AREA_SELF ->
			self;  
		?SKILL_AREA_TARGET ->
			if TargetType =:= -1 ->%没有目标，自己计算
				   Fun =battle_util:get_relation_charge_fun(SkillTpl#temp_skill.relation_type),  
				   case battle_util:get_defend_mon_list(BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,SkillTpl#temp_skill.distance,1,RelationInfo,Fun) of
					   {_,0}  ->  
						   case battle_util:get_defend_player_list(SceneId,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,SkillTpl#temp_skill.aoe_dist,1,RelationInfo,Fun) of
							   {_,0} ->
								   skip;  
							   {[DefendPlayer],1}->
								   {DefendPlayer#player.id, ?ELEMENT_PLAYER}
						   end;
					   {[Mon],1}->
						   {Mon#temp_mon_layout.id, ?ELEMENT_MONSTER}
				   end;
			   true ->%有目标，用目标
				    target
			end;
		?SKILL_AREA_POSITION->
			skip
	end.
pack_and_send(Status, Cmd, Data) ->
	 {ok, BinData} = pt_20:write(Cmd, Data),
	 lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
