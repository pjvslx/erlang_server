%%%-----------------------------------
%%% @Module  : lib_scene
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 场景信息
%%%-----------------------------------
-module(lib_scene).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include_lib("xmerl/include/xmerl.hrl").
-compile(export_all).



%% -define(GRID_WIDTH,64) .     	%% 划分格子的默认宽度
%% -define(GRID_HEIGHT,64) .	 	%% 划分格子的默认高度
%Type 1.人物优先 2.怪物优先 3只搜索玩家 4只搜索怪物
-define(PLAYER_FIRST,1). 
-define(MONSTER_FIRST,2).
-define(PLAYER_ONLY,3).
-define(MONSTER_ONLY,4).

-define(STRAIGHT,1). %%直线
-define(SECTOR,2). %%扇形
-define(MATRIX,3). %%九宫格
%%@spec 各个分场景的ETS名字
get_ets_name(SceneId) ->
	EtsName = misc:create_atom(?ETS_ONLINE_SCENE,[SceneId]) ,
	EtsName .

%%@spec 各个分场景的ETS名字
create_scene_online() ->
	create_scene_online(ets:tab2list(?ETS_TEMP_SCENE)) .
create_scene_online([]) ->
  skip ;  
create_scene_online([BaseScn|LeftBaseScn]) ->
	lists:foreach(fun(SubId) ->
						  EstName = get_ets_name(100*BaseScn#?ETS_TEMP_SCENE.sid+SubId) ,
						  ets:new(EstName, [{keypos,#player.id}, named_table, public, set,{read_concurrency,true}])
				  end , lists:seq(1, ?SCENE_MAX_NUMBER)) ,
	create_scene_online(LeftBaseScn) .

%%
get_ets_slice_name(SceneId) ->
	EtsName = misc:create_atom(ets_scene_slice_,[SceneId]) ,
	EtsName .

create_scene_slice() ->
	create_scene_slice(ets:tab2list(?ETS_TEMP_SCENE)) .
create_scene_slice([]) ->
	skip;
create_scene_slice([BaseScn|LeftBaseScn]) ->
	EstName = get_ets_slice_name(BaseScn#?ETS_TEMP_SCENE.sid) ,
	ets:new(EstName, [{keypos,#ets_scene_slice.id}, named_table, public, set,{read_concurrency,true}]),
	create_scene_slice(LeftBaseScn).
  
%%@spec  ETS操作函数 begin==========
%%spec 获取场景模板
get_scene_tmpl(SceneId) ->
	case ets:lookup(?ETS_TEMP_SCENE, get_base_scene(SceneId))of
		[S|_] ->
			S ;
		_ ->
			[]  
	end .

%% 获取场景的出生点
get_scene_xy(SceneId) ->
	BaseScn = get_base_scene(SceneId) ,
	case get_scene_tmpl(BaseScn) of
		TplScn when is_record(TplScn,temp_scene) ->
			{TplScn#temp_scene.x,TplScn#temp_scene.y} ;
		_ ->
			{0,0}
	end .

%%spec 获取场景模板
get_scene_tmpl(SceneId,OldSceneId) ->
	case get_scene_tmpl(SceneId) of
		ScnTpl when is_record(ScnTpl,temp_scene) ->
			ScnTpl ;
		_ ->
			get_scene_tmpl(OldSceneId)
	end .

is_valid_scene_inst(SceneId) ->
	case get_scene_tmpl(SceneId) of
		[] ->
			false ;
		_ ->
			SceneId > 999 
	end .
%如果身上有定身buff，则不能移动
check_stoptable_pos(X,Y,BattleAttr)->
	if BattleAttr#battle_attr.status_stop >0 -> 
		   {BattleAttr#battle_attr.x,BattleAttr#battle_attr.y};
	   true ->
		   {X,Y}
	end.
		
%% @spec 获取NPC模板数据
get_scene_npc(NpcId) ->
	case ets:lookup(?ETS_NPC, NpcId)of
		[S|_] ->
			S ;
		_ ->
			[]
	end .

%% @spec 获取NPC实例数据
get_npc_layout(NpcId) ->
	case ets:lookup(?ETS_NPC_LAYOUT, NpcId)of
		[S|_] ->
			S ;
		_ ->
			[]
	end .



get_scene_player_number(SceneId) ->
	EtsName = get_ets_name(SceneId) ,
	ets:info(EtsName,size) .
	

%%spec 获取场景玩家
get_scene_player(SceneId,PlayerId) ->
	EtsName = get_ets_name(SceneId) ,
	case ets:lookup(EtsName, PlayerId) of
		[] ->
			[] ;
		[D|_] ->
			D
	end .

get_scene_player(PlayerId) ->
	lib_player:get_player(PlayerId).

%% 从指定ETS表中删除玩家
remove_scene_player(SceneId,UId) ->
	case SceneId > 999 of
		true ->  
			EtsName = get_ets_name(SceneId) ,
			ets:delete(EtsName,UId) ;
		false ->
			skip 
	end .

%%@spec 加载场景基础数据到ETS表
load_temp_scene() ->  
	ScnRcdList =  db_agent_scene:select_scene() ,
	add_scene_to_ets(ScnRcdList) .
add_scene_to_ets([]) ->
	skip ;
add_scene_to_ets([ScnRcd|LeftList]) ->
	if
		is_record(ScnRcd,temp_scene) ->
			ets:insert(?ETS_TEMP_SCENE, ScnRcd) ;
		true ->
			skip
	end ,
	add_scene_to_ets(LeftList) .

%%@spec 加载NPC模板数据到ETS表
load_temp_npc() ->
	NpcRcdList =  db_agent_scene:select_npc() ,
	add_npc_to_ets(NpcRcdList) .
add_npc_to_ets([]) ->
	skip ;
add_npc_to_ets([NpcRcd|LeftList]) ->
	if
		is_record(NpcRcd,temp_npc) ->
			ets:insert(?ETS_NPC, NpcRcd) ;
		true ->
			skip
	end ,
	add_npc_to_ets(LeftList) .

%%@spec 加载NPC模板、实例 数据到ETS表
load_temp_npc_layout() ->
	NpcLayoutRcdList =  db_agent_scene:select_npc_layout() ,
	add_npclayout_to_ets(NpcLayoutRcdList) .
add_npclayout_to_ets([]) ->
	skip ;
add_npclayout_to_ets([NpcLayoutRcd|LeftList]) ->
	if
		is_record(NpcLayoutRcd,temp_npc_layout) ->
			case get_scene_npc(NpcLayoutRcd#temp_npc_layout.npcid) of
				NpcRcd when is_record(NpcRcd,temp_npc_layout) ->
					NewNpcLayoutRcd = NpcLayoutRcd#temp_npc_layout{npcrcd = NpcRcd} ,
					ets:insert(?ETS_NPC_LAYOUT, NewNpcLayoutRcd) ;
				_ ->
					skip
			end ;
		true ->
			skip
	end ,
	add_npclayout_to_ets(LeftList) .

%%@spec 加载MON模板数据到ETS表
load_temp_mon_layout() ->
	MonLayoutRcdList = db_agent_scene:select_mon_layout() ,
	add_monlayout_to_ets(MonLayoutRcdList) .
add_monlayout_to_ets([]) ->
	skip ;
add_monlayout_to_ets([MonLayoutRcd|LeftList]) ->
	if
		is_record(MonLayoutRcd,temp_mon_layout) ->
			case get_scene_npc(MonLayoutRcd#temp_mon_layout.monid) of
				MonRcd when is_record(MonRcd,temp_npc) ->
					MonCombatAttrRcd = lib_player:init_base_battle_attr(MonRcd#temp_npc.level, MonRcd#temp_npc.npc_type) ,
					NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{monrcd = MonRcd,battle_attr = MonCombatAttrRcd } ,
					ets:insert(?ETS_TEMP_MON_LAYOUT, NewMonLayoutRcd) ;
				_ ->
					skip
			end ;
		true ->
			skip
	end ,
	add_monlayout_to_ets(LeftList) .

%% 是否是副本进程
is_dungeon_scene(SceneId) ->
	case get_scene_tmpl(SceneId) of
		TplScn when is_record(TplScn,temp_scene) ->
			TplScn#temp_scene.mode =:= 4 orelse TplScn#temp_scene.mode =:= 5 ;
		_ ->
			false 
	end .

%% 普通场景
is_normal_scene(SceneId) ->
	case get_scene_tmpl(SceneId) of
		TplScn when is_record(TplScn,temp_scene) ->
			TplScn#temp_scene.mode =/= 4 andalso TplScn#temp_scene.mode =/= 5 ;
		_ ->
			false 
	end .
%%更新场景/副本怪物技能相关进程字典
reflesh_monster_skill_timer(MonId,TimerSkill) when  TimerSkill =/= []->  
	case get(?MON_SKILL_TIMER_LIST) of 
		undefined->  
			self() !'BUFFER_TIMER',
			put(?MON_SKILL_TIMER_LIST,[MonId]);
		[]-> 
			self() !'BUFFER_TIMER',
			put(?MON_SKILL_TIMER_LIST,[MonId]);
		List -> 
			case lists:member(MonId,List) of
				true -> skip;
				false ->   
					put(?MON_SKILL_TIMER_LIST,[MonId|List])
			end
	end;
reflesh_monster_skill_timer(_,_)->
	skip.

erase_monster_skill_timer(MonsterId)->
	case get(?MON_SKILL_TIMER_LIST) of
		undefined -> skip;
		[]->	skip;
		List ->
			put(?MON_SKILL_TIMER_LIST,lists:delete(MonsterId, List))
	end.
%% 基础场景
is_copy_scene(UniqueId) ->
	UniqueId > 99999.

%% 场景实例化，确定场景的实例和NPC
load_scene(SceneId) ->
	case get_scene_tmpl(get_base_scene(SceneId)) of
		Scn when is_record(Scn,temp_scene) ->
			%%子场景实例
			ets:insert(?ETS_SCENE, Scn#temp_scene{id = SceneId, npc=[]}) ,
			ets:insert(?ETS_TEMP_SCENE, Scn#temp_scene{scene_num = Scn#temp_scene.scene_num + 1});
		_ ->  
			skip  
	end .  

%% @spec保存伤害信息
save_player_damage(PlayerStatus,HpDamege) ->
	if    
		is_record(PlayerStatus,player) -> 
			{NewDemageReductionDetail,NewHpDamage,NewDamageReductionQueue,_} =
				battle_util:defend_redunction_call_back(PlayerStatus#player.battle_attr#battle_attr.damage_reduction, HpDamege,PlayerStatus#player.battle_attr#battle_attr.damage_reduction_queue),
			CurrentHP = max(0, PlayerStatus#player.battle_attr#battle_attr.hit_point - NewHpDamage), 
			BattleAttr =
				PlayerStatus#player.battle_attr#battle_attr
									{damage_reduction = NewDemageReductionDetail,hit_point = CurrentHP,energy = PlayerStatus#player.battle_attr#battle_attr.energy,damage_reduction_queue = NewDamageReductionQueue},
			if CurrentHP > 0 ->  
				   {BrocastPassiveEffect,NewBatttleAtte} = lib_skill:passive_skill_call_back(BattleAttr),
				   lib_skill:borcast_passive_skill_effect(PlayerStatus,NewBatttleAtte,BrocastPassiveEffect),
				   NewPlayer = PlayerStatus#player{battle_attr = NewBatttleAtte,status = PlayerStatus#player.status} ;
			   true -> %%玩家血量为0 
				   %%lib_mail:send_mail_to_one(PlayerStatus#player.id,1,6,[]),
				   lib_battle:erase_battle_player(PlayerStatus#player.id),  
				   NewPlayer = PlayerStatus#player{battle_attr = BattleAttr,status = ?PLAYER_NORMAL_STATE}  
			end, 
			save_scene_player(NewPlayer) ,   
			{NewHpDamage,NewPlayer} ;
		true ->
			{0,PlayerStatus}
	end .

%% @spec保存玩家信息
save_scene_player(PlayerStatus) ->  
	EtsName = get_ets_name(PlayerStatus#player.scene) , 
 	ets:insert(EtsName, PlayerStatus) .

%% @spec修改玩家信息
update_scene_player(PlayerStatus,VlaueList) ->
	EtsName = get_ets_name(PlayerStatus#player.scene) ,
	ets:update_element(EtsName, PlayerStatus#player.id,VlaueList) .
%% 	ets:insert(?ETS_ONLINE_SCENE, PlayerStatus) .

%%获取场景九宫格小格子对象列表
get_scene_slice(SceneId,SliceX,SliceY) ->
	EtsName = get_ets_slice_name(SceneId div 100) ,
	Id = SceneId*10000 + SliceX * 100 + SliceY,
	case ets:lookup(EtsName, Id) of
		[] ->
			[] ;
		[D|_] ->
			D#ets_scene_slice.obj
	end .  

set_scene_slice(SceneId,SliceX,SliceY,ObjList) ->
	EtsName = get_ets_slice_name(SceneId div 100) ,
	Id = SceneId*10000 + SliceX * 100 + SliceY,
	Rcd = #ets_scene_slice{id = Id,obj=ObjList},
	ets:insert(EtsName,Rcd).

get_base_scene(SceneId) ->
	if
		SceneId > 999 ->		
			SceneId div 100 ;	
		true ->					
			SceneId
	end .

check_level(LV,ScnId) ->
	ScnTplRcd =  lib_scene:get_scene_tmpl(ScnId) ,
	is_record(ScnTplRcd,temp_scene) andalso LV >= ScnTplRcd#temp_scene.min_level andalso LV =< ScnTplRcd#temp_scene.max_level .
	
								

%% @spec 玩家进入场景前的检查
check_eneter(SceneId,Status,PosX,PosY) ->
	PidSend = Status#player.other#player_other.pid_send ,
	Lv = Status#player.level ,
	ScnTmpl = get_scene_tmpl(SceneId) ,
	OldPlayerStatus = get_scene_player(Status#player.scene,Status#player.id) ,
	IsSameScene = is_same_scene(SceneId,Status#player.scene) ,
	%%case is_dungeon_scene(OldPlayerStatus#player.scene) of
	case IsSameScene of
		true ->  				%% 断线重连的情况
			case is_dungeon_scene(SceneId) of
				true ->			%% 之前所在的是副本场景
				 	case lib_dungeon:check_reconn_dungeon(Status) of
						{succ,PreScnId,PrePostX,PrePostY} ->
						 	%%{PreScnId,PrePostX,PrePostY} ;  									%%不能进入副本，则进入之前的场景
							SceneNum = ScnTmpl#temp_scene.scene_num ,
							SubSceneId = check_scene(ScnTmpl#temp_scene.sid,1,SceneNum) ,
							{SubSceneId,PosX,PosY} ;
						{fail_timeout,PreScnId,PrePostX,PrePostY} ->
							{PreScnId,PrePostX,PrePostY} ;
						_ ->
							%%异常跳到101入口
							ScnTmpl2 = get_scene_tmpl(101) ,
							SubSceneId = check_scene(101,1,ScnTmpl2#temp_scene.scene_num) ,
							{SubSceneId,14,7} 
					end ;
				false ->
					%%SubSceneId = check_scene(ScnTmpl#temp_scene.sid,1,SceneNum) ,
					%%{SubSceneId,PosX,PosY}
					SceneNum = ScnTmpl#temp_scene.scene_num ,
					SubSceneId = check_scene(ScnTmpl#temp_scene.sid,1,SceneNum) ,
					{SubSceneId,PosX,PosY}
 					%%{OldPlayerStatus#player.scene,OldPlayerStatus#player.battle_attr#battle_attr.x,OldPlayerStatus#player.battle_attr#battle_attr.y}
			end ;
		_ ->		
			if
				Lv < ScnTmpl#temp_scene.min_level orelse Lv > ScnTmpl#temp_scene.max_level ->    %% 等级不足
					lib_player:send_tips(2002003, [], PidSend) ,
					{0,0,0} ; 
				true ->
					SceneNum = ScnTmpl#temp_scene.scene_num ,
					SubSceneId = check_scene(ScnTmpl#temp_scene.sid,1,SceneNum) ,
					{SubSceneId,PosX,PosY}
			end 
	end .
		

is_same_scene(SceneIdA,ScneneIdB) ->
	get_base_scene(SceneIdA) =:= get_base_scene(ScneneIdB) .

%% 进入场景
check_scene(BaseSceneId,SubId,MaxScnNum)  ->
	SubSceneId = BaseSceneId * 100 + SubId ,
	case SubId > MaxScnNum of
		true ->
			case SubId =< ?SCENE_MAX_NUMBER of 
				true ->
					SubSceneId ;
				false ->
					0
			end ;
		false ->
			EtsName = get_ets_name(SubSceneId) ,
			Members = ets:info(EtsName,size) ,
			case Members < ?SCENE_PLAYER_MAX_NUMBER of
				true ->
					SubSceneId ;
				false ->
					check_scene(BaseSceneId, SubId + 1, MaxScnNum) 
			end 
	end .

get_sub_scene_number(BaseScnId) ->
	case get_scene_tmpl(BaseScnId) of
		ScnRcd when is_record(ScnRcd,temp_scene) ->
			ScnRcd#temp_scene.scene_num ;
		_ ->
			0
	end .

%% @spec 玩家进入场景
%% 1、需要发送场景内的人物，NPC，怪物信息给玩家
%% 2、需要广播有玩家进入场景(如果放在pp里面做，可能会导致)
enter_scene(Status,BattleExpriedTime) ->
	%%1.0 保存玩家信息
	save_scene_player(Status) ,

    monEvent_FirstPlayerComming(Status),

	%%2.0 获取场景上的怪物信息
	PosX = Status#player.battle_attr#battle_attr.x ,
	PoxY = Status#player.battle_attr#battle_attr.y ,
	{ok,EnterBin} = pt_12:write(12001, [Status#player.scene,PosX,PoxY]) ,
	lib_send:send_to_sid(Status#player.other#player_other.pid_send, EnterBin) ,
	
	case is_dungeon_scene(Status#player.scene) of
		true ->
			true;
		false ->
			lib_battle:move_battle_data(Status#player.id,BattleExpriedTime)
	end.

enter_scene_ok(Status) ->
	case Status of 
		Player when is_record(Player,player) ->
			PosX = Player#player.battle_attr#battle_attr.x ,
			PoxY = Player#player.battle_attr#battle_attr.y ,
			{SliceX,SliceY} = util:get_xy_slice(PosX,PoxY),
			%%add_slice_player(SliceX, SliceY, Player#player.id,Player#player.other#player_other.pid_send),
			add_slice_player(Player#player.scene,SliceX, SliceY, Player#player.id,Player#player.other#player_other.pid_send),
			case is_dungeon_scene(Player#player.scene) of
				true ->
					lib_dungeon:enter_scene_ok(Player);
				false ->
					lib_dungeon:info_dungeon_rewards(Player), 
					lib_scene_gift:info_scene_gift(Player)
			end,
			PlayerList 	= get_matrix_players(Player,PosX,PoxY) ,
			MonList 	= lib_mon:get_matrix_monsters(PosX,PoxY) ,  
			DropList 	= [],
			{ok,BinData} = pt_12:write(12002, [Player#player.scene,PlayerList,MonList,DropList]) ,
			lib_send:send_to_sid(Player#player.other#player_other.pid_send, BinData);
		_ ->
            ?ERROR_MSG("no such player 12005:~p", [Status#player.id]),
			skip
	end.

%-------------------------
%-	获取满足条件的玩家
%-------------------------
get_matrix_friend(SceneId,X, Y,ExcepUId,AoeDist,AoeNum)->
	EtsName = lib_scene:get_ets_name(SceneId) ,
	MS = ets:fun2ms(fun(P) when P#player.battle_attr#battle_attr.x - X =< AoeDist andalso
								P#player.battle_attr#battle_attr.y - Y =< AoeDist andalso  
								P#player.id =/= ExcepUId -> 
								P#player.other#player_other.pid_send end),
	L = ets:select(EtsName, MS),
	lists:sublist(L,AoeNum).



%%离开当前场景
leave_scene(PlayerId,SceneId) ->
    Status =  get_scene_player(SceneId,PlayerId),
    
	case Status of
		Player when is_record(Player,player) ->
            monEvent_LastPlayerLeave(Status),
			PosX = Player#player.battle_attr#battle_attr.x ,
			PosY = Player#player.battle_attr#battle_attr.y ,
			{SliceX,SliceY} = util:get_xy_slice(PosX,PosY),

			case is_dungeon_scene(SceneId) of
				true ->
					mod_dungeon:delete_slice_player(Player#player.other#player_other.pid_dungeon,Player#player.scene,SliceX, SliceY, PlayerId);
				false ->
                    Monsters = lib_mon:get_monsters(),
                    if
                        length(Monsters) > 0 ->%%通知场景怪进程删除相关信息
                            skip;
                            %[EachMon#temp_mon_layout.pid ! {'player_leaving',PlayerId} || EachMon<- Monsters];
                        true ->
                            skip
                    end,
					%%delete_slice_player(SliceX, SliceY, PlayerId)
					delete_slice_player(Player#player.scene,SliceX, SliceY, PlayerId)
			end;
		_ ->
			?ERROR_MSG("leave_scene error:~p", [PlayerId]),
			skip
	end,
	EtsName = get_ets_name(SceneId) ,
	ets:delete(EtsName, PlayerId) .
%% 	ets:delete(?ETS_ONLINE_SCENE, PlayerId) .

%% 同步玩家的目的位置
update_postion(Status,DestX,DestY) ->
	{SolutX,SolutY} = {Status#player.resolut_x,Status#player.resolut_y} ,
	%%BattleAttr = Status#player.battle_attr#battle_attr{x = DestX, y = DestY} ,
	case get_scene_player(Status#player.scene,Status#player.id) of
		Player when is_record(Player,player) ->
			OldX = Player#player.battle_attr#battle_attr.x ,
			OldY = Player#player.battle_attr#battle_attr.y ,
			BattleAttr = Player#player.battle_attr#battle_attr{x = DestX, y = DestY} ,			{OldSliceX,OldSliceY} = util:get_xy_slice(OldX,OldY),
			{OldSliceX,OldSliceY} = util:get_xy_slice(OldX,OldY),
			{DestSliceX,DestSliceY} = util:get_xy_slice(DestX,DestY),
			update_scene_player(Player,{#player.battle_attr,BattleAttr}),
			%%走出九宫格的小格子，更新对象列表
			case OldSliceX =:= DestSliceX andalso OldSliceY =:= DestSliceY of
				false ->
					%%广播剩余路径
					case Player#player.battle_attr#battle_attr.walk_path of
						[] ->
							skip;
						[WalkDestX,WalkDestY,WalkLen,WalkPath] ->
							LeftPath2 = case find_left_walk_path(DestX,DestY,WalkDestX,WalkDestY,WalkPath) of
								LeftPath when size(LeftPath) > 0 ->
									{ok, BinData} = pt_12:write(12010, [Player#player.id,WalkDestX,WalkDestY,size(LeftPath) div 4,LeftPath]) ,
									mod_scene_agent:send_to_matrix(Player#player.scene, 
												Player#player.battle_attr#battle_attr.x, 
												Player#player.battle_attr#battle_attr.y, 
												BinData,Player#player.id),
									LeftPath;
								EmptyPath ->
									EmptyPath
							end,
						BattleAttr2 = Player#player.battle_attr#battle_attr{x = DestX, y = DestY,walk_path = [WalkDestX,WalkDestY,size(LeftPath2) div 4,LeftPath2]} ,
						update_scene_player(Player,{#player.battle_attr,BattleAttr2})
%% 						lib_player:put_walk_path(Player#player.id,LeftPath2)
					end,					  
					DestZoneObjList = get_zone_playerlist(Player#player.scene,DestSliceX,DestSliceY),
					OldZoneObjList = get_zone_playerlist(Player#player.scene,OldSliceX,OldSliceY),
					%%1从旧的对象列表删除
					delete_slice_player(Player#player.scene,OldSliceX, OldSliceY, Player#player.id),
					%%2加入新的对象列表中
					add_slice_player(Player#player.scene,DestSliceX,DestSliceY,Player#player.id,Player#player.other#player_other.pid_send),
					DelOldZoneObjList = lists:filter(fun(ObjId) ->
														not lists:member(ObjId, DestZoneObjList) 
													end, OldZoneObjList),
					AddDestZoneObjList = lists:filter(fun(ObjId) ->
														not lists:member(ObjId, OldZoneObjList) 
													end, DestZoneObjList),
					%%3旧九宫格对象删除玩家
					{ok, LeaveBinData} = pt_12:write(12004, [Player#player.id]),
					broadcast_player_data(DelOldZoneObjList,LeaveBinData),
					%io:format("3LeaveBinData::~p~n",[DelOldZoneObjList]),
					%%4玩家删除旧九宫格对象
					send_leave_objs(DelOldZoneObjList, Player), %%TODO:++怪物，采集物
					%%5更新新九宫格对象给玩家
					%%send_change_objs(DestZoneObjList, Player,12004), %%TODO:++怪物，采集物
					refresh_scene_elems(Player, DestX, DestY) ,
					%%6更新玩家给新九宫格对象
					{ok, EnterBinData} = pt_12:write(12003, [Player]) ,
					broadcast_player_data(AddDestZoneObjList,EnterBinData),
					%io:format("6EnterBinData::~p~n",[AddDestZoneObjList]),
					ok;
				true ->
					skip
			end;
		_ ->
			skip
	end.

find_left_walk_path(DestX,DestY,WalkDestX,WalkDestY,WalkPath) ->
	case WalkPath of
		<<FirstX:16,FirstY:16,LeftPath/binary>> ->
			case DestX =:= FirstX andalso DestY =:= FirstY of
				true ->
					LeftPath;
				false ->
					find_left_walk_path(DestX,DestY,WalkDestX,WalkDestY,LeftPath)
			end;
		_ ->
			<<>>
	end.

delete_slice_player(SceneId,X,Y,PlayerId) ->
	%io:format("delete_slice_player::~p~n",[PlayerId]),
	case get_scene_slice(SceneId,X,Y) of
		[] ->
			skip;
		ObjList ->
			NewObjList = lists:keydelete(PlayerId,1,ObjList),
			set_scene_slice(SceneId,X,Y,NewObjList)
	end.

add_slice_player(SceneId,X,Y,PlayerId,PlayerPidSend) ->
	case is_dungeon_scene(SceneId) of
		false ->
			ObjList = get_scene_slice(SceneId,X,Y),
			case lists:keyfind(PlayerId,1,ObjList) of
				false ->
					NewObjList = ObjList ++ [{PlayerId,PlayerPidSend}],
					set_scene_slice(SceneId,X,Y,NewObjList);
				_ ->
					skip  
			end;
		true ->
			skip
	end.
	
%%获取以X，Y为中心的九宫格范围内的所有玩家列表
get_zone_players(SceneId,X,Y) ->
	ZoneObjList = lists:foldr(fun({AppX,AppY},Result) ->  
				  NewX = X + AppX,
				  NewY = Y + AppY,
				  ObjList = get_scene_slice(SceneId,NewX,NewY),
				  ObjList ++ Result
		  end , [],?ZONE_POS),
	ZoneObjList.


get_zone_playerlist(SceneId,X,Y) ->
	ZoneObjList = get_zone_players(SceneId,X,Y),
	lists:foldl(fun({PlayerId,PlayerPidSend},Result) ->
			Result ++ [PlayerId]
	end,[],ZoneObjList).

%%get_slice_playerlist(X,Y) ->
%%	case get({X,Y,sliceplayer}) of
%%		undefined ->
%%			[];
%%		SliceObjList ->
%%			lists:foldl(fun({PlayerId,PlayerPidSend},Result) ->
%%					Result ++ [PlayerId]
%%			end,[],SliceObjList)
%%	end.

%%更新场景元素,包括场景的玩家和怪物
refresh_scene_elems(Status, DestX, DestY) ->  
	  
	MatrixPlayers = get_matrix_players(Status,DestX,DestY) ,
	%%io:format("refresh_scene_elems::MatrixPlayers::~p~n",[length(MatrixPlayers)]),
	MatrixMons = lib_mon:get_matrix_monsters(DestX,DestY), 
	%%DropList 	= lib_mon:get_screen_drops(DestX,DestY,SolutX,SolutY) ,
	{ok,BinData} = pt_12:write(12002, [Status#player.scene,MatrixPlayers,MatrixMons,[]]) ,
	lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData) .

%%当人物移动的时候广播
%%TODO::移动广播优化
%%broadcast_move(SceneId, {OldPosX,OldPosY}, {NewPosX,NewPosY}, {SolutX,SolutY}, LeaveBinData, EnterBinData) ->
%%	%%1.0 获取旧区域的玩家
%%	OldPlayers = get_matrix_players(SceneId,OldPosX,OldPosY) ,
%%	DestPlayers = get_matrix_players(SceneId,NewPosX,NewPosY) ,
%% 	{OldList,NewList,_SameList} = split_players(OldPlayers,DestPlayers) ,
	
%%	broadcast_data(OldPlayers,LeaveBinData) ,
%%	broadcast_data(DestPlayers,EnterBinData) .


%%发送消息给玩家列表
broadcast_data([],_DataBin) ->
	skip ;
broadcast_data([Player|LeftPlayers],DataBin) ->
	
	lib_send:send_to_sid(Player#player.other#player_other.pid_send, DataBin) ,
	broadcast_data(LeftPlayers,DataBin) .
%%
broadcast_player_data([],_DataBin) ->
	skip ;
broadcast_player_data([PlayerId|LeftPlayerIds],DataBin) ->
	case get_scene_player(PlayerId) of
		Player when is_record(Player,player) ->
			lib_send:send_to_sid(Player#player.other#player_other.pid_send, DataBin);
		_ ->
			skip
	end,
	broadcast_player_data(LeftPlayerIds,DataBin) .
%%
send_leave_objs([],Player) ->
	skip;
send_leave_objs([TargetId|LeftTargetIds],Player) ->
	case get_scene_player(TargetId) of
		Target when is_record(Target,player) ->
			{ok, BinData} = pt_12:write(12004, [TargetId]),
			lib_send:send_to_sid(Player#player.other#player_other.pid_send, BinData);
		_ ->
			skip
	end,
	send_leave_objs(LeftTargetIds,Player).

%% 从玩家列表里面获取指定区域里面的所有玩家
get_screen_players(Players,{X1,Y1,X2,Y2}) ->
	Fun = fun(Player,SPlayers) ->
				  case util:is_same_screen(Player#player.battle_attr#battle_attr.x, Player#player.battle_attr#battle_attr.y, {X1, Y1, X2, Y2}) of
					  true ->
						  [Player|SPlayers] ;
					  false ->
						  SPlayers 
				  end 
		  end ,
	lists:foldl(Fun, [], Players) .

%%@spec 从两个玩家列表中分离出
%%%%%% 		1. A 在 B中不存在的 
%%%%%% 		2. B 在 A中不存在的
%%%%%% 		3. 在 A 和 B中都存在的
split_players(APlayerList,BPlayerList) ->
	%%1.0 先从AList中找出在BList中也存在的玩家
	Fun = fun(APlayer,{AList,CList}) ->
				  case lists:keyfind(APlayer#player.id, #player.id, BPlayerList) of
					  Player when is_record(Player,player) ->
						 ALeftList = lists:keydelete(APlayer#player.id, #player.id, AList) ,
						 {ALeftList,[Player|CList]} ;
					  _ ->
						 {AList,CList} 
						 
				  end 
		  end ,
	{APList,CPList} = lists:foldl(Fun, {APlayerList,[]}, APlayerList) ,
	
	%%2.0 先从BList中找出在BList中也存在的玩家
	DFun = fun(BPlayer,BList) ->
				  case lists:keyfind(BPlayer#player.id, #player.id, CPList) of
					  Player when is_record(Player,player) ->
						 BLeftList = lists:keydelete(BPlayer#player.id, #player.id, BList) ,
						 BLeftList ;
					  _ ->
						 BList 
						 
				  end 
		  end ,
	BPList = lists:foldl(DFun, [], BPlayerList) ,
	
	{APList,BPList,CPList} .



%% 按照字段更新玩家场景信息
update_player_info_fields(SceneId,PlayerId,ValueList) ->
	EtsName = get_ets_name(SceneId) ,
	Pattern = #player{id = PlayerId,_='_'},
	Player = ets:match(EtsName,Pattern),
	if
		is_record(Player,player) ->
			NewPlayer = lib_player_rw:set_player_info_fields(Player,ValueList),
			ets:insert(EtsName, NewPlayer) ;
%% 			ets:insert(?ETS_ONLINE_SCENE, NewPlayer);
		true ->
			skip
	end.


%% 怪物掉落拾取
pick_drop(DropId) ->
	%%根据掉落列表就行拆分
	DropList = lib_mon:get_monster_drops() ,
	MonDropList = [ D || D <- DropList, D#mon_drop_goods.drop_id =:= DropId] ,
	lib_mon:save_monster_drops(DropList -- MonDropList) ,
%% 
%% 	Fun = fun(D) ->
%% 				  D#mon_drop_goods.uid =:= UId andalso 
%% 				  D#mon_drop_goods.goods_id =:= GoodsId andalso
%% 				  D#mon_drop_goods.mon_id =:= MonId
%% 		  end ,
%% 	{MonDropList,LeftDropList} = lists:splitwith(Fun, DropList) ,
%% 	lib_mon:save_monster_drops(LeftDropList) ,
	
	%%过滤出需要返回的字段
	RFun = fun(D) ->
				   {D#mon_drop_goods.goods_id,D#mon_drop_goods.goods_num}
		   end ,
	PickedDrops = lists:map(RFun, MonDropList) ,
	[1,PickedDrops] .
			 
%@spec 获取跟指定坐标同九宫格区域的玩家
get_matrix_players(Status,X,Y) ->
	SceneId = Status#player.scene,
    case is_dungeon_scene(SceneId) of
		false ->
			{SliceX,SliceY} = util:get_xy_slice(X,Y),
			ObjList = get_zone_playerlist(SceneId,SliceX,SliceY),
			F = fun(ObjId,List1) ->
						case get_scene_player(ObjId) of
							Player when is_record(Player,player) ->
								List1 ++ [Player];
							_ ->
								List1
						end
				end,
			Result = lists:foldl(F, [], ObjList);
		true ->
			Result = [Status]
	end,
	Result.

%%战斗相关的扫描玩家和怪物外部接口BEGIN%%%%
%获取直线范围内受击者列表
%Type 1.人物优先 2.怪物优先 3只搜索玩家 4只搜索怪物
%DeFendX 目标的x坐标
%DeFendY 目标的y坐标
%AttrX 攻击者的x坐标
%AttrY 攻击者的y坐标
%Rang 技能伤害举例
%NUM 技能最大目标
%RelationFun 判断关系函数指针
%Relation 攻击者关系对象
%返回 {PlayerList,MonsterList}
get_straight_line_defenders(Type,SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang,Num,RelationFun,Relation) ->
	get_shape_defenders(?STRAIGHT,Type,[SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang],Num,RelationFun,Relation).

%获取九宫格内受击者列表
%Type 1.人物优先 2.怪物优先 3只搜索玩家 4只搜索怪物
%DeFendX 目标的x坐标
%DeFendY 目标的y坐标
%Rang 技能伤害距离
%NUM 技能最大目标
%返回 {PlayerList,MonsterList}
get_matrix_defenders(Type,SceneId,DeFendX,DeFendY,Rang,Num,RelationFun,Relation) ->
	get_shape_defenders(?MATRIX,Type,[SceneId,DeFendX,DeFendY,Rang],Num,RelationFun,Relation).

%获取扇形受击者列表
%Type 1.人物优先 2.怪物优先 3只搜索玩家 4只搜索怪物
%AtkX 攻击者的x坐标
%AtkY 攻击者的y坐标
%DirX 方向x坐标
%DirY 方向y坐标
%Rang 技能伤害距离
%Angle 扇形角度
%NUM 技能最大目标
%返回 {PlayerList,MonsterList}
get_sector_defenders(Type,SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle,Num,RelationFun,Relation) ->
	get_shape_defenders(?SECTOR,Type,[SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle],Num,RelationFun,Relation).

%%返回直线路径上的最远的可走点
%MapId 地图Id
%SrcX,SrcY 源坐标
%DestX,DestY 目标坐标  
%%返回值成功：{ok,ProperX,ProperY},碰到障碍返回:{block,ProperX,ProperY}失败：{fail,0,0}
find_src2dest_position(MapId,SrcX,SrcY,DestX,DestY) ->
	case SrcX =:= DestX andalso SrcY =:= DestY of
		true ->
			{ok,DestX,DestY};
		false ->
			case DestX > SrcX of
				true ->
					DirectX = [1,0];
				false ->
					DirectX = [-1,0]
			end,
			case DestY > SrcY of
				true ->
					DirectY = [0,1];
				false ->
					DirectY = [0,-1]
			end,
			case abs(DestX - SrcX) > abs(DestY - SrcY) of
				true ->
					MainDirect = DirectX,
					SecondDirect = DirectY;
				false ->
					MainDirect = DirectY,
					SecondDirect = DirectX
			end,
			find_next_point_to_dest(MapId,SrcX,SrcY,SrcX,SrcY,DestX,DestY,MainDirect,SecondDirect,true)
	end.
	

%%返回击退后的坐标
%MapId 地图Id
%AtkX,AtkY 攻击者坐标
%DefX,DefY 受击者坐标
%Dist 击退距离
%%返回值成功：{ok,ProperX,ProperY},失败：{fail,0,0}
beat_back_position(MapId,AtkX,AtkY,DefX,DefY,Dist) ->
	DistAD = util:distance({AtkX,AtkY},{DefX,DefY}),
	case DistAD > 0 of
		true ->
			CosD = (DefX -AtkX) / DistAD,
			SinD = (DefY -AtkY) / DistAD,
			DestX = DefX + round(Dist * CosD),
			DestY = DefY + round(Dist * SinD),
			find_src2dest_position(MapId, DefX, DefY, DestX, DestY);
		false ->
			{ok,DefX,DefY}
	end.
%%战斗相关的扫描玩家和怪物外部接口END%%%%

%%战斗相关的扫描玩家和怪物内部接口BEGIN%%%%
get_shape_defenders(ScanType,Type,Args,Num,RelationFun,Relation) ->
	Defenders = if 
		Type =:= ?PLAYER_FIRST ->
			ObjList = get_players_by_scan_type(ScanType,Args),
			get_defenders_sub(ScanType,?PLAYER_FIRST,Args,Num,ObjList,[],[],false,RelationFun,Relation);
		Type =:= ?MONSTER_FIRST ->
			ObjList = get_monsters_by_scan_type(ScanType,Args),
			get_defenders_sub(ScanType,?MONSTER_FIRST,Args,Num,ObjList,[],[],false,RelationFun,Relation);
		Type =:= ?PLAYER_ONLY ->
			ObjList = get_players_by_scan_type(ScanType,Args),
			get_defenders_sub(ScanType,?PLAYER_FIRST,Args,Num,ObjList,[],[],true,RelationFun,Relation);
		Type =:= ?MONSTER_ONLY ->
			ObjList = get_monsters_by_scan_type(ScanType,Args),
			get_defenders_sub(ScanType,?MONSTER_FIRST,Args,Num,ObjList,[],[],true,RelationFun,Relation);
		true ->
			[]
	end,
	Defenders.

get_defenders_sub(ScanType,Type,Args,0,ObjList,ResultPlayer,ResultMonster,Flag,RelationFun,Relation) ->
	{ResultPlayer,ResultMonster};
get_defenders_sub(ScanType,Type,Args,Num,ObjList,ResultPlayer,ResultMonster,Flag,RelationFun,Relation) ->
	if 
		Type =:= ?PLAYER_FIRST ->
			case fliter_one_player(ScanType,Args,ObjList,RelationFun,Relation) of
				fail -> 
					if 
					   Flag =:= false ->
							Flag2 = true,
							ObjList2 = get_monsters_by_scan_type(ScanType,Args),
							get_defenders_sub(ScanType,?MONSTER_FIRST,Args,Num,ObjList2,ResultPlayer,ResultMonster,Flag2,RelationFun,Relation);
					   true ->
						   	{ResultPlayer,ResultMonster}
					end;
				PlayerId ->
					ObjList2 = ObjList -- [PlayerId],
					ResultPlayer2 = ResultPlayer ++ [PlayerId],
					get_defenders_sub(ScanType,?PLAYER_FIRST,Args,Num-1,ObjList2,ResultPlayer2,ResultMonster,Flag,RelationFun,Relation)
			end;
		Type =:= ?MONSTER_FIRST ->
			case lib_mon:fliter_one_monster(ScanType,Args,ObjList,RelationFun,Relation) of
				fail ->
					if 
						Flag =:= false ->
							Flag2 = true,
							ObjList2 = get_players_by_scan_type(ScanType,Args),
							get_defenders_sub(ScanType,?PLAYER_FIRST, Args, Num,ObjList2,ResultPlayer,ResultMonster,Flag2,RelationFun,Relation);
						true ->
						    {ResultPlayer,ResultMonster}
					end;
				MonsterId ->
					ObjList2 = ObjList -- [MonsterId],
					ResultMonster2 = ResultMonster ++ [MonsterId],
					get_defenders_sub(ScanType,?MONSTER_FIRST, Args, Num - 1,ObjList2,ResultPlayer,ResultMonster2,Flag,RelationFun,Relation)
			end;
		true ->
			skip
	end.

get_players_by_scan_type(ScanType,Args) ->
	case ScanType of
		?STRAIGHT ->
			[SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang] = Args,
			{SliceX,SliceY} = util:get_xy_slice(DeFendX,DeFendY),
			get_zone_playerlist(SceneId,SliceX,SliceY);
		?SECTOR ->
			[SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle] = Args,
			{SliceX,SliceY} = util:get_xy_slice(AtkX,AtkY),
			get_zone_playerlist(SceneId,SliceX,SliceY);
		?MATRIX ->
			[SceneId,DeFendX, DeFendY, Rang] = Args,
			{SliceX,SliceY} = util:get_xy_slice(DeFendX,DeFendY),
			get_zone_playerlist(SceneId,SliceX,SliceY);
		_ ->
			[]
	end.

get_monsters_by_scan_type(ScanType,Args) ->
	case ScanType of
		?STRAIGHT ->
			[SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang] = Args,
			lib_mon:scan_monsters(DeFendX,DeFendY,Rang);
		?SECTOR ->
			[SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle] = Args,
			lib_mon:scan_monsters(AtkX,AtkY,Rang);
		?MATRIX ->
			[SceneId,DeFendX, DeFendY, Rang] = Args,
			lib_mon:scan_monsters(DeFendX,DeFendY,Rang);
		_ ->
			[]
	end.

fliter_one_player(ScanType,Args,[],RelationFun,Relation) ->
	fail;
fliter_one_player(ScanType,Args,[PlayerId|LeftPlayerIds],RelationFun,Relation) ->
	case get_scene_player(PlayerId) of
		Player when is_record(Player,player) ->
			PX = Player#player.battle_attr#battle_attr.x,
			PY = Player#player.battle_attr#battle_attr.y,
			case RelationFun(Relation,{ Player#player.camp}) of
				true ->
					case check_fun(ScanType,Args,PX,PY) of
						true ->
							PlayerId;
						false ->
							fliter_one_player(ScanType,Args,LeftPlayerIds,RelationFun,Relation)
					end;
				false ->
					fliter_one_player(ScanType,Args,LeftPlayerIds,RelationFun,Relation)
			end;
		_ ->
			fliter_one_player(ScanType,Args,LeftPlayerIds,RelationFun,Relation)
	end.

check_fun(ScanType,Args,PX,PY) ->
	case ScanType of
		?STRAIGHT ->
			[SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang] = Args,
			check_in_straight_line(AttrX,AttrY,DeFendX,DeFendY,PX,PY,Rang);
		?SECTOR ->
			[SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle] = Args,
			check_in_sector(AtkX,AtkY,DirX,DirY,PX,PY,Rang,Angle);
		?MATRIX ->
			[SceneId,DeFendX, DeFendY, Range] = Args,
			Dist = util:distance({DeFendX,DeFendY},{PX,PY}), 
			Dist =< Range;
		_ ->
			false
	end.

check_in_sector(AtkX,AtkY,DirX,DirY,X,Y,Rang,Angle) ->
	DefX = AtkX + DirX,
	DefY = AtkY - DirY,
	DistAB = math:sqrt(DirX*DirX+DirY*DirY),
	DistAC = math:sqrt((X-AtkX)*(X-AtkX)+(Y-AtkY)*(Y-AtkY)),
	case DistAB >= 0.001 andalso DistAC >= 0.001 of 
		true ->
			DistBC = math:sqrt((X-DefX)*(X-DefX)+(Y-DefY)*(Y-DefY)),
			COSA = (DistAB*DistAB+DistAC*DistAC-DistBC*DistBC)/(2*DistAB*DistAC),
			COSA - math:cos(Angle/360*3.1415) >= -0.001 andalso Rang >= DistAC;
		false ->
			true
	end.

check_in_straight_line(AttrX,AttrY,DeFendX,DeFendY,X,Y,Rang) ->
	ZFlag = case AttrX =:= DeFendX andalso AttrY =:= DeFendY of
		true ->
			DeFendX =:= X andalso DeFendY =:= Y;
		false ->
			true
	end,
	XFlag = case AttrX >= DeFendX of 
		true ->
			DeFendX >= X;
		false ->
			X >= DeFendX
	end,
	YFlag = case AttrY >= DeFendY of 
		true ->
			DeFendY >= Y;
		false ->
			Y >= DeFendY
	end,
	case XFlag andalso YFlag andalso ZFlag of
		true ->
			A = DeFendY - AttrY,
			B = AttrX - DeFendX,
			C = AttrY*(DeFendX-AttrX)-AttrX*(DeFendY-AttrY),
			Sqrt = math:sqrt(math:pow(A, 2)+math:pow(B, 2)),
			case Sqrt > 0 of 
				true ->
					Dist = abs(A*X+B*Y+C)/Sqrt,
					Dist2 = util:distance({DeFendX,DeFendY},{X,Y}),
					Dist =< 1 andalso Dist2 =< Rang;
				false ->
					true
			end;
		false ->
			false
	end.
%%战斗相关的扫描玩家和怪物内部接口END%%%%

%@spec 获取跟指定坐标同九宫格区域的玩家
get_squre_players(SceneId,X,Y,Range) ->
	{X1,Y1,X2,Y2} = {X - Range, Y - Range, X + Range,  Y + Range } ,
	EtsName = get_ets_name(SceneId) ,
	MS = ets:fun2ms(fun(P) when P#player.battle_attr#battle_attr.x >= X1 andalso
								P#player.battle_attr#battle_attr.x =< X2 andalso
								P#player.battle_attr#battle_attr.y >= Y1 andalso
								P#player.battle_attr#battle_attr.y =< Y2 andalso 
				  				P#player.battle_attr#battle_attr.hit_point > 0 ->  P end) ,
	ets:select(EtsName, MS) .


%@spec 获取跟指定坐标同九宫格区域的玩家（除了自己）
get_squre_players(SceneId,ExceptUId,X,Y,Range) ->
	{X1,Y1,X2,Y2} = {X - Range, Y - Range, X + Range, Y + Range } ,
	EtsName = get_ets_name(SceneId) ,
	MS = ets:fun2ms(fun(P) when P#player.battle_attr#battle_attr.x >= X1 andalso
								P#player.battle_attr#battle_attr.x =< X2 andalso
								P#player.battle_attr#battle_attr.y >= Y1 andalso
								P#player.battle_attr#battle_attr.y =< Y2 andalso 
				  				P#player.battle_attr#battle_attr.hit_point > 0 andalso 
				  				P#player.id =/= ExceptUId->  P end) ,
	ets:select(EtsName, MS) .

get_squre_players(X,Y,AttackArea,AttackTargetNum,SceneId,RelationInfo,RelationFun)->
	EtsName = get_ets_name(SceneId) ,
	AllPlayer = ets:tab2list(EtsName) ,
	X1 = X - AttackArea ,
	X2 = X + AttackArea ,
	Y1 = Y - AttackArea ,
	Y2 = Y + AttackArea ,  
	get_squre_players(AllPlayer,X1,X2,Y1,Y2,AttackTargetNum,0,[],RelationInfo,RelationFun).

get_squre_players([],_,_,_,_,_,LenIndex,Result,RelationInfo,RelationFun)->
	{Result,LenIndex};
get_squre_players(_,_,_,_,_,MaxNum,MaxNum,Result,RelationInfo,RelationFun)->
	{Result,MaxNum};
get_squre_players([P|Rest],X1,X2,Y1,Y2,MaxNum,LenIndex,Result,RelationInfo,RelationFun)-> 
	RelationResult =  RelationFun(RelationInfo,{P#player.camp}) ,
	if   P#player.battle_attr#battle_attr.x  >= X1 andalso 
											  P#player.battle_attr#battle_attr.x  =< X2 andalso 
											  P#player.battle_attr#battle_attr.y  >= Y1 andalso 
											  P#player.battle_attr#battle_attr.y  =< Y2 andalso 
											  P#player.battle_attr#battle_attr.hit_point > 0  andalso 
											  RelationResult =:= true->
			 get_squre_players(Rest,X1,X2,Y1,Y2,MaxNum,LenIndex+1,[P]++Result,RelationInfo,RelationFun);
		 true -> 
			 get_squre_players(Rest,X1,X2,Y1,Y2,MaxNum,LenIndex,Result,RelationInfo,RelationFun)
	end.

  
%%--------------------------------------------------
%% @spec 玩家进入小村镇的初始坐标和场景标识 
get_default_scene() -> 
	case get_scene_tmpl(101) of
		ScnTpl when is_record(ScnTpl,temp_scene) ->
			{10101,ScnTpl#temp_scene.x,ScnTpl#temp_scene.y} ;
		_ ->
			{10101,util:rand(12,16),util:rand(5,9)}
	end .
 
 
%%检查玩家步行移动时候的新位置是否合法(为了实现容错，暂时设定阀值为8)
check_newposition(Status,[DestX,DestY])->
    %io:format("cxf_test:x:~p,y:~p,Sx:~p,Sy:~p,Dx:~p,Dy:~p~n",[abs(Status#player.battle_attr#battle_attr.x-DestX),abs(Status#player.battle_attr#battle_attr.y-DestY),Status#player.battle_attr#battle_attr.x,Status#player.battle_attr#battle_attr.y,DestX,DestY]),
    if
        abs(Status#player.battle_attr#battle_attr.x - DestX) =< 8 andalso abs(Status#player.battle_attr#battle_attr.y - DestY) =< 8 ->
           true;
        true ->
           false 
    end. 

%%地图格子相关接口BEGIN%%%%
%%地图障碍点
%%搜索附近点
check_dest_position(MapId,[DestX,DestY],Index)->
	{AppX,AppY} = helixIndex2coord(Index),
	NextX = DestX+AppX,
	NextY = DestY+AppY,
	case get_position_info(MapId, NextX, NextY) of
		{ok,Type,Row,Col} ->
			if 
				Row =:= 0 andalso Col =:= 0 ->
					?ERROR_MSG("[lib_scene]check_dest_position read map error:MapId:~pX:~pY:~p~n",[MapId,NextX,NextY]),
					{nomap,Row,Col};
				Index =:= 1 andalso (NextX < 0 orelse NextY < 0 orelse NextX >Col orelse NextY > Row) ->
					?ERROR_MSG("[lib_scene]check_dest_position out of line :MapId:~pX:~pY:~p~n",[MapId,NextX,NextY]),
					{outofline,Row,Col};
				NextX < 0 orelse NextY < 0 orelse NextX >Col orelse NextY > Row ->
					check_dest_position(MapId,[DestX,DestY],Index+1);
				Type =:= ?GRID_BLOCK ->
					check_dest_position(MapId,[DestX,DestY],Index+1);
				true ->
					{ok,NextX,NextY}
			end;
		_ ->
			fail
	end.
	
find_next_point_to_dest(MapId,CurX,CurY,SrcX,SrcY,DestX,DestY,MainDirect,SecondDirect,IsDirChanged) ->
	case IsDirChanged of
		true ->
			IsDirChanged2 = false,
			Direct = MainDirect;
		false ->
			%%compare
			PointA = [CurX + lists:nth(1, MainDirect),CurY + lists:nth(2, MainDirect)],
			PointB = [CurX + lists:nth(1, SecondDirect),CurY + lists:nth(2, SecondDirect)],
			A = SrcY - DestY,
			B = DestX - SrcX,
			C = DestY*(SrcX-DestX)-DestX*(SrcY-DestY),
			Sqrt = math:sqrt(math:pow(A, 2)+math:pow(B, 2)),
			case Sqrt > 0 of 
				true ->
					Dist1 = abs(A*lists:nth(1, PointA)+B*lists:nth(2, PointA)+C)/Sqrt,
					Dist2 = abs(A*lists:nth(1, PointB)+B*lists:nth(2, PointB)+C)/Sqrt,
					if 
						Dist1 > Dist2 ->
							IsDirChanged2 = true,
							Direct = SecondDirect;
						true ->
							IsDirChanged2 = false,
							Direct = MainDirect							
					end;
				false ->
					IsDirChanged2 = IsDirChanged,
					Direct = MainDirect
			end
	end,
	NextX = CurX + lists:nth(1, Direct),
	NextY = CurY + lists:nth(2, Direct),
	if 
		NextX =:= DestX andalso NextY =:= DestY  ->
			{ok,CurX,CurY};
		true ->
			case get_position_info(MapId, NextX, NextY) of
				{ok,Type,Row,Col} ->
					if 
						NextX < 0 orelse NextY < 0 orelse NextX >Col orelse NextY > Row ->
							{block,CurX,CurY};
						Type =:= ?GRID_BLOCK ->
							{block,CurX,CurY};
						true ->
							find_next_point_to_dest(MapId,NextX,NextY,SrcX,SrcY,DestX,DestY,MainDirect,SecondDirect,IsDirChanged2)
					end;
				_ ->
					?TRACE("get_position_info fail~n"),
					{fail,0,0}
			end
	end.
	
set_player_position(Status,[SrcX,SrcY,DestX,DestY])->
	case check_dest_position(Status#player.scene div 100,[SrcX,SrcY,DestX,DestY],1) of
		{ok,ProperX,ProperY} ->
			update_postion(Status,ProperX,ProperY),
			{ok,ProperX,ProperY};
		_ ->
			{fail,0,0}
	end.

%% correct_player_position(Status,[DestX,DestY])->
%% 	case check_dest_position(Status#player.scene div 100,[DestX,DestY],1) of
%% 		{ok,ProperX,ProperY} ->
%% 			update_postion(Status,ProperX,ProperY),
%% 			{ok,BinData} = pt_12:write(12011,[Status#player.id,ProperX,ProperY]),
%% 			mod_scene_agent:send_to_matrix(Status#player.scene, ProperX, ProperY, BinData),
%% 			{ok,ProperX,ProperY};
%% 		_ ->
%% 			{fail,0,0}
%% 	end.

read_map_config(MapId,IconPath) ->
	Path = "../src/map/" ++ IconPath ++ "/MapTile.xml", %%TODO路径
	case file:read_file_info(Path) of 
		{ok,_} ->
			{XmlElt,_} = xmerl_scan:file(Path),
			Items = xmerl_xpath:string("/root/mapGrid",XmlElt),
			Item = lists:nth(1,Items),
			[#xmlAttribute{value=GridRowString}] = xmerl_xpath:string("/mapGrid/@gridRow",Item),
			{GridRow,_} = string:to_integer(GridRowString),
			[#xmlAttribute{value=GridColString}] = xmerl_xpath:string("/mapGrid/@gridCol",Item),
			{GridCol,_} = string:to_integer(GridColString),
			MapData = xmerl_xpath:string("/root/mapData",XmlElt),
			[#xmlElement{content=Content}] = MapData,
			[#xmlText{value=Value}] = Content,
			{ok,#scene_map_info{map_id = MapId,grid_row = GridRow,grid_col = GridCol,grid_type = Value}};
		_ ->
			if IconPath =/= "0" ->
					?ERROR_MSG("ERROR::MAP ~p CONFIG LOADED FAIL~n",[MapId]);
				true ->
					skip
			end,
			{ok,#scene_map_info{map_id = MapId,grid_row = 0,grid_col = 0,grid_type = "0"}}
	end.

load_scene_map_info() ->
	SceneList = ets:tab2list(?ETS_TEMP_SCENE),
	lists:foreach(fun(S) ->
						case lib_scene:read_map_config(S#temp_scene.sid,binary_to_list(S#temp_scene.icon)) of
						{ok,MapInfo} ->
							ets:insert(?ETS_SCENE_MAP_INFO, MapInfo);
						_ ->
							skip
						end
					end,SceneList),
%% 	io:format("load_base_data(map_info)"),
%% 	lists:foreach(fun(S) ->
%% 					io:format("~p~p~n",[S#scene_map_info.map_id,S#scene_map_info.grid_type])
%% 					end, ets:tab2list(?ETS_SCENE_MAP_INFO)),
	ok.

get_position_info(MapId,X,Y) ->
try 
  	case ets:lookup(?ETS_SCENE_MAP_INFO, MapId) of
  		[MapInfo|_] when is_record(MapInfo,scene_map_info) ->
  			MapType = MapInfo#scene_map_info.grid_type,
  			Row = MapInfo#scene_map_info.grid_row,
  			Col = MapInfo#scene_map_info.grid_col,
  			if 
  				X < 0 orelse Y < 0 orelse X >= Col orelse Y >= Row ->
  					{ok,?GRID_BLOCK,Row,Col};
  				true ->
  					Index = (Y + 1 - 1) * Col + (X + 1),
  					Type = lists:nth(Index,MapType) - 48,
  					{ok,Type,Row,Col}
  			end;
  		_ ->
  			fail
  	end
catch
	_:Reason -> 
		?DEBUG("test_position_type fail for the reason:[~p]",[Reason]),
		fail
end .

test_pos_cost_time(Num) ->
	Start = erlang:now(),
	lists:foreach(fun(WorkerId) ->
						  get_position_info(107,20,20)
				end,lists:seq(1, Num)),
	Stop = erlang:now(),
	io:format("test_pos_cost_time~p~n",[time_diff(Start,Stop)]).

time_diff({A1,A2,A3}, {B1,B2,B3}) ->
    (B1 - A1) * 1000000 + (B2 - A2) + (B3 - A3) / 1000000.0 . 

%%%%%%%%%%%%%%%%%%%%
%%21 22 23 24 25
%%20 7  8  9  10
%%19 6  1  2  11
%%18 5  4  3  12
%%17 16 15 14 13
%%%%%%%%%%%%%%%%%%%%
%%Tv = max + y + x
%%Lv = max + 3x - y
%%Bv = max - x - 5y
%%Rv = max - 7x + y
%%%%%%%%%%%%%%%%%%%%
helixIndex2coord(Index) ->
	Circle = find_circle(Index,0),
	Side = find_side(Index,Circle,0),
	Max = (2*Circle+1)*(2*Circle+1),
	{X,Y} = if 
		Side =:= 0 ->
			{0,0};
	%%top
		Side =:= 1 ->
			My = -Circle,
			Mx = Index - Max - (My),
			{Mx,My};
	%%left
		Side =:= 2 ->
			Mx = -Circle,
			My = Max + 3*Mx - Index,
			{Mx,My};
	%%bottom
		Side =:= 3 ->
			My = Circle,
			Mx = Max - 5*My - Index,
			{Mx,My};
	%%right
		Side =:= 4 ->
			Mx = Circle,
			My = Index - Max + 7*Mx,
			{Mx,My}
	end,
	{X,Y}.

find_circle(Index,C)->
	if 
		1 =:= Index ->
			0;
		(2*C+1)*(2*C+1) >= Index ->
			C;
		true ->
			find_circle(Index,C+1)
	end.

find_side(Index,Circle,S) ->
	if 
		 0 =:= Circle ->
			0;
		(2*Circle+1)*(2*Circle+1)-(S+1)*(2*Circle+1 - 1) < Index ->
			S+1;
		true ->
			find_side(Index,Circle,S+1)
	end.

test_slice_obj(Status) ->
	gen_server:cast(Status#player.other#player_other.pid_scene, {apply_cast, lib_scene, print_slice_obj, [Status]}),
	ok.
	

print_slice_obj(Status) ->
	MapId = Status#player.scene div 100,
	PosX = Status#player.battle_attr#battle_attr.x,
	PosY = Status#player.battle_attr#battle_attr.y,
	{SliceX,SliceY} = util:get_xy_slice(PosX,PosY),
	case get_position_info(MapId, PosX, PosY) of
		{ok,Type,Row,Col} ->
			lists:foreach(fun(R) ->
								  lists:foreach(fun(C) ->
										%%ObjList = get({C,R,sliceplayer}),
										ObjList = get_scene_slice(Status#player.scene,C,R),
										io:format("test_slice_obj::SX~p::SY~p::List::~p~n",[R,C,ObjList])
										end, lists:seq(0, Col div ?SLICEWIDTH))
								  end, lists:seq(0, Row div ?SLICEHEIGHT));
		_ ->
			skip
	end.
			
test_grid_warn(PId,X,Y) ->
	gen_server:cast(PId, {apply_cast, lib_scene, print_grid_warn, [X,Y]}),
	ok.

print_grid_warn(X,Y) ->
	NewList = get({X,Y,warn}),
	io:format("print_grid_warn::~p~n",[NewList]).
%%地图格子相关接口END%%%%

%%处理第一个玩家进入场景时候，需要通知场景怪物进程开启
monEvent_FirstPlayerComming(Status) ->
    NowTime = util:longunixtime(),
    SendMsg2Mon = fun(OneMon) ->
            OneMon#temp_mon_layout.pid ! {'scene_create'},
            OneMon#temp_mon_layout.pid ! {'player_showing_up',Status#player.other#player_other.pid_scene,NowTime}%%开始调用怪物定时器
    end,

    case is_dungeon_scene(Status#player.scene) of
        false ->
            ScenePlayerNum = lib_scene:get_scene_player_number(Status#player.scene),
            if
                ScenePlayerNum =:= 1 ->
                    Monsters = lib_mon:get_monsters(),
                    [SendMsg2Mon(EachMon) || EachMon <- Monsters];
                true ->
                    skip
            end;
        true ->
            skip
    end.

%%处理最后一个玩家退出场景时候，需要通知怪物进程关闭
monEvent_LastPlayerLeave(Status) ->
    NowTime = util:longunixtime(),
    
    SendMsg2Mon = fun(OneMon) ->
            skip
            %OneMon#temp_mon_layout.pid ! {'scene_erase'}
    end,

    case is_dungeon_scene(Status#player.scene) of
        false ->
            ScenePlayerNum = lib_scene:get_scene_player_number(Status#player.scene),
            if
                ScenePlayerNum =:= 1 ->%%如果玩家是最后一个离开该场景，则通知该场景的怪物，场景已取消
                    Monsters = lib_mon:get_monsters(),
                    [SendMsg2Mon(EachMon) || EachMon <- Monsters];
                true ->
                    skip
            end;
        true ->
            skip
    end.
