%%%-----------------------------------
%%% @Module  : lib_skill
%%% @Author  : water
%%% @Created : 2013.01.18
%%% @Description: 技能库函数
%%%-----------------------------------
-module(lib_skill).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("battle.hrl").
-include("log.hrl").
-compile(export_all).

%%处理登录加载技能, 取出当前玩家技能列表
role_login(Status) ->  
	Skill = get_all_skill(Status#player.id, Status#player.career,Status#player.level),
	NewPlayerOther = Status#player.other#player_other{skill_list = Skill#skill.cur_skill_list,skill_point = Skill#skill.skill_point},
	Status#player{other = NewPlayerOther}.
%%玩家退出逻辑
role_logout(Status)->
    Skill = get_all_skill(Status#player.id, Status#player.career,Status#player.level), 
	db_agent_skill:update_skill(Skill).
%%更新玩家技能点信息
update_player_skill_point(Ps)->
	get_all_skill(Ps#player.id, Ps#player.career,Ps#player.level).

%%更新玩家战斗属性(限玩家进程调用)
%%根据被动技能更新玩家战斗属性
add_skill_attr_to_player(Status) ->
    _SkillList = Status#player.other#player_other.skill_list,
    BattleAttr = Status#player.battle_attr,
    %%被动技能加成
    NewBattleAttr = BattleAttr#battle_attr{},
    Status#player{battle_attr = NewBattleAttr}.

%%开启技能模块
open_skill(Status) ->
	case Status#player.level >= data_config:get_open_level(skill) of
		true  -> 
			Status#player{switch = Status#player.switch bor ?SW_SKILL_BIT};
		false -> 
			Status
	end .

%%重置被动技能入口函数
%1.消耗元宝
%2.开始重置
clean_all_skill_point(Ps)->
	case 10 > Ps#player.gold of
		true ->
			{false,1};
		false ->
			case lib_money:cost_money(Ps, 10, ?MONEY_T_BGOLD, ?LOG_SKILL_CLEAN) of
				NewPs1 when is_record(NewPs1, player)->  
					lib_player:send_player_attribute3(NewPs1),
					do_clean_all_skill_point(NewPs1);
				_->
					{false,2}
			end
	end.
%%重置被动技能
do_clean_all_skill_point(Ps)->
	Skill = get_all_skill(Ps#player.id, Ps#player.career,Ps#player.level), 
	NewSkillList = revert_skill(Ps#player.other#player_other.skill_list,[]),
	{_,SkillPointTotal} =  Ps#player.other#player_other.skill_point,
	NewSkill = Skill#skill{
						   skill_point = {0,SkillPointTotal},
						   cur_skill_list = NewSkillList,
						   skill_list = NewSkillList
						  },
	put(player_skill, NewSkill),
	NewPlayerOther = Ps#player.other#player_other{
												  skill_point = {0,SkillPointTotal},
												  skill_list = NewSkillList
												 },
	{ok,Ps#player{other = NewPlayerOther}}.

%%清空被动技能技能列表
revert_skill([],Result)->
	Result;
revert_skill([{SkillId,SkillLv}|Rest],Result)->
	TplSkill = tpl_skill:get(SkillId),
	case TplSkill#temp_skill.type =:= ?SKILL_PASSIVE of
		true ->
			revert_skill(Rest,Result);
		false ->
			revert_skill(Rest,[{SkillId,SkillLv}|Result])
	end.

%%学习技能 玩家进程调用
%%学习时后立刻回写数据库
learn_skill(Status, SkillId) ->
	case check_skill_learnable(Status, SkillId, 1) of
		true ->
			Skill = get_all_skill(Status#player.id, Status#player.career,Status#player.level),
			%% data_skill:get_require_skill_list(SkillId, 1)
			RequireSkillList = data_skill:get_require_skill_list(SkillId, 1),
			case check_skill_requirement(Skill#skill.cur_skill_list, RequireSkillList) of
				true ->
					case lists:keyfind(SkillId, 1, Skill#skill.cur_skill_list) of
						{SkillId, _Lv} ->
							{false, 6};  %技能已学习
						false ->
							TplSkill = tpl_skill:get(SkillId),  
							case TplSkill#temp_skill.type =:= ?SKILL_PASSIVE of
								true ->
									case check_skill_point(Status#player.other,1) of
										true ->
											{NewSkill,NewStatus}=cost_skill_point(Skill,Status,1),
											do_learn_skill(TplSkill,NewSkill,NewStatus);
										false ->
											{false,7}  
									end;
								false->  
									do_learn_skill(TplSkill,Skill,Status)
							end
					end;
				false ->
					{false, 5}  %%所学技能等级不够学习新技能
			end;
		false ->
			{false, 3} %%Level 
	end.

%%升级技能 玩家进程调用
%%升级立刻回写数据库
upgrade_skill(Status, SkillId,SkillPoint) ->
	Skill = get_all_skill(Status#player.id, Status#player.career,Status#player.level),
	case lists:keyfind(SkillId, 1, Skill#skill.cur_skill_list) of
		false ->
			{false, 5};   %技能未学习
		{SkillId, Lv} ->
			case check_skill_lv(SkillId, Lv+SkillPoint) of %%技能新等级是否有效
				true ->
					case check_passive_skill_upgrade(Status, Skill#skill.cur_skill_list, {SkillId, Lv+SkillPoint}) of
						true ->
							{SkillPointUsed,SkillPointTotal} = Status#player.other#player_other.skill_point,
							NewSkillPointInfo = {SkillPointUsed+SkillPoint,SkillPointTotal},
							%{CoinCost, EmpCost} = get_upgrade_cost(SkillId, Lv + 1),
							NewSkillList = lists:keyreplace(SkillId, 1, Skill#skill.cur_skill_list, {SkillId, Lv+SkillPoint}),
							NewSkill = Skill#skill{skill_list = NewSkillList, cur_skill_list = NewSkillList,skill_point = NewSkillPointInfo},
							put(player_skill, NewSkill),
							write_back_skill(), 
							NewPlayerOther = Status#player.other#player_other{
																			  skill_point = NewSkillPointInfo,
																			  skill_list = Skill#skill.cur_skill_list},
							TplSkill = tpl_skill:get(SkillId),
							NewBattleAttr = update_passive_skill(Status#player.battle_attr,TplSkill,Lv+SkillPoint),
							{true, Lv+SkillPoint, Status#player{other = NewPlayerOther,battle_attr = NewBattleAttr},NewSkillPointInfo};        %返回成功
						false ->
							{false, 3}  %%人物等级不足或技能等级不足
					end;
				false ->
					{false, 0} %%无效参数
			end
	end.
%%学习技能逻辑
do_learn_skill(SkillTpl,SkillInfo,Status)-> 
	SkillId = SkillTpl#temp_skill.sid,
	NewSkillList = [{SkillId, 1}|SkillInfo#skill.cur_skill_list], 
	NewSkill = SkillInfo#skill{skill_list = NewSkillList, cur_skill_list = NewSkillList},
	put(player_skill, NewSkill),
	write_back_skill(),
	NewPlayerOther = Status#player.other#player_other{skill_list = NewSkillList},
	{true, Status#player{other = NewPlayerOther}} .
%%消耗技能点
cost_skill_point(SkillInfo,Ps,SkillPoint)->
	{SkillPointUsed,SkillPointTotal} = Ps#player.other#player_other.skill_point,
	NewPlayerOther = Ps#player.other#player_other{
												 skill_point =  	{SkillPointUsed+SkillPoint,SkillPointTotal}
												  },
	NewSkillInfo = SkillInfo#skill{skill_point = {SkillPointUsed+SkillPoint,SkillPointTotal}},
	{NewSkillInfo,Ps#player{other = NewPlayerOther}}.

%%查看技能信息, 21000协议
get_skill_info(Status)->
    Skill = get_all_skill(Status#player.id, Status#player.career,Status#player.level), 
    F = fun({SkillId, Level}, SkillList) ->  
            case data_skill:is_normal_attr(SkillId) of   
                true -> SkillList;                      %%0为普通技能,不发到客户端
                _ -> [[SkillId, Level] | SkillList]
            end 
    end,
    SkillList = lists:foldr(F, [], Skill#skill.cur_skill_list),
	{SkillList,Skill#skill.skill_point}.
%%检查技能点是否足够
check_skill_point(PlayerOther,SkillPoint)->
	{SkillPointUsed,SkillPointTotal} = PlayerOther#player_other.skill_point,
	SkillPointTotal - SkillPointUsed >= SkillPoint .

%%----------------------------------------------------------
%%战斗相关技能函数
%%----------------------------------------------------------
%%功能: 检查战斗过程技能是否可用.
%%返回: true 技能可用, false 技能不可用
%%      检查技能CD, 消耗法力,怒气值 这里不修改任何战斗属性
check_skill_usable(Status, SkillId) ->
	CurSkillList = Status#player.other#player_other.skill_list,
	TplSkill = tpl_skill:get(SkillId),
	if TplSkill#temp_skill.type =/= ?SKILL_PASSIVE -> %%不能释放被动技能 
		   case lists:keyfind(SkillId, 1, CurSkillList) of
			   {SkillId, SkillLv} ->  %%已学习技能
				   TempSkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
				   AllCdFlag = data_skill:get_is_cd_all(SkillId),
				   ?ASSERT(is_record(TempSkillAttr, temp_skill_attr)),
				   BattleAttr = Status#player.battle_attr,
				   NowLong = util:longunixtime(),  %%毫秒值
				   {CostLvTimes,CostEnergy,CostPercent} =  TempSkillAttr#temp_skill_attr.cost_energy,
				   TotalEnergy = CostEnergy+ util:floor( BattleAttr#battle_attr.energy#energy.max_energy*CostPercent/100+Status#player.level * CostLvTimes),
			 	   %%检查能否消耗能量值
				   if  (BattleAttr#battle_attr.energy#energy.energy_val < TotalEnergy) ->
						   lib_player:send_tips(3102014, [], Status#player.other#player_other.pid_send) ,
						   ?TRACE("[SKILL] not enough energy of skill id ~p cost ~p player energy ~p ~n",
								  [SkillId,TotalEnergy,Status#player.battle_attr#battle_attr.energy#energy.energy_val]),
						   {false,SkillLv};  %%能量值不够
					   AllCdFlag =:= ?SKILL_ALL_CD andalso BattleAttr#battle_attr.skill_cd_all > NowLong ->
						   lib_player:send_tips(3102005, [], Status#player.other#player_other.pid_send) ,
						   ?TRACE("[SKILL]in cd of skill id ~p  ~n",[SkillId]),
						   {false,SkillLv};  %%技能CD还没有到
					   true -> 
						   {true,SkillLv} 
				   end;
			   false ->  %%未学习的技能,不能使用
				   ?TRACE("[SKILL] skill has not been learn ~n",[]),
				   lib_player:send_tips(3102018, [], Status#player.other#player_other.pid_send) ,
				   {false,0}
		   end;
	   true ->
		   ?TRACE("[SKILL] can not use passive skill ~n",[]),
		   lib_player:send_tips(3102019, [], Status#player.other#player_other.pid_send) ,
		   {false,0}
	end.

%%功能: 检查战斗过程怪的技能是否可用.
%%返回: true 技能可用, false 技能不可用
%%      对怪只检查技能CD  这里不修改任何战斗属性
check_skill_usable(BattleAttr, SkillId, _SkillLv) ->
%%     TempSkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
%%     ?ASSERT(is_record(TempSkillAttr, temp_skill_attr)),
    NowLong = util:longunixtime(),  %%毫秒值
    IsFightable = battle_util:check_fightable(BattleAttr,SkillId),
    %%检查是否需要消耗怒气值及法力值
    if BattleAttr#battle_attr.skill_cd_all > NowLong ->
           false;  %%技能CD还没有到
       BattleAttr#battle_attr.sing_expire > NowLong ->
           false;  %%吟唱时间中
       IsFightable =:= false ->
          false; 
       true ->
           %%检查是否有技能CD组
           case lists:keyfind(SkillId, 1, BattleAttr#battle_attr.skill_cd_list) of
               {SkillId, ExpireTime} ->
                   NowLong >= ExpireTime;
               false ->
                   true
           end
    end.
    
%%功能: 战斗过程玩家技能Buff处理,需要计算伤害前调用
%%返回: 新的玩家Status, 更新后战斗记录BattleAttr 
%%      2: 已过期的Buff解除, 应用周期性技能BUFF
%%      3: CD处理
update_player_battle_attr(Status, SkillId,SkillLv) ->   
	BattleAttr = Status#player.battle_attr,
	SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
	?ASSERT(is_record(SkillAttr, temp_skill_attr)),
	NowLong = util:longunixtime(),    
	{CostTimers,CostEnergy,CostPercent} = SkillAttr#temp_skill_attr.cost_energy,
	TotalEnergy = CostEnergy+ util:floor( BattleAttr#battle_attr.energy#energy.max_energy*CostPercent/100+CostTimers*Status#player.level),
	NewEnergy = BattleAttr#battle_attr.energy#energy{
													 energy_val = max(0,BattleAttr#battle_attr.energy#energy.energy_val-TotalEnergy)
													},
	BattleAttr1 = BattleAttr#battle_attr{
										 energy = NewEnergy
										}, 
	%%CD处理: 
	NewBattleAttr = update_skill_cd(BattleAttr1, SkillId, NowLong), 
	Status#player{battle_attr = NewBattleAttr}.

%%功能: 战斗过程怪的技能处理,需要计算伤害前调用
%%返回: 新的战斗属性Status
%%      1: 扣除技能消耗的怒气值
%%      2: 已过期的Buff解除, 应用周期性的技能BUFF
%%      3: CD处理
update_mon_battle_attr(BattleAttr, SkillId, SkillLv) -> 
	BattleAttr1 = BattleAttr,
    NowLong = util:longunixtime(),  %%毫秒值
    {_SingBreak,SingTime} = data_skill:get_sing(SkillId),
    if 
       SingTime > 0 -> %%检查是否有吟唱时间, 有就加上
            BattleAttr1#battle_attr{sing_expire = NowLong + SingTime};
       NowLong >= BattleAttr1#battle_attr.sing_expire ->  %%吟唱时间已到,清为0
            BattleAttr1#battle_attr{sing_expire = 0};
       true ->
            BattleAttr1
    end.

%%群体攻击技能Buff处理(技能Buff对被攻击方所有人)
%%参数:　SkillId, SkillLv为攻方技能
%%　     DefendList为守方战斗结构列表
%%返回: NewDefendList
update_defend_battle_attr(SkillId, SkillLv, BattleAttrList) when is_list(BattleAttrList) ->
    ?ASSERT(data_skill:get_type(SkillId) =:= 2),
    NowLong = util:longunixtime(),
    SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
    ?ASSERT(is_record(SkillAttr, temp_skill_attr)),
    %%应用新BUFF
    F = fun(BattleAttr) ->
        buff_util:active_skill_buff(BattleAttr, SkillAttr#temp_skill_attr.buff, NowLong)
    end,
    lists:map(F, BattleAttrList);

%%单体攻击技能Buff处理(技能Buff对被攻击方)
%%参数:　SkillId, SkillLv为攻方技能
%%　　　 Defend为守方战斗结构信息
%%返回:  NewDefend
update_defend_battle_attr(SkillId, SkillLv, BattleAttr) ->
    ?ASSERT(data_skill:get_type(SkillId) =:= 1),
    NowLong = util:longunixtime(),
    SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
    ?ASSERT(is_record(SkillAttr, temp_skill_attr)),
    %%应用新BUFF
    buff_util:active_skill_buff(BattleAttr, SkillAttr#temp_skill_attr.buff, NowLong).


%%群体辅助技能Buff处理(技能Buff对已方所有人)
%%参数:　SkillId, SkillLv为攻方技能
%%　　　 AttackList为攻方战斗结构列表
%%返回:  NewAttackList
%% update_attack_battle_attr(SkillId, SkillLv, BattleAttrList) when is_list(BattleAttrList) ->
%%     %%?ASSERT(data_skill:get_type(SkillId) =:= 4),
%%     NowLong = util:longunixtime(),
%%     SkillAttr = tpl_skill_attr:get(SkillId, SkillLv), 
%%     ?ASSERT(is_record(SkillAttr, temp_skill_attr)),
%%     %%应用新BUFF
%%     F = fun(BattleAttr) ->  
%%         {NewBattleAttr,_} = buff_util:active_skill_buff(BattleAttr,SkillLv, SkillAttr#temp_skill_attr.buff, NowLong)   ,
%% 		NewBattleAttr
%%     end,
%%     lists:map(F, BattleAttrList);

%%单体辅助技能Buff处理(技能Buff对自己)
%%参数:　SkillId, SkillLv为攻方技能
%%　　　 Attack为战斗结构
%%返回:  NewAttack
update_attack_battle_attr(BuffList, SkillLv, BattleAttr) ->
    %%?ASSERT(data_skill:get_type(SkillId) =:= 3),
    NowLong = util:longunixtime(), 
    %%应用新BUFF
    buff_util:active_skill_buff(BattleAttr,SkillLv, BuffList, NowLong).

%%功能: 通知战斗开始, 设置玩家战斗技能状态 
%%返回: 新的玩家Status, 更新后战斗记录BattleAttr
%%      1: 清理战斗记录的skill_cd_list, skill_cd_all
%%      2: 清空skill_buff列表
%% clear_player_battle_attr(Status) -> 
%%     NewBattleAttr = clear_battle_attr(Status#player.battle_attr),
%%     Other = Status#player{battle_attr = NewBattleAttr},
%%     Status#player{other = Other}.


%%在自身身上应用攻击技能上的buff
%%AttrBattleAttr 攻击目标战斗属性
apply_self_skill_buff(_,[],_)->
	skip;
apply_self_skill_buff(Ps,SelfBuff,Skillinfo)->    
	NowLong = util:longunixtime(),     
	buffer_call_back({?ELEMENT_PLAYER,Ps#player.id,Ps#player.battle_attr},Ps#player.other#player_other.pid,SelfBuff,[],Skillinfo,NowLong). 
apply_skill_buff(_,_,[],[],_,_)->
	skip; 
apply_skill_buff(?SKILL_TYPE_DEMAGE,DefendList,BuffList,RepelList,AttrStatus,SkillInfo)->	  
	NowLong = util:longunixtime(),
	lists:map(fun({DefendType,DefendId,_,_,_,_,_})->
					  Status =  battle_util:get_status(DefendId, DefendType) ,   
					  case Status of
						  []-> 
							  skip;
						  _-> 
							  do_apply_skill_buff(AttrStatus,Status,BuffList,RepelList,SkillInfo,NowLong)
					  end
			  end , DefendList);
%%应用非攻击技能上的buff
apply_skill_buff(?SKILL_TYPE_NODEMAGE,DefendInfo,BuffList,RepelList,AttrStatus,SkillLv)->	  
	NowLong = util:longunixtime(),
	{MonsterList,PlayerList,_,_} =  DefendInfo,  
	lists:map(fun(Monster)-> 
					  do_apply_skill_buff(AttrStatus,Monster,BuffList,RepelList,SkillLv,NowLong)
			  end , MonsterList),  
	lists:map(fun(Player)->  
					  do_apply_skill_buff(AttrStatus,Player,BuffList,RepelList,SkillLv,NowLong)
			  end , PlayerList).
%%buff效果计算
do_apply_skill_buff(AttrStatus,DefendStatus,BuffList,RepelList,SkillInfo,NowLong) when is_record(DefendStatus, temp_mon_layout)-> 
	if DefendStatus#temp_mon_layout.battle_attr#battle_attr.hit_point > 0->
		   {_,_,AttrBattleAttr} = battle_util:get_attr_status(AttrStatus),
		   {SkillId,SkillLv,SesssionId} = SkillInfo, 
		   MapId = DefendStatus#temp_mon_layout.scene_id div 100,   
		   {NewBattleAttr0,RepelInfo} = battle_util:do_repel(MapId,AttrBattleAttr,DefendStatus#temp_mon_layout.battle_attr,RepelList,[]),  
		   {NewBattleAttr1,BuffInfo} = buff_util:active_skill_buff(NewBattleAttr0,SkillLv,BuffList, NowLong),   
		   {NewBattleAttr2,{TotalDamage,DemageInfo}} = buff_util:apply_damage_buff(AttrBattleAttr,NewBattleAttr1,NewBattleAttr1#battle_attr.demage_buff_list,SkillInfo,{0,[]}), 
		   {PosX,PosY} = util:get_xy_slice(NewBattleAttr2#battle_attr.x, NewBattleAttr2#battle_attr.y),
		   PlayerIdList = lib_scene:get_zone_playerlist(DefendStatus#temp_mon_layout.scene_id,PosX,PosY),    
		   PlayerSendPidList = lib_send:get_player_send_pid(PlayerIdList,[]), 
		   if NewBattleAttr2#battle_attr.remove_buff_list =/= [] ->
				  {NewBattleAttr3,RemoveBuff} = buff_util:remove_skill_buff_by_id(DefendStatus#temp_mon_layout{battle_attr = NewBattleAttr2}),
				  gen_server:cast(  mod_scene_agent:get_agent_pid(), {apply_cast,buff_util,broadcast_reflesh_remove_skill_buff_4_mon,
																	  [PlayerSendPidList,?ELEMENT_MONSTER, DefendStatus#temp_mon_layout.id,NewBattleAttr3,RepelInfo++BuffInfo++DemageInfo,RemoveBuff]}),
				  buffer_call_back(AttrStatus,NewBattleAttr3,DefendStatus,SkillLv) ;
			  true -> 
				  gen_server:cast(  mod_scene_agent:get_agent_pid(), {apply_cast,buff_util,broadcast_new_skill_buff_4_mon,
																	  [PlayerSendPidList,?ELEMENT_MONSTER, DefendStatus#temp_mon_layout.id,NewBattleAttr2,RepelInfo++BuffInfo++DemageInfo]}),
				  buffer_call_back(AttrStatus,NewBattleAttr2,DefendStatus,SkillLv) 
		   end;
	   true ->
		   skip
	end; 
do_apply_skill_buff(AttrStatus,DefendStatus,BuffList,RepelList,SkillInfo,NowLong) when is_record(DefendStatus, player)->
 	if DefendStatus#player.battle_attr#battle_attr.hit_point > 0->
		   AttrInfo = battle_util:get_attr_status(AttrStatus),  
		   buffer_call_back(AttrInfo,DefendStatus#player.other#player_other.pid,BuffList,RepelList,SkillInfo,NowLong);
	   true ->
		   skip
	end.
%%刷新对象buff保存对象信息(人)
buffer_call_back(AttrInfo,DefendPid,BuffList,RepelList,SkillLv,NowLong)->   
	gen_server:cast(DefendPid, {battle_buff_callback,AttrInfo,BuffList,RepelList,SkillLv,NowLong}). 
%%刷新对象buff保存对象信息(怪)
buffer_call_back(MonLayoutStatus,BattleAttr,OldMonsterStatus,SkillLv) when is_record(MonLayoutStatus, temp_mon_layout)->
	{NewMonsterStatus,_,_} = monster_buff_call_back(BattleAttr,OldMonsterStatus,SkillLv),  
	lib_mon:save_monster(NewMonsterStatus) ;
buffer_call_back(Ps,BattleAttr,OldMonsterStatus,SkillLv) ->
	{NewMonsterStatus,LeftHp,NewDamageValue} = monster_buff_call_back(BattleAttr,OldMonsterStatus,SkillLv), 
	lib_battle:save_monster_in_scene
(Ps, NewMonsterStatus#temp_mon_layout{pos_x = NewMonsterStatus#temp_mon_layout.battle_attr#battle_attr.x,
									  pos_y = NewMonsterStatus#temp_mon_layout.battle_attr#battle_attr.y},LeftHp,NewDamageValue).  

%应用buff后更新怪物状态
monster_buff_call_back(BattleAttr,OldMonsterStatus,SkillLv)-> 
	{NewBattleAttr,LinkSkill} = start_trigger_buff_skill(BattleAttr,SkillLv),
	LeftHp = NewBattleAttr#battle_attr.hit_point,
	NewMonsterStatus = OldMonsterStatus#temp_mon_layout{ battle_attr = NewBattleAttr },
	lists:foreach(fun({SkillId,SkillLv})->
						  buff_trigger_single_monster_skill(NewMonsterStatus,0,-1,SkillId,SkillLv)
				  end, LinkSkill), 
 	lib_scene:reflesh_monster_skill_timer(OldMonsterStatus#temp_mon_layout.id,NewBattleAttr#battle_attr.timer_buff++NewBattleAttr#battle_attr.buff1++NewBattleAttr#battle_attr.skill_buff++NewBattleAttr#battle_attr.buff2),
	NewDamageValue = OldMonsterStatus#temp_mon_layout.battle_attr#battle_attr.hit_point - LeftHp , 
	{OldMonsterStatus#temp_mon_layout{battle_attr = NewBattleAttr},LeftHp,NewDamageValue}.

%------------------------
%- dot 类buff使用
%------------------------
start_timer_buffer(BattleAttr) when BattleAttr#battle_attr.buff2 =/= [] andalso BattleAttr#battle_attr.buff_timer_start =:= false ->
	io:format("start_timer_buffer ~n"),
	self()!'BUFFER_TIMER',  
	BattleAttr#battle_attr{
						   buff_timer_start = true
						  };
start_timer_buffer(BattleAttr)->
	BattleAttr.


%-------------------------
%- 	buff触发技能(通用)
%-------------------------
start_trigger_buff_skill(BattleAttr,SkillLv)->    
	if BattleAttr#battle_attr.link_skill_buff =/= [] ->
		 buff_trigger_skill(BattleAttr,BattleAttr#battle_attr.link_skill_buff,[],SkillLv);
	   true ->  
		   {BattleAttr,[]}
	end. 

%buff触发单次技能
buff_trigger_single_skill(Ps,TarId,TarType,SkillId,SkillLv,SessionId)->
	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->   
			mod_dungeon:start_trigger_skill(Ps,TarId,TarType,SkillId,SkillLv,SessionId);
		false ->  
			mod_scene:start_trigger_skill(Ps,TarId,TarType,SkillId,SkillLv,SessionId)
	end  .
%buff触发单次怪物技能
buff_trigger_single_monster_skill(Monster,TarId,TarType,SkillId,SkillLv)->
	try
		gen_server:cast(self(), {apply_cast, lib_battle, auto_trigger_monster_skill, [Monster,TarId,TarType,SkillId,SkillLv]}) 
	catch
		_:_ -> []
	 end .
%循环触发技能
buff_trigger_skill(BattleAttr,[BuffId|Rest],LinkSkill,SkillLv)->
	?TRACE("[buff_trigger_skill] buff_trigger_skill ~p ~n",[[BuffId|Rest]]),
	TplBuff = tpl_buff:get(BuffId),
	NewBattleAttr = case TplBuff#temp_buff.trigger_type of
						?BUFF_TRIGGER_ONCE -> %%单次触发类buff 
							NewLinkSkill  = lists:map(fun(SkillId)->
															  {SkillId,SkillLv}
													  end,TplBuff#temp_buff.link_skill) ++LinkSkill,
							BattleAttr;
						?BUFF_TRIGGER_TIMER ->%%时间触发类buff 
							{LinkSkillList,TimerBuffInfoList}=lists:foldl(fun(SkillId,{TempLinkSkill,NewTimerBuffInfoList})-> 
																  NewTimerBuffInfo = make_timer_buff_info(TplBuff,SkillId,SkillLv),
																  {[{SkillId,SkillLv}|TempLinkSkill],[NewTimerBuffInfo]++lists:keydelete(SkillId, 1,NewTimerBuffInfoList)} 
														  end, {[],BattleAttr#battle_attr.timer_buff},TplBuff#temp_buff.link_skill),  
							NewLinkSkill  =  LinkSkillList++LinkSkill,
					 		BattleAttr#battle_attr{
												   timer_buff = TimerBuffInfoList
												  };
						?BUFF_TRIGGER_HURTED ->%%受击触发类buff
							HurtedBuffInfoList = lists:foldl(fun(SkillId,NewHurtedBuffInfoList)->
																	 NewHurtedBuffInfo = make_hurted_buff_info(TplBuff,SkillId,SkillLv),
																	 [NewHurtedBuffInfo]++lists:keydelete(SkillId, 1,NewHurtedBuffInfoList)
															 end,[],TplBuff#temp_buff.link_skill), 
							NewLinkSkill = LinkSkill,
							?TRACE("[SKILL] HURT SKILL ~p ~n",[HurtedBuffInfoList]),
							BattleAttr#battle_attr{
												   hurted_buff = HurtedBuffInfoList++BattleAttr#battle_attr.hurted_buff
												  };
						_->
							?TRACE("[BUFF_WARNING] UNKNOW trigger type ~p of buff ~p ~n",[TplBuff#temp_buff.trigger_type,TplBuff#temp_buff.buff_id]),
							NewLinkSkill = LinkSkill,
							BattleAttr
					end	, 
 	buff_trigger_skill( NewBattleAttr ,Rest,NewLinkSkill,SkillLv);
buff_trigger_skill(BattleAttr,[],LinkSkill,_)->  
	NewBattleAttr = BattleAttr#battle_attr{
													  link_skill_buff = []
													 },
	FinalBattleAttr = trigger_timer_buff(NewBattleAttr), 
	{FinalBattleAttr,LinkSkill}.
%%构造时间计时器信息
make_timer_buff_info(TplBuff,SkillId,SkillLv)->   
	TriggerRate = util:floor(TplBuff#temp_buff.last_time/TplBuff#temp_buff.times),
	Now = util:longunixtime(),
	{SkillId,SkillLv,Now+TplBuff#temp_buff.last_time,TriggerRate,Now}.
%%构造被击触发器信息
make_hurted_buff_info(TplBuff,SkillId,SkillLv)->
	Now = util:longunixtime(),  
	{SkillId,SkillLv,Now+TplBuff#temp_buff.last_time}.
%%触发技能计时器
trigger_timer_buff(BattleAtte) when BattleAtte#battle_attr.timer_buff =/= [] andalso BattleAtte#battle_attr.buff_timer_start =:= false->  
		io:format("trigger_timer_buff ~n"),
	self()!'BUFFER_TIMER',  
	BattleAtte#battle_attr{
									  buff_timer_start = true
									 };
trigger_timer_buff(BattleAtte)  -> 
 	BattleAtte.
%%在buff第一次触发技能时立马施放一次该技能
%%暂支持单次触发类buff与时间触发类buff
trigger_link_skill(_,[],_,_)->
	skip;
trigger_link_skill(Ps,LinkSkill,TarId,TarType)-> 
	Now = util:longunixtime(),
	lists:foreach(fun({SkillId,SkillLv})->
						  buff_trigger_single_skill(Ps,TarId,TarType,SkillId,SkillLv,Now)
				  end,LinkSkill).

%%定期扫描时间触发类buff(通用)
%%1.移除过期的buff
%%2.更新有效的buff
%%3.计算合适的计时器 
reflesh_timer_skill_info(BattleAttr,SkillList,[TimerBuffInfo|Rest],Now)-> 
	{SkillId,SkillLv,ExpriedTime,TriggerRate,LastTrigger} = TimerBuffInfo, 
	Flag = Now+50-LastTrigger,  
	{NewTimerBuff,NewSkillList} = if Now >= ExpriedTime ->%移除过期的技能
										 ?TRACE("[BUFF] remove timer buff -> ~p ~n",[SkillId]),
										 {lists:keydelete(SkillId, 1, BattleAttr#battle_attr.timer_buff),SkillList} ;
									 Flag >= TriggerRate ->%触发满足条件的技能
										 ?TRACE("[BUFF] trigger_timer_skill current rate ~p ~n",[TriggerRate]),
 
										 {lists:keyreplace(SkillId, 1,BattleAttr#battle_attr.timer_buff, {SkillId,SkillLv,ExpriedTime,TriggerRate,Now}),[{SkillId,SkillLv}|SkillList]} ;
									 true ->%%时间未到的buff 
										 {BattleAttr#battle_attr.timer_buff,SkillList}
								  end,  
	NewBattleAttr = BattleAttr#battle_attr{
										   timer_buff = NewTimerBuff
										  } , 
	reflesh_timer_skill_info(NewBattleAttr,NewSkillList,Rest,Now);
reflesh_timer_skill_info(BattleAttr,SkillList,[],_)->
	if BattleAttr#battle_attr.timer_buff =:= [] andalso BattleAttr#battle_attr.buff2 =:= []->  
			NewBattleAttr = BattleAttr#battle_attr{
									  buff_timer_start = false
									 },
			{NewBattleAttr, SkillList};
		true->
			{BattleAttr,SkillList}
	end	.
%%获取时间触发类buff对应的可触发技能 
get_trigger_timer_skill(BattleAttr,SkillList,[{SkillId,ExpriedTime,TriggerRate,LastTrigger}|Rest])->
	Now = util:longunixtime(),
	Flag = Now-LastTrigger,  
	{NewBattleAttr,NewSkillList} = if Flag >= TriggerRate -> 
								  ?TRACE("[BUFF] trigger_timer_skill ~n",[]),
								  NewTimerTrigger = lists:keyreplace(SkillId, 1,BattleAttr#battle_attr.timer_buff, {SkillId,ExpriedTime,TriggerRate,Now}),
								  TempBattleAttr = BattleAttr#battle_attr{
																					timer_buff = NewTimerTrigger
																				   },  
								  { TempBattleAttr ,[SkillId]++SkillList}  ;
							  true ->
								  {BattleAttr,SkillList}
						   end,
	get_trigger_timer_skill(NewBattleAttr,NewSkillList,Rest);
get_trigger_timer_skill(BattleAttr,NewSkillList,[])->
	{BattleAttr,NewSkillList}.

%----------------------
%-	职业被动分流技能
%----------------------
%%初始化玩家职业被动技能
init_passive_skill(Ps)->
	NewBattleAttr = lists:foldl(fun({SkillId,SkillLv},BattleAttr)->
										SkillTpl = tpl_skill:get(SkillId),
										if SkillTpl#temp_skill.type =:= ?SKILL_PASSIVE ->
											   TplSkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
											    case TplSkillAttr#temp_skill_attr.buff of
												   []->BattleAttr;
												   List ->
													   lists:foldl(fun(BuffId,TempBattleAttr)->
																		   TplBuff = tpl_buff:get(BuffId),
																		   add_passive_effect(TempBattleAttr,TplBuff#temp_buff.data,SkillLv)
																   end, BattleAttr , List)
											   end;
										   true ->
											   BattleAttr
										end
								end, Ps#player.battle_attr,Ps#player.other#player_other.skill_list),
	FinalBattleAttr = apply_lv_passive_effect(Ps#player{battle_attr = NewBattleAttr}), 
	Ps#player{battle_attr = FinalBattleAttr}.
  
add_passive_effect(BattleAttr,[{Effect,Times,AbsValue}|Rest],SkillLv)-> 
	NewBattleAttr = BattleAttr#battle_attr{
										   passive_skill_attr =[{Effect,0,Times*SkillLv+AbsValue}|BattleAttr#battle_attr.passive_skill_attr] 
										  },
	add_passive_effect(NewBattleAttr,Rest,SkillLv);
add_passive_effect(BattleAttr,[],_)->
	BattleAttr.   

apply_lv_passive_effect(Ps)->
   lists:foldl(fun({Effect,LastVal,AddVal},TempBattleAttr)->
										case Effect of
											hp_max_call_back ->
												NewValue =TempBattleAttr#battle_attr.hit_point_max-LastVal + Ps#player.level*AddVal,
												?TRACE("[LV_PASSIVE] old hp ~p new hp ~p ~n",[ TempBattleAttr#battle_attr.hit_point,NewValue]),
												if NewValue < TempBattleAttr#battle_attr.hit_point ->
													   TempBattleAttr#battle_attr{
																				  hit_point = NewValue,
																				  hit_point_max = NewValue
																				 };
												   true ->
												?TRACE("[LV_PASSIVE] old hp ~p new hp ~p ~n",[ TempBattleAttr#battle_attr.hit_point,NewValue]),
													   TempBattleAttr#battle_attr{ 
																				  hit_point_max = NewValue
																				 }
												end; 
											_->
												TempBattleAttr
										end
								end
								, Ps#player.battle_attr, Ps#player.battle_attr#battle_attr.passive_skill_attr).
%%根据玩家当前生命值刷新被动分流效果
passive_skill_call_back(BattleAttr)->
	case BattleAttr#battle_attr.hit_point_max of
		0->
			{[],BattleAttr};
		_->
			LostHpPrecent = data_battle:get_lost_hp(BattleAttr#battle_attr.hit_point_max, BattleAttr#battle_attr.hit_point),
			reflesh_passive_skill_attr(BattleAttr,BattleAttr#battle_attr.passive_skill_attr,LostHpPrecent,[]) 
	end.    

%%刷新具体被动分流效果
reflesh_passive_skill_attr(BattleAttr,[],_,ResultInfoList)->
	{ResultInfoList,BattleAttr};
reflesh_passive_skill_attr(BattleAttr,[{Effect,LastVal,Times}|Rest],LostHpPrecent,ResultInfoList)->
	{NewResultInfoList,NewBattleAttr} = case Effect of 
		attack_callback ->%%失去多少百分比血，增加多少攻击力
			NewAddVal = util:ceil(Times*LostHpPrecent),  
			{ResultInfoList,BattleAttr#battle_attr{attack = BattleAttr#battle_attr.attack-LastVal+NewAddVal,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		hp_cover_call_back->%%失去多少百分比血，增加多少生命恢复效果
			NewAddVal = util:ceil(Times*LostHpPrecent),   
			NewHpCallBack = BattleAttr#battle_attr.hp_cover_callback  - LastVal + NewAddVal,
			{ResultInfoList,BattleAttr#battle_attr{hp_cover_callback = NewHpCallBack,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		attr_speed_call_back->%%失去多少百分比血，增加多少攻击速度
			NewAddVal = util:ceil(Times*LostHpPrecent), 
			NewAttrSpeed = BattleAttr#battle_attr.attack_speed-LastVal+NewAddVal,
			ReturnInfo  = get_passive_return_info(BattleAttr#battle_attr.attack_speed,NewAttrSpeed,{?BUFF_TYPE_PROPERTY,?BUFF_EFFECT_ATTR_SPEED,NewAttrSpeed}),
		    
			{ReturnInfo++ResultInfoList,BattleAttr#battle_attr{attack_speed = NewAttrSpeed,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		move_speed_call_back->%%失去多少百分比血，增加多少移动速度
			NewAddVal = util:ceil(Times*LostHpPrecent div ?COMMON_MOVE_SPEED div 2), 
		 	NewMoveSpeed = BattleAttr#battle_attr.speed-LastVal+NewAddVal,
			ReturnInfo  = get_passive_return_info(BattleAttr#battle_attr.speed,NewMoveSpeed,{?BUFF_TYPE_PROPERTY,?BUFF_EFFECT_MOVE_SPEED,NewMoveSpeed}),
			{ReturnInfo++ResultInfoList,BattleAttr#battle_attr{speed = NewMoveSpeed,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		control_radio_call_back->%%失去多少百分比血，增加多少控制几率
			NewAddVal = util:ceil(Times*LostHpPrecent), 
			{ResultInfoList,BattleAttr#battle_attr{control_radio = BattleAttr#battle_attr.control_radio-LastVal+NewAddVal,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		hurt_call_back_rate ->%%失去多少百分比血，增加多少反伤比例
			NewAddVal = util:ceil(Times*LostHpPrecent),
			{ResultInfoList,BattleAttr#battle_attr{passive_hurt_rate = BattleAttr#battle_attr.passive_hurt_rate-LastVal+NewAddVal,
								   passive_skill_attr = lists:keyreplace(Effect, 1, BattleAttr#battle_attr.passive_skill_attr, {Effect,NewAddVal,Times})}};
		_->
			{ResultInfoList,BattleAttr}
	end, 
	reflesh_passive_skill_attr(NewBattleAttr,Rest,LostHpPrecent,NewResultInfoList).  

get_passive_return_info(LastVal,LastVal,_)->
	[];
get_passive_return_info(_,_,ReturnInfo)->
	[ReturnInfo].

%%升级被动技能时改变玩家被动分流属性
update_passive_skill(BattleAttr,TplSkill,SkillLv) when TplSkill#temp_skill.type =:= ?SKILL_PASSIVE ->
	TplSkillAttr = tpl_skill_attr:get(TplSkill#temp_skill.sid, SkillLv),
	case TplSkillAttr#temp_skill_attr.buff of
		[]->BattleAttr;
		List ->
			lists:foldl(fun(BuffId,NewBattleAttr)->
								TplBuff = tpl_buff:get(BuffId),
								NewPassiveList = update_passive_skill_effect(TplBuff#temp_buff.data,NewBattleAttr#battle_attr.passive_skill_attr,SkillLv),
								NewBattleAttr#battle_attr{passive_skill_attr = NewPassiveList}
						end,BattleAttr , List)
	end;
update_passive_skill(BattleAttr,_,_)->
	BattleAttr.

													   
update_passive_skill_effect([{Effect,Times,AdsVal}|Rest],PassiveSkillList,SkillLv)->
	NewPassiveSkillList =  case lists:keyfind(Effect,1,PassiveSkillList) of
							   {Effect,LastVal,_} ->
								   lists:keyreplace(Effect, 1, PassiveSkillList, {Effect,LastVal,Times*SkillLv+AdsVal});
							   false ->
								   [{Effect,0,Times*SkillLv+AdsVal}|PassiveSkillList]
						   end,
	update_passive_skill_effect(Rest,NewPassiveSkillList,SkillLv);
update_passive_skill_effect([],NewPassiveSkillList,_)->
	NewPassiveSkillList.

borcast_passive_skill_effect(_,_,[])->
	skip;
borcast_passive_skill_effect(Ps,NewBattleAttr,BuffList)->
	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->   
			buff_util:broadcast_new_skill_buff_in_dungeon(?ELEMENT_PLAYER, Ps#player.id,Ps#player.other#player_other.pid_send, NewBattleAttr,BuffList);
		false ->  
			gen_server:cast(mod_scene_agent:get_agent_pid(), 
							{apply_cast, buff_util, broadcast_new_skill_buff,
							 [Ps#player.scene,?ELEMENT_PLAYER, Ps#player.id,NewBattleAttr,BuffList]}) 
	end.
%-----------------------
%-	受击触发buff技能  
%-----------------------  
reflesh_hurted_trigger_buff(BattleAttr,Now)->
		 	NewHurtList = lib_skill:check_hurted_trigger_buff(BattleAttr#battle_attr.hurted_buff,[],Now),
		    BattleAttr#battle_attr{
																  hurted_buff = NewHurtList
																 }.
%%清除过期的受伤buff(通用)
check_hurted_trigger_buff([{SkillId,SkillLv,ExpriedTime}|Rest],HurtSkill,Now)-> 
	if Now > ExpriedTime ->
		   check_hurted_trigger_buff(Rest,HurtSkill,Now);
	   true ->
		   NewHurtSkill = [{SkillId,SkillLv,ExpriedTime}|HurtSkill],
		   check_hurted_trigger_buff(Rest,NewHurtSkill,Now)
	end;
check_hurted_trigger_buff([],HurtSkillList,_)->
	HurtSkillList.
%%刷新怪物时间触发类技能
reflesh_mon_timer_skill(Monster,Now)when is_record(Monster, temp_mon_layout)->
	{NewBattleAttr1,SkillList} = reflesh_timer_skill_info(Monster#temp_mon_layout.battle_attr,[],Monster#temp_mon_layout.battle_attr#battle_attr.timer_buff,Now), 
	{NewBattleAttr2,RemoveBuff,RefleshBuff} = do_check_buff(NewBattleAttr1,Now),  
	{PosX,PosY} = util:get_xy_slice(NewBattleAttr2#battle_attr.x, NewBattleAttr2#battle_attr.y),
	PlayerIdList = lib_scene:get_zone_playerlist(Monster#temp_mon_layout.scene_id,PosX,PosY),    
	PlayerSendPidList = lib_send:get_player_send_pid(PlayerIdList,[]),
	gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast, buff_util, broadcast_reflesh_remove_skill_buff_4_mon,
													  [PlayerSendPidList,?ELEMENT_MONSTER, Monster#temp_mon_layout.id,NewBattleAttr2,RefleshBuff,RemoveBuff]}),  
	 NewMonster = Monster#temp_mon_layout{battle_attr = NewBattleAttr2},
	 if NewBattleAttr2#battle_attr.buff_timer_start =/= false 
									  orelse NewBattleAttr2#battle_attr.buff1 =/= []
																			orelse NewBattleAttr2#battle_attr.skill_buff =/= []
		 																			orelse  NewBattleAttr2#battle_attr.buff2 =/= []->  
		   skip;
	   true -> 
		   lib_scene:erase_monster_skill_timer(Monster#temp_mon_layout.id)
	end, 
	lists:foreach(fun({SkillId,SkillLv})->
						  buff_trigger_single_monster_skill(NewMonster,0,-1,SkillId,SkillLv)
				  end, SkillList),
	lib_mon:save_monster(NewMonster) ;
reflesh_mon_timer_skill(_,_)->
	skip.
%%----------------------------------------------------------
%%技能内部函数
%%----------------------------------------------------------
%%功能: 战斗过程技能处理,需要计算伤害前调用
%%返回: 更新后战斗记录BattleAttr
%%      1: 扣除技能消耗的怒气值
%%      2: 已过期的Buff解除, 周期性BUFF应用
%%      3: CD处理
test() ->
	SkillAttr = tpl_skill_attr:get(5, 1),
	?ASSERT(is_record(SkillAttr, temp_skill_attr)).

update_battle_attr(BattleAttr, SkillId, SkillLv) ->
    SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
    ?ASSERT(is_record(SkillAttr, temp_skill_attr)),
    NowLong = util:longunixtime(),    
	{CostEnergy,CostPercent} = SkillAttr#temp_skill_attr.cost_energy,
	TotalEnergy = CostEnergy+ util:floor( BattleAttr#battle_attr.energy#energy.max_energy*CostPercent/100),
	NewEnergy = BattleAttr#battle_attr.energy#energy{
													 energy_val = max(0,BattleAttr#battle_attr.energy#energy.energy_val-TotalEnergy)
													 },
	BattleAttr1 = BattleAttr#battle_attr{
										 energy = NewEnergy
										 }, 
    %%CD处理: 
    NewBattleAttr = update_skill_cd(BattleAttr1, SkillId, NowLong),
    NewBattleAttr .


%%检查buff  
%%解除旧的BUFF
%%应用周期性Buff
do_check_buff(BattleAttr,NowLong)->
    {BattleAttr1,RemoveBuff} = buff_util:deactive_skill_buff(BattleAttr, NowLong),  
    {BattleAttr2,RefleshBuff} = buff_util:refresh_skill_buff(BattleAttr1, NowLong),
	{BattleAttr2,RemoveBuff,RefleshBuff}.

%%功能: 战斗结束, 解除玩家战斗技能增加的属性 
%%返回: 更新后战斗记录BattleAttr
%%      1: 清理战斗记录的skill_cd_list, skill_cd_all
%%      2: 清空skill_buff列表
%%      3: 使用连击点增加的属性攻击值
clear_battle_attr(BattleAttr) -> 
    %%去除使用的连击点增加的属性攻击值
    BattleAttr1 = 
    if BattleAttr#battle_attr.use_combopoint >= 1 ->
           case BattleAttr#battle_attr.career of
               ?CAREER_F ->  
                    BattleAttr#battle_attr{
                                 use_combopoint = 0,
                                 fattack = max(BattleAttr#battle_attr.fattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                             };
               ?CAREER_M -> 
                     BattleAttr#battle_attr{
                                 use_combopoint = 0,
                                 mattack = max(BattleAttr#battle_attr.mattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                              };
               ?CAREER_D -> 
                     BattleAttr#battle_attr{
                                 use_combopoint = 0,
                                 dattack = max(BattleAttr#battle_attr.dattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                              };
               _Other    -> 
                     BattleAttr
           end;
      true ->
          BattleAttr
    end,
    %%清理Buff
    BattleAttr2 = buff_util:clear_skill_buff(BattleAttr1),
    %%清除技能的CD及Buff列表, 吟唱时间    
    BattleAttr2#battle_attr{sing_expire = 0, skill_cd_all = 0, skill_cd_list = []}.


%%检查是否可以使用连击点
%%可以使用连击点,应用连击点到属性攻击
apply_combopoint_usage(BattleAttr, SkillId) ->
    case data_skill:get_combopoint_usage(SkillId) of
        true  ->
            %%去除上次使用的连击点增加的属性攻击值
            BattleAttr1 = 
            if BattleAttr#battle_attr.use_combopoint >= 1 ->
                   case BattleAttr#battle_attr.career of
                       ?CAREER_F ->  
                            BattleAttr#battle_attr{
                                         use_combopoint = 0,
                                         fattack = max(BattleAttr#battle_attr.fattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                                     };
                       ?CAREER_M -> 
                             BattleAttr#battle_attr{
                                         use_combopoint = 0,
                                         mattack = max(BattleAttr#battle_attr.mattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                                      };
                       ?CAREER_D -> 
                             BattleAttr#battle_attr{
                                         use_combopoint = 0,
                                         dattack = max(BattleAttr#battle_attr.dattack - BattleAttr#battle_attr.use_combopoint*100, 0)
                                      };
                       _Other1 -> 
                             BattleAttr
                   end;
              true ->
                  BattleAttr
            end,
            %%应用本次使用连击点增加属性攻击值
            if BattleAttr1#battle_attr.combopoint >= 1 ->
                   UseCombopoint = min(BattleAttr1#battle_attr.combopoint, BattleAttr1#battle_attr.combopoint_max),
                   case BattleAttr1#battle_attr.career of
                       ?CAREER_F ->  
                            BattleAttr1#battle_attr{
                                         use_combopoint = UseCombopoint,
                                         combopoint = BattleAttr1#battle_attr.combopoint - UseCombopoint,
                                         fattack = BattleAttr1#battle_attr.fattack +  UseCombopoint * 100
                                     };
                       ?CAREER_M -> 
                             BattleAttr1#battle_attr{
                                         use_combopoint = UseCombopoint,
                                         combopoint = BattleAttr1#battle_attr.combopoint - UseCombopoint,
                                         mattack = BattleAttr1#battle_attr.mattack + UseCombopoint * 100
                                      };
                       ?CAREER_D -> 
                             BattleAttr1#battle_attr{
                                         use_combopoint = UseCombopoint,
                                         combopoint = BattleAttr1#battle_attr.combopoint - UseCombopoint,
                                         dattack = BattleAttr1#battle_attr.dattack + UseCombopoint * 100
                                      };
                       _Other2 -> 
                             BattleAttr1
                   end;
               true ->
                  BattleAttr1
           end;
       false -> 
           BattleAttr
    end.

%%更新战斗技能的CD值
%%SkillCdList: [{SkillId, CdTime},...], CdTime为unixtime毫秒
update_skill_cd(BattleAttr, SkillId, Now) ->
    TempSkill = tpl_skill:get(SkillId),
    ?ASSERT(is_record(TempSkill, temp_skill)),  
    %%对所有技能CD,
    if TempSkill#temp_skill.cd_all > 0 ->
           BattleAttr#battle_attr{skill_cd_all = Now + TempSkill#temp_skill.cd_all*?MAX_ATTRACK_SPEED div BattleAttr#battle_attr.attack_speed};
       true ->
           BattleAttr#battle_attr{skill_cd_all = Now + ?SKILL_DEFAULT_CD_ALL*?MAX_ATTRACK_SPEED div BattleAttr#battle_attr.attack_speed }
    end.

%% 获取所有技能, 玩家进程调用. 其他进程不要调用
%% 参数: PlayerId 玩家ID
%% 返回: 技能记录 skill %为了调试，现在做一些修改
get_all_skill(PlayerId, Career,Lv) ->
	SkillPointTotal = lib_player:get_player_new_skill_point(Lv),
	Skill = 
		case get(player_skill) of
			undefined ->
				case db_agent_skill:get_skill(PlayerId) of
					[] -> %%默认技能是普通攻击  {DefaultSid, DefaultLv} 
						NewSkillList = data_skill:get_default_skill(Career), 
						InitSkill = #skill{ 
										   uid = PlayerId,
										   skill_list = NewSkillList,
										   cur_skill_list =NewSkillList,
										   skill_point = {0,SkillPointTotal}
										  }, 
						db_agent_skill:insert_skill(InitSkill),
						InitSkill;
					Other ->
						{SkillPointUsed,_} = Other#skill.skill_point, 
						Other#skill{skill_point = {SkillPointUsed,SkillPointTotal}}
				end;
			Data -> 
				{SkillPointUsed,_} = Data#skill.skill_point, 
				Data#skill{skill_point = {SkillPointUsed,SkillPointTotal}}
		end,
	?ASSERT(is_record(Skill, skill)),
	put(player_skill, Skill),
	Skill.

%% 回写技能数据到数据库. 仅玩家进程调用. 
%% PlayerId 玩家ID
write_back_skill() ->
    case get(player_skill) of
        undefined ->
            skip;
        Skill -> 
            db_agent_skill:update_skill(Skill)
    end.

%%清空已学的所有技能
clean_all_skill(Ps)-> 
	OldSkill = get(player_skill),
	NewSkillList = data_skill:get_default_skill(Ps#player.career),
	NewSkill = OldSkill#skill{ 
							  skill_list = NewSkillList,
							  cur_skill_list =NewSkillList
							 },
	db_agent_skill:update_skill(NewSkill),
	put(player_skill, NewSkill),
	F = fun({SkillId, Level}, SkillList) ->  
				case data_skill:is_normal_attr(SkillId) of   
					true -> SkillList;                      %%0为普通技能,不发到客户端
					_ -> [[SkillId, Level] | SkillList]
				end 
		end,
	FinalSkillList = lists:foldr(F, [],NewSkillList),
	io:format("~n [CLEAN] TTTTTTTTT ~p ~n",[FinalSkillList]),
	pp_skill:pack_and_send(Ps, 21000, [FinalSkillList,NewSkill#skill.skill_point]),
	NewPlayerOther = Ps#player.other#player_other{skill_list = NewSkillList},
	Ps#player{other = NewPlayerOther}.

%%检查技能ID是否有效, 有效返回true,否则false
check_skill_id(SkillId) ->
    SkillTemp = tpl_skill:get(SkillId),
    is_record(SkillTemp, temp_skill).
 
%%检测是否被动技能
check_skill_type(SkillId)->
	TplSkill = tpl_skill:get(SkillId),
	TplSkill#temp_skill.type =:= ?SKILL_PASSIVE.

%%检查技能ID,等级是否有效,有效返回true,否则false
check_skill_lv(SkillId, SkillLv) ->
    SkillTemp = tpl_skill:get(SkillId),
    SkillAttr = tpl_skill_attr:get(SkillId, SkillLv),
    is_record(SkillTemp, temp_skill) andalso is_record(SkillAttr, temp_skill_attr).

%%检查技能是否可学, 检查技能类型, 职业限制, 等级要求
%%可以学习返回 true, 否则返回 false
check_skill_learnable(Status, SkillId, Lv) ->  
    TempSkill = tpl_skill:get(SkillId),
    TempSkillAttr = tpl_skill_attr:get(SkillId, Lv),
    is_record(TempSkill, temp_skill) andalso 
    is_record(TempSkillAttr, temp_skill_attr) andalso
  %  (TempSkill#temp_skill.type =/= 0) andalso  %%可以学习的技能技能(普通默认技能不用学习)
    (TempSkill#temp_skill.stype =:= 1) andalso %%玩家技能
    ((TempSkill#temp_skill.career =:= 0) orelse (Status#player.career =:= TempSkill#temp_skill.career)) andalso
    (Status#player.level >= TempSkillAttr#temp_skill_attr.learn_level).

%%检查技能是否可以升级
check_skill_upgrade(Status, CurSkillList, {SkillId, Lv}) ->
   TempSkillAttr = tpl_skill_attr:get(SkillId, Lv), 
   ?TRACE("[TEST CONDITION] ~p ~n",[{ is_record(TempSkillAttr, temp_skill_attr),
											(Status#player.level >= TempSkillAttr#temp_skill_attr.learn_level),
												 check_skill_requirement(CurSkillList, TempSkillAttr#temp_skill_attr.require_list)	}]),
   is_record(TempSkillAttr, temp_skill_attr) andalso
   (Status#player.level >= TempSkillAttr#temp_skill_attr.learn_level) andalso
   check_skill_requirement(CurSkillList, TempSkillAttr#temp_skill_attr.require_list).

check_passive_skill_upgrade(Status, CurSkillList, {SkillId, Lv}) ->
	TempSkillAttr = tpl_skill_attr:get(SkillId, Lv),  
   is_record(TempSkillAttr, temp_skill_attr) andalso
   (Status#player.level >= TempSkillAttr#temp_skill_attr.learn_level) .

%%学习技能时检查: 检查当前技能列表是否满足要求的技能列表
%%满足时返回true, 否则false
check_skill_requirement(_CurSkillList, []) ->
	true;
check_skill_requirement(CurSkillList, [{SkillId, SkillLv}|T]) ->
	case lists:keyfind(SkillId, 1,  CurSkillList) of
		{SkillId, Lv} ->
			if Lv >= SkillLv ->
				   check_skill_requirement(CurSkillList, T); %%满足,比较下一个技能要求
			   true ->
				   false   %%等级不满足
			end;
		false ->
			false       %%技能未学习,不满足
	end.
%清除所有技能buff
remove_all_skill_buffer_when_dead(Ps) when Ps#player.battle_attr#battle_attr.hit_point =:= 0->
	BattleAttr0 = Ps#player.battle_attr#battle_attr{
													demage_buff_list = [],
													timer_buff = [],
													buff_timer_start = false
												   },
	{BattleAttr1,RemoveBuff} = buff_util:deactive_skill_buff(BattleAttr0, util:longunixtime()+1380096070781),
 	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->    
			buff_util:broadcast_reflesh_skill_buff_in_dungeon(?ELEMENT_PLAYER,Ps#player.id,Ps#player.other#player_other.pid_send, BattleAttr1,[],RemoveBuff);
		false ->   
			gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast, buff_util, broadcast_reflesh_remove_skill_buff, [Ps#player.scene,?ELEMENT_PLAYER,Ps#player.id,BattleAttr1,[],RemoveBuff]})
	end, 
	Ps#player{battle_attr = BattleAttr1};
remove_all_skill_buffer_when_dead(Ps) ->
	Ps.

	%{BattleAttr1,RemoveBuff} =
	
