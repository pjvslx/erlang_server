%%%--------------------------------------
%%% @Module  : battle_util
%%% @Author  : jack
%%% @Created : 
%%% @Description:战斗处理 
%%%--------------------------------------
-module(battle_util).
-export(
    [
	    get_defend_obj_lists/5,
	 	get_battle_type/2,    
		get_status/2,
		init_battle_info/2,
		init_pet_battle_info/2,
		check_att_area/5,
		check_attack_range/5,
		get_attack_postion/2,
		get_attack_postion/3,
		check_pvp_condition/4,
		get_attack_skill/4,
		get_relation_charge_fun/1,
		get_attr_status/1,
		do_repel/5,
		do_rush/5,
		get_defend_mon_list/6,
		get_defend_player_list/7,
		check_define_status/6,
		check_fightable/2,
		get_battle_info/2,
		make_defend_tpl_list/1,
		defend_redunction_call_back/3
    ]
).


-include("debug.hrl").
-include("common.hrl").
-include("record.hrl").
-include("battle.hrl").


-define(BATTLE_LEVEL,25). %新手保护级别 

%%回春术等构造受击列表
make_defend_tpl_list(DefendInfo)->
	{MonList,PlayerList,_,_} = DefendInfo,
	lists:map(fun make_defend_tpl/1, MonList++PlayerList). 

make_defend_tpl(PlayerStatus) when is_record(PlayerStatus, player) ->
	{?ELEMENT_PLAYER, 
	 PlayerStatus#player.id,0,0,0,0,?DAMAGE_TYPE_NORMAL};
make_defend_tpl(MonStatus) when is_record(MonStatus, temp_mon_layout) ->
	{?ELEMENT_MONSTER,MonStatus#temp_mon_layout.id,0,0,0,0,?DAMAGE_TYPE_NORMAL}.

%% 获取战斗类型
get_battle_type(AttackType, DefendType) ->
	if
		AttackType =:= ?ELEMENT_PLAYER andalso DefendType =:= ?ELEMENT_PLAYER -> ?BATTLE_TYPE_PVP;
		AttackType =:= ?ELEMENT_PET andalso DefendType =:= ?ELEMENT_PLAYER -> ?BATTLE_TYPE_PVP;
		AttackType /= DefendType -> ?BATTLE_TYPE_PVE;
		true -> ?BATTLE_TYPE_PVE
	end.

%% 玩家发起攻击前的检查
check_fightable(BattleAttr,SkillId) ->  
	SkillTpl = tpl_skill:get(SkillId),
	case SkillTpl#temp_skill.is_caused_by_buff of
		?NOT_CHILD_SKILL->
			case SkillTpl#temp_skill.is_normal_attr of
				?SKILL_NORMAL_ATTR ->
				 	BattleAttr#battle_attr.hit_point > 0
											   andalso  BattleAttr#battle_attr.status_unattrackable =< 0;  %检测不能攻击
				_-> 
				 	BattleAttr#battle_attr.hit_point > 0
											   andalso  BattleAttr#battle_attr.status_unattrackable =< 0  %检测不能攻击
																				   andalso BattleAttr#battle_attr.status_silent =< 0 %检测沉默 
			end;
		?IS_CHILD_SKILL->
			BattleAttr#battle_attr.hit_point > 0
	end.

%%对受击方的状态检查    
check_define_status(_,_,_,_,SkillTpl,_) when SkillTpl#temp_skill.target_type =:= ?SKILL_AREA_SELF->
	true;  
check_define_status(?ELEMENT_PLAYER,X,Y,DefinePlayer,SkillTpl,RelationInfo)-> 
	Fun = battle_util:get_relation_charge_fun(SkillTpl#temp_skill.relation_type),
	case DefinePlayer#player.battle_attr#battle_attr.hit_point of %判断攻击对象是否死亡
		0-> 
			?TRACE("[BATTLE_CHARGE] target ~p has been dead ~n",[DefinePlayer#player.id]),
			{false,3102017};  
		_-> 
			%%判断敌友关系
			Result = Fun(RelationInfo,{DefinePlayer#player.camp}),  
			case Result of
				true ->  
					%判断施法距离
					{DX,DY} = {DefinePlayer#player.battle_attr#battle_attr.x,DefinePlayer#player.battle_attr#battle_attr.y}, 
					Distance = SkillTpl#temp_skill.distance,  
					if (abs(DX-X) =< Distance) andalso (abs(DY-Y) =< Distance) -> 
						   if DefinePlayer#player.battle_attr#battle_attr.invincible > 0 -> %%无敌状态
							
								  {false,3102015};
							  true ->
								  true
						   end;
					   true ->
						   ?TRACE("[BATTLE_CHARGE] target out of distance ~n",[]),
						   %   io:format("[DISTANCE_CHECK_ERROR]target out of distance  Defend Pos ~p Atr Pos ~p distance ~p ~n",[{DX,DY},{X,Y},Distance]), 
						   {false,3102015}
					end;
				_-> 
					?TRACE("[BATTLE_CHARGE] battle relation err ~n",[]),
					{false,3102009}
			end 
	end; 
check_define_status(?ELEMENT_MONSTER,X,Y,DefineMon,SkillTpl,RelationInfo)->
	Fun = battle_util:get_relation_charge_fun(SkillTpl#temp_skill.relation_type),
	case DefineMon#temp_mon_layout.battle_attr#battle_attr.hit_point of %判断攻击对象是否死亡
		0-> 
			?TRACE("[BATTLE_CHARGE] target ~p has been dead ~n",[DefineMon#temp_mon_layout.id]),
			{false,3102017};
		_-> %%判断敌友关系
			Result = Fun(RelationInfo,{10}),
			case Result of
				true -> 
					%判断施法距离  
					{DX,DY} = {DefineMon#temp_mon_layout.battle_attr#battle_attr.x,DefineMon#temp_mon_layout.battle_attr#battle_attr.y}, 
					Distance = SkillTpl#temp_skill.distance,
					if (abs(DX-X) =< Distance+2) andalso (abs(DY-Y) =< Distance+2) ->
						 %  io:format("[DISTANCE_CHECK]skill id ~p Defend Pos ~p Atr Pos ~p distance ~p ~n",[SkillTpl#temp_skill.sid,{DX,DY},{X,Y},Distance]),  
						   true;
					   true ->
						   ?TRACE("[BATTLE_CHARGE] target out of distance ~n",[]),
						%   io:format("[DISTANCE_CHECK_ERROR]target out of distance  Defend Pos ~p Atr Pos ~p distance ~p ~n",[{DX,DY},{X,Y},Distance]), 
						   {false,3102015}
					end;
				_->
					?TRACE("[BATTLE_CHARGE] battle relation err ~n",[]),
					{false,3102009}
			end
	end;
check_define_status(_,_,_,_,_,_)->
	false.

%构造攻击者的信息
make_attr_status_info(AttrStatus)->
	if is_record(AttrStatus, player) ->
		   {{AttrStatus#player.camp},AttrStatus#player.battle_attr} ;
	   is_record(AttrStatus, temp_mon_layout) ->
		   {{10},AttrStatus#temp_mon_layout.battle_attr}; 
	   true ->
		   {{10},{}} 
	end.
%%根据技能属性获取受技能影响对象列表（人/怪） DefendId, DefendType
get_defend_obj_lists(AttrStatus, DefenfStuts,DefendType,SkillTpl,SceneId)-> 
	{RelationInfo,BattleAttr} = make_attr_status_info(AttrStatus),   
	if SkillTpl#temp_skill.target_type == ?SKILL_AREA_SELF andalso SkillTpl#temp_skill.aoe_type == 0 -> %单体对自身施放的技能 
		   if is_record(AttrStatus, player) -> 
				  {[],[AttrStatus],BattleAttr#battle_attr.x,BattleAttr#battle_attr.y};
			  true -> 
				  {[AttrStatus],[],BattleAttr#battle_attr.x,BattleAttr#battle_attr.y}
		   end;
	   SkillTpl#temp_skill.target_type == ?SKILL_AREA_TARGET 
							   andalso SkillTpl#temp_skill.aoe_type == 0 -> %单体对目标施放技能
		   if  BattleAttr#battle_attr.is_rush_success =/= ?BUFF_RUSH_ERROR ->
				   case  DefendType of  
					   ?ELEMENT_MONSTER ->%目标为怪物 
				 		   {[DefenfStuts],[],DefenfStuts#temp_mon_layout.battle_attr#battle_attr.x,DefenfStuts#temp_mon_layout.battle_attr#battle_attr.y};
					   ?ELEMENT_PLAYER when  SkillTpl#temp_skill.is_monster_skill =/= ?IS_MONSTER_SKILL ->%目标为人 
					 	   {[],[DefenfStuts],DefenfStuts#player.battle_attr#battle_attr.x,DefenfStuts#player.battle_attr#battle_attr.y}; 
					   _-> 
						   {[],[],0,0}
				   end;
			   true-> 
				   {[],[],0,0}
		   end;
	   SkillTpl#temp_skill.target_type == ?SKILL_AREA_TARGET -> %目标为中心施放群体技能
		   case  DefendType of
			   ?ELEMENT_MONSTER ->   
			 	   get_defend_lists(BattleAttr,DefenfStuts#temp_mon_layout.battle_attr#battle_attr.x,DefenfStuts#temp_mon_layout.battle_attr#battle_attr.y, DefendType, SkillTpl,SceneId,RelationInfo);
			   ?ELEMENT_PLAYER when  SkillTpl#temp_skill.is_monster_skill =:= ?IS_MONSTER_SKILL-> 
			 	   {MonsterList,_,X,Y} = get_defend_lists(BattleAttr,DefenfStuts#player.battle_attr#battle_attr.x,DefenfStuts#player.battle_attr#battle_attr.y, ?ELEMENT_MONSTER, SkillTpl,SceneId,RelationInfo),
				   {MonsterList,[],X,Y};
			   ?ELEMENT_PLAYER  -> 
				    get_defend_lists(BattleAttr,DefenfStuts#player.battle_attr#battle_attr.x,DefenfStuts#player.battle_attr#battle_attr.y, DefendType, SkillTpl,SceneId,RelationInfo);
			   _-> 
				   {[],[],0,0} 
		   end;
	   SkillTpl#temp_skill.target_type == ?SKILL_AREA_SELF -> %自身为中心施放群体技能 
		   get_defend_lists(BattleAttr,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y, DefendType, SkillTpl,SceneId,RelationInfo);
	   SkillTpl#temp_skill.target_type == ?SKILL_AREA_GROUND ->
		   {PostX,PostY} = get_attack_postion(BattleAttr#battle_attr.x, BattleAttr#battle_attr.y, SkillTpl) ,  
		   get_defend_lists(BattleAttr,PostX,PostY, DefendType, SkillTpl,SceneId,RelationInfo );										   
	   true ->
		   {[],[],0,0}
	end.
%-------------------------
%-	阵营关系判断，判断对方是友军还是敌军（以后扩展，暂时以阵营为判断）
%-------------------------
%%判断是否为友方
charge_friend({P1Camp},{P2Camp})-> 
	P1Camp =:= P2Camp.
%%判断是否为敌方
charge_enermy({P1Camp},{P2Camp})->   
	P1Camp =/= P2Camp.

get_relation_charge_fun(RelationType)->
	case RelationType of
		?SKILL_RELATION_ENERMY -> 
			Fun = fun(Ps1,Ps2)-> 
						  charge_enermy(Ps1, Ps2)
				  end;
		?SKILL_RELATION_FRIEND-> 
			Fun = fun(Ps1,Ps2)->
						  charge_friend(Ps1, Ps2)
				  end;
		?SKILL_RELATION_MISS-> 
			Fun = fun(Ps1,Ps2)->
						  true
				  end;
		_-> 
			Fun = fun(Ps1,Ps2)->
						  false
				  end
		end.

%%受技能影响对象列表
get_defend_lists(BattleAttr,X,Y, DefendType, SkillTpl,SceneId,RelationInfo)->
	Fun = get_relation_charge_fun(SkillTpl#temp_skill.relation_type),  
	case SkillTpl#temp_skill.aoe_type of
		?SKILL_RANG_LINE->  
			{PlayerList,MonsterList} = lib_scene:get_straight_line_defenders
										 (DefendType,SceneId,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,X,Y,SkillTpl#temp_skill.aoe_dist,SkillTpl#temp_skill.aoe_tnum,Fun,RelationInfo),
			
			?TRACE("get line target ~p ~n",[{PlayerList,MonsterList}]),
			NewMonsterList = lists:map(fun(MonId)->get_status(MonId, ?ELEMENT_MONSTER) end, MonsterList),
			NewPlayerList = lists:map(fun(UId)->get_status(UId, ?ELEMENT_PLAYER) end, PlayerList),
			{NewMonsterList,NewPlayerList,X,Y}; 
		?SKILL_RANG_MATRIX-> 
			{PlayerList,MonsterList} = lib_scene:get_matrix_defenders
										 (DefendType,SceneId,X,Y,SkillTpl#temp_skill.aoe_dist,SkillTpl#temp_skill.aoe_tnum,Fun,RelationInfo),
			?TRACE("get MATRIX target ~p ~n",[{PlayerList,MonsterList}]),
			NewMonsterList = lists:map(fun(MonId)->get_status(MonId, ?ELEMENT_MONSTER) end, MonsterList),
			NewPlayerList = lists:map(fun(UId)->get_status(UId, ?ELEMENT_PLAYER) end, PlayerList),
			{NewMonsterList,NewPlayerList,X,Y};
		?SKILL_RANG_SCTOR->   
			{PlayerList,MonsterList} = lib_scene:get_sector_defenders
										 (DefendType,SceneId,BattleAttr#battle_attr.x,BattleAttr#battle_attr.y,BattleAttr#battle_attr.direct_x,BattleAttr#battle_attr.direct_y,SkillTpl#temp_skill.aoe_dist,?SKILL_SCETOR_ANGLE,SkillTpl#temp_skill.aoe_tnum,Fun,RelationInfo),
			?TRACE("get Sector target ~p ~n",[{PlayerList,MonsterList}]),
			NewMonsterList = lists:map(fun(MonId)->get_status(MonId, ?ELEMENT_MONSTER) end, MonsterList),
			NewPlayerList = lists:map(fun(UId)->get_status(UId, ?ELEMENT_PLAYER) end, PlayerList),
			{NewMonsterList,NewPlayerList,X,Y};
		_->
			{[],[],X,Y}
	end.  

%% 获取指定数目的被攻击人物列表
%% get_defend_player_list(_AttackId, SceneId, X, Y, AttackArea, AttackTargetNum) ->
%% 	PlayerList = lib_scene:get_squre_players(SceneId, X, Y, AttackArea) ,
%% 	PlayerListLen = length(PlayerList),
%% 	if
%% 		PlayerListLen > AttackTargetNum andalso AttackTargetNum >0 ->
%% 			{AttackTargetNum, lists:sublist(PlayerList, AttackTargetNum)};
%% 		PlayerListLen > 0 ->
%% 			{PlayerListLen, lists:sublist(PlayerList, PlayerListLen)};
%% 		true ->
%% 			{0, []}
%% 	end.
%% 获取指定数目的被攻击人物列表
get_defend_player_list(_,_,_,_,0,_,_)->
	{[],0};
get_defend_player_list(SceneId, X, Y, AttackArea, AttackTargetNum,RelationInfo,RelationFun)->
	lib_scene:get_squre_players(X,Y,AttackArea,AttackTargetNum,SceneId,RelationInfo,RelationFun).

%% 获取指定数目的被攻击人物列表
%% get_defend_mon_list(AttackId, _SceneId, X, Y, AttackArea, AttackTargetNum) ->
%% 	MonList = lib_mon:get_squre_mons(AttackId, X, Y, AttackArea),
%% 	MonListLen = length(MonList),
%% 	if
%% 		MonListLen > AttackTargetNum andalso AttackTargetNum > 0 ->
%% 			{AttackTargetNum, lists:sublist(MonList, AttackTargetNum)};
%% 		MonListLen > 0 ->
%% 			{MonListLen, lists:sublist(MonList, MonListLen)};
%% 		true ->
%% 			{0, []}
%% 	end.
get_defend_mon_list(_,_,_,0,_,_)->  
	{[],0}; 
get_defend_mon_list(X,Y,Range,MaxNum,RelationInfo,RelationFun)->
	 lib_mon:get_squre_mons(X,Y,Range,MaxNum,RelationInfo,RelationFun).

%% 获取场景人或怪信息
get_status(Id, Type) ->
	if  
		Type =:= ?ELEMENT_PLAYER -> % 人
			case lib_scene:get_scene_player(Id) of
				AttackStatus1 when is_record(AttackStatus1, player) -> 
					AttackStatus1;
				_ ->
					[]
			end;  
		Type =:= ?ELEMENT_MONSTER -> % 怪
			case lib_mon:get_monster(Id) of
				AttackStatus1 when is_record(AttackStatus1, temp_mon_layout) ->
					NewBattleAttr = init_battle_info(AttackStatus1,?ELEMENT_MONSTER),
				 	AttackStatus1;
				%	AttackStatus1#temp_mon_layout{battle_attr = NewBattleAttr};
				_ ->
					[]
			end;
		Type =:= ?ELEMENT_PET -> % 宠物
			case lib_common:get_ets_info(?ETS_PET_INFO, Id) of
				AttackStatus1 when is_record(AttackStatus1, pet) ->
					AttackStatus1;
				_ ->
					[]
			end;
		true ->
			[]
	end.
%%获取对象的战斗属性以及等级
get_battle_info(Id, Type)->
	case get_status(Id, Type) of
		Player when is_record(Player, player) ->
			{Player#player.level,Player#player.battle_attr};
		Monster when is_record(Monster, temp_mon_layout) ->
			{Monster#temp_mon_layout.monrcd#temp_npc.level,Monster#temp_mon_layout.battle_attr};
		_->
			?TRACE("[BATTLE]get_battle_info fail, Id:~p, Type:~p ~n", [Id, Type]),
			{0,{}}
	end.

get_attack_postion(X,Y,SkillTpl) when is_record(SkillTpl,temp_skill) ->
	Distance = SkillTpl#temp_skill.distance ,
	Direct = util:rand(1, 4) ,
	case Direct of
		1 ->	%% 水平右方向上
			{util:rand(X, X+Distance),Y} ;
		2 ->	%% 垂直上方向
			{X,util:rand(Y, Y+Distance)} ;
		3 ->
			{util:rand(X-Distance,X),Y} ;
		4 ->
			{X,util:rand(Y-Distance, Y)} ;
		_ ->
			{X,Y}
	end .
get_attr_status(Status) when is_record(Status, player)->
	{?ELEMENT_PLAYER,Status#player.id,Status#player.battle_attr};
get_attr_status(Status) when is_record(Status, temp_mon_layout)->
	{?ELEMENT_MONSTER,Status#temp_mon_layout.id,Status#temp_mon_layout.battle_attr}.

%%处理击退逻辑
do_repel(MapId,AttrBattle,DefendBattle,[BuffId|Rest],BuffEffectList)->
	TplBuff = tpl_buff:get(BuffId),
	[{_,_,Dist}|_] = TplBuff#temp_buff.data,  
	case lib_scene:beat_back_position (MapId,AttrBattle#battle_attr.x , AttrBattle#battle_attr.y, DefendBattle#battle_attr.x, DefendBattle#battle_attr.y, Dist)of
		{ok,RestX,RestY} -> 
			do_repel(MapId,AttrBattle,DefendBattle#battle_attr{x = RestX,y =RestY },Rest,[{?BUFF_TYPE_REPEL,RestX,RestY}|BuffEffectList]);
		{block,RestX,RestY} ->		
			do_repel(MapId,AttrBattle,DefendBattle#battle_attr{x = RestX,y =RestY },Rest,[{?BUFF_TYPE_REPEL,RestX,RestY}|BuffEffectList]); 
		R->
			do_repel(MapId,AttrBattle,DefendBattle ,Rest,BuffEffectList)
	end;
do_repel(_,_,DefendBattle,[ ],BuffEffectList)->
	{DefendBattle,BuffEffectList}.
 
do_rush(MapId,BattleAttr,{_,_,TargetBattleAttr},[RushId|Rest],ResultList)->
	TplBuff = tpl_buff:get(RushId),
	[{_,_,Dist}|_] = TplBuff#temp_buff.data,
	if abs(BattleAttr#battle_attr.x-TargetBattleAttr#battle_attr.x)=<Dist andalso abs(BattleAttr#battle_attr.y-TargetBattleAttr#battle_attr.y)=<Dist
		   andalso TargetBattleAttr#battle_attr.hit_point > 0->
		   case lib_scene:find_src2dest_position
				  (MapId, BattleAttr#battle_attr.x, BattleAttr#battle_attr.y, TargetBattleAttr#battle_attr.x, TargetBattleAttr#battle_attr.y) of
			   {ok,DestX,DestY} ->
				   do_rush(MapId,BattleAttr#battle_attr{x = DestX,y = DestY,is_rush_success = ?BUFF_RUSH_SUCCESS},TargetBattleAttr,Rest,[{?BUFF_TYPE_RUSH,DestX,DestY}|ResultList]) ;
			   {block,DestX,DestY} ->
				   do_rush(MapId,BattleAttr#battle_attr{x = DestX,y = DestY,is_rush_success = ?BUFF_RUSH_ERROR},TargetBattleAttr,Rest,[{?BUFF_TYPE_RUSH,DestX,DestY}|ResultList]) ;
			   _-> 
				   do_rush(MapId,BattleAttr#battle_attr{is_rush_success = ?BUFF_RUSH_ERROR},TargetBattleAttr ,Rest,ResultList)
		   end;
	   true ->
		    do_rush(MapId,BattleAttr#battle_attr{is_rush_success = ?BUFF_RUSH_ERROR},TargetBattleAttr ,Rest,ResultList)
	end;
do_rush(_,BattleAttr,_,[],ResultList)->
	{BattleAttr,ResultList}.

get_attack_postion(Id, Type) ->
	if
		Type =:= ?ELEMENT_PLAYER -> % 人
			case lib_scene:get_scene_player(Id) of
				AttackStatus1 when is_record(AttackStatus1, player) -> 
					AttackStatus1,
					{AttackStatus1#player.battle_attr#battle_attr.x,AttackStatus1#player.battle_attr#battle_attr.y};
				_ ->
					{0,0}
			end;
		Type =:= ?ELEMENT_MONSTER -> % 怪
			case lib_mon:get_monster(Id) of
				AttackStatus1 when is_record(AttackStatus1, temp_mon_layout) ->
					{AttackStatus1#temp_mon_layout.battle_attr#battle_attr.x,AttackStatus1#temp_mon_layout.battle_attr#battle_attr.y};
				_ ->
					{0,0}
			end;
		true ->
			{0,0}
	end.

%%@spec 获取玩家的攻击技能  
get_attack_skill(Index,SkillId,SkillList,Career) ->
	case lists:keyfind(SkillId, Index, SkillList) of
		false ->
			%% 取职业的默认技能
			DefaultSkillList = data_skill:get_default_skill(Career),
            case lists:keyfind(SkillId, Index, DefaultSkillList) of
                    {_SkillId,Lv} ->
                        {SkillId,Lv};
                    false ->
                        {0,0}
            end;
		{_SkillId, Lv} ->
			{SkillId, Lv} ;
		{_,_SkillId, Lv} ->
			{SkillId, Lv}
	end .
	

%% 初始化人物、宠物或怪物战斗信息
init_battle_info(Status, Type) ->
	if
		Type =:= ?ELEMENT_PLAYER -> % 人  
			Status#player.battle_attr;
		Type =:= ?ELEMENT_PET -> % 宠物
			Status#pet.battle_attr;
		Type =:= ?ELEMENT_MONSTER -> % 怪
			Status#temp_mon_layout.battle_attr#battle_attr{x = Status#temp_mon_layout.pos_x,y = Status#temp_mon_layout.pos_y};
		true ->
			#battle_attr{}
	end.

%% 初始化宠物战斗信息
init_pet_battle_info(PS, PetInfo) ->
	{Fattack, Mattack, Dattack} =
		if
			PetInfo#pet.attack_type =:= 1 ->
				{PetInfo#pet.attr_attack, 0, 0};
			PetInfo#pet.attack_type =:= 2 ->
				{0, PetInfo#pet.attr_attack,  0};
			PetInfo#pet.attack_type =:= 3 ->
				{0, 0, PetInfo#pet.attr_attack};
			true -> {0, 0, 0}
		end,
	BattleInfo = #battle_attr{
							  skill_cd_all = PetInfo#pet.battle_attr#battle_attr.skill_cd_all,
							  skill_cd_list = PetInfo#pet.battle_attr#battle_attr.skill_cd_list,
							  skill_buff = PetInfo#pet.battle_attr#battle_attr.skill_buff,
							  buff1 = PetInfo#pet.battle_attr#battle_attr.buff1,
							  buff2 = PetInfo#pet.battle_attr#battle_attr.buff2,
							  x = PS#player.battle_attr#battle_attr.x,
							  y = PS#player.battle_attr#battle_attr.y,
							  career = PetInfo#pet.attack_type,
							  attack = PetInfo#pet.attack,
							  fattack = Fattack,
							  mattack = Mattack,
							  dattack = Dattack,
							  hit_ratio = PetInfo#pet.hit,
							  crit_ratio = PetInfo#pet.crit
							 },
	PetInfo#pet{battle_attr = BattleInfo}.

%% 判断是否在攻击范围内
%% AX 攻击方X坐标
%% AY 攻击方y坐标
%% DX 被击方X坐标
%% DY 攻击方y坐标
%% AttArea 攻击距离
check_att_area(AX, AY, DX, DY, AttArea) ->
	NewAttArea = AttArea + 2,
    X = abs(AX - DX),
    Y = abs(AY - DY),
    X =< NewAttArea andalso Y =< NewAttArea .


check_attack_range(AX, AY, DX, DY, Range) ->   
    X = abs(AX - DX),
    Y = abs(AY - DY),
    X =< Range andalso Y =< Range .

%% 判断pvp战斗条件
check_pvp_condition(AttackStatus, AttackType, DefendStatus, DefendType) ->
	if
		AttackType =:= ?ELEMENT_PLAYER andalso DefendType =:= ?ELEMENT_PLAYER -> % 人
			%% 人VS人， 判断等级限制
			AttackStatus#player.level > ?BATTLE_LEVEL andalso DefendStatus#player.level > ?BATTLE_LEVEL ;
		true ->
			false  
	end.
%%吸收伤害回调
defend_redunction_call_back({DefendVal,MaxDefendVal,DefendPercent,Effect},DamageHp,DamageReductionQueue)when DefendVal >0 -> 
	TrueDemageReduction = util:ceil(DamageHp*DefendPercent/100),
	NewDefendVal =max(0,DefendVal - TrueDemageReduction),  
	NewHpDamage =  DamageHp - TrueDemageReduction,  
	if NewDefendVal =:= 0 ->											 
		   {NewDamageReductionDetail,NewDamageReductionQueue} = lib_player:apply_damage_reduction(remove,DamageReductionQueue,{DefendVal,MaxDefendVal,DefendPercent,Effect},0,-MaxDefendVal,""),
	 	   {NewDamageReductionDetail,NewHpDamage,NewDamageReductionQueue,true};	   
	   true->    
		   {{NewDefendVal,MaxDefendVal,DefendPercent,Effect},NewHpDamage,DamageReductionQueue,false}
	end;
defend_redunction_call_back(DemageReduction,DamageHp,DamageReductionQueue)->
	{DemageReduction,DamageHp,DamageReductionQueue,false}.	
  
