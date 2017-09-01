%%%-----------------------------------
%%% @Module  : lib_dungeon_monster
%%% @Author  : chenzm
%%% @Created : 2013.1.22
%%% @Description:  副本中怪物管理
%%%-----------------------------------
-module(lib_dungeon_monster).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("battle.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-define(MON_DEFAULT_SKILL,5) .
-define(MON_DEFAULT_SKILL_LV,1) .
-compile(export_all).
-export([load_monster/2,
		 create_monsters/2,
		 save_monster/3]).


save_monster(PlayerStatus,MonLayoutRcd,LeftHp) ->  
	case  is_record(MonLayoutRcd, temp_mon_layout) of
		true ->
			case LeftHp > 0 of     %% 怪物活着
				true -> 
					NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{
																		   state = ?MON_STATE_2_TRYATT },  
					lib_mon:save_monster(NewMonLayoutRcd) ;  
				false ->			
					lib_scene:erase_monster_skill_timer(MonLayoutRcd#temp_mon_layout.id),			
					lib_mon:remove_moster(MonLayoutRcd#temp_mon_layout.id) ,
                    %%NowTime = util:unixtime(),
                    %%NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = [] , target_uid = 0 , refresh_time = NowTime + ?MON_STATE_SPEED_7 + 1000*MonLayoutRcd#temp_mon_layout.revive_time ,state = ?MON_STATE_6_DEAD}, 
					%%处理怪物警戒格子
					lib_mon:update_monster_warn_area(MonLayoutRcd#temp_mon_layout.id,
							 MonLayoutRcd#temp_mon_layout.x,
							 MonLayoutRcd#temp_mon_layout.y,
							 0,0,
							 MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range),
					%% 处理怪物产出
					handle_monster_output(MonLayoutRcd, PlayerStatus#player.id)  , 
					%% 触发物件
					mod_dungeon:trigger_call_back(PlayerStatus,?CONDITION_MON_DEAD),
					%% 增加杀怪个数
					lib_dungeon:add_kill_monster(PlayerStatus#player.other#player_other.pid_send, 
												 MonLayoutRcd#temp_mon_layout.monid) 
			end;
			%%lib_mon:save_monster(NewMonLayoutRcd) ;  
		_ ->
			skip
	end . 
%% @spec 加载副本怪物信息
load_monster(SceneId,[]) ->
	case lib_mon:get_monsters() of 
		[] ->
            skip;
			%misc:cancel_timer(?MON_STATE_TIMER_KEY) ;
		_ ->
			%misc:cancel_timer(?MON_STATE_TIMER_KEY) ,
			NowTime = util:unixtime() ,
			NextTimer = NowTime + ?MON_STATE_SPEED_7,
			self()!{'reflesh_player_state',NowTime},
		%	erlang:send_after(?MON_STATE_SPEED_7, self(), {'mon_state_manage',SceneId,NowTime}) ,
			put(?MON_STATE_TIMER_KEY,NextTimer) 
	end ;
load_monster(SceneId,[{X,Y,MonId}|LeftMonList]) ->
	LayoutId = SceneId * 1000 + lib_mon:get_monster_id() ,

    case lib_scene:get_scene_npc(MonId) of
		NpcRcd when is_record(NpcRcd,temp_npc)  ->
            %%生成副本怪物进程
            DunMonProcessName = erlang:list_to_atom(lists:concat(["mon_"] ++ [SceneId] ++ [LayoutId])),
            case misc:whereis_name({local, DunMonProcessName}) of
                PrePid when is_pid(PrePid) ->
                    Pid = PrePid;
                _ ->
                    {ok,Pid} = mod_mon_fsm:start_link(DunMonProcessName,LayoutId)
           end,

			MonBattleAttrRcd = lib_player:init_base_battle_attr(NpcRcd#temp_npc.level, NpcRcd#temp_npc.npc_type) ,
			LayoutRcd = #temp_mon_layout{
										 monid = MonId ,
                                         monrcd = NpcRcd,
                                         %%ai_init_id用于保存初始的ai_id,用于重置ai
                                         battle_attr = MonBattleAttrRcd#battle_attr{x = X,y = Y,ai_init_id = NpcRcd#temp_npc.ai_id},
										 scene_id = SceneId ,
										 pos_x = X ,
										 pos_y = Y , 
										 x = X ,
										 y = Y ,
										 move_path = [] ,
										 state = ?MON_STATE_1_GUARD , %%guard--move--fight--return--dead--guard
										 attack_skill = 5 ,%%小怪普通攻击
										 sing_expire = 0 ,
										 skill_lv = 1 ,
										 refresh_time = 0 ,
										 last_move_time = 0 ,
										 hate_list = [] ,
										 buff_list = [] ,	%%记录没次循环前的BUFF列表
                                         pid = Pid ,
										 id = LayoutId} ,
			lib_mon:save_monster(LayoutRcd) ,

            Pid ! {'player_showing_up',self(),util:longunixtime()},%%通知怪物，有玩家进入副本
            Pid ! {'player_leaving',0},%%初始化State

			PosX = LayoutRcd#temp_mon_layout.x,
			PosY = LayoutRcd#temp_mon_layout.y,
			WarnRange = LayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range,
			lib_mon:update_monster_warn_area(LayoutId,0,0,PosX,PosY,WarnRange);
		_ ->
			skip
	end ,
	load_monster(SceneId,LeftMonList) .

create_monsters([],Status) ->
	ok;
create_monsters([{X,Y,MonId} | LeftList],Status) ->
	SceneId = Status#player.scene,
	LayoutId = SceneId * 1000 + lib_mon:get_monster_id() ,

    case lib_scene:get_scene_npc(MonId) of
		NpcRcd when is_record(NpcRcd,temp_npc)  ->
            %%生成副本怪物进程
            DunMonProcessName = erlang:list_to_atom(lists:concat(["mon_"] ++ [SceneId] ++ [LayoutId])),
            case misc:whereis_name({local, DunMonProcessName}) of
                PrePid when is_pid(PrePid) ->
                    Pid = PrePid;
                _ ->
                    {ok,Pid} = mod_mon_fsm:start_link(DunMonProcessName,LayoutId)
           end,

			MonBattleAttrRcd = lib_player:init_base_battle_attr(NpcRcd#temp_npc.level, NpcRcd#temp_npc.npc_type) ,
			LayoutRcd = #temp_mon_layout{
										 monid = MonId ,
                                         monrcd = NpcRcd,
                                         %%ai_init_id用于保存初始的ai_id,用于重置ai
                                         battle_attr = MonBattleAttrRcd#battle_attr{x = X,y = Y,ai_init_id = NpcRcd#temp_npc.ai_id},
										 scene_id = SceneId ,
										 pos_x = X ,
										 pos_y = Y , 
										 x = X ,
										 y = Y ,
										 move_path = [] ,
										 state = ?MON_STATE_1_GUARD , %%guard--move--fight--return--dead--guard
										 attack_skill = 5 ,%%小怪普通攻击
										 sing_expire = 0 ,
										 skill_lv = 1 ,
										 refresh_time = 0 ,
										 last_move_time = 0 ,
										 hate_list = [] ,
										 buff_list = [] ,	%%记录没次循环前的BUFF列表
                                         pid = Pid ,
										 id = LayoutId} ,
			lib_mon:save_monster(LayoutRcd) ,

            Pid ! {'player_showing_up',self(),util:longunixtime()},%%通知怪物，有玩家进入副本
            Pid ! {'player_coming',LayoutRcd,Status#player.other#player_other.pid_scene,Status},%%让怪物主动进入战斗
            %%Pid ! {'player_leaving',0},%%初始化State

			PosX = LayoutRcd#temp_mon_layout.x,
			PosY = LayoutRcd#temp_mon_layout.y,
			WarnRange = LayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range,
			lib_mon:update_monster_warn_area(LayoutId,0,0,PosX,PosY,WarnRange);
		_ ->
			skip
	end ,
	create_monsters(LeftList,Status).


%%@spec 修改怪物当前BUFF列表
%% 1.判断BUFF有无变化
%% 2.广播有变化的BUFF列表
update_buff([],NewMonList,BuffList) ->
	{ok,BuffBin} = pt_12:write(12013,[BuffList]) ,
	case lib_dungeon:get_player() of
		Player when is_record(Player,player) ->
			lib_send:send_to_sid(Player#player.other#player_other.pid_send, BuffBin) ;
		_ ->
			skip
	end ,
	
	NewMonList ;
update_buff([MonRcd|LeftMonList],NewMonList,BuffList) ->
	NewBuffList = MonRcd#temp_mon_layout.battle_attr#battle_attr.skill_buff ,
	OldBuffList = MonRcd#temp_mon_layout.buff_list ,
	NewBuffIDList = lists:sort([BuffId || {BuffId,_} <- NewBuffList]) ,
	OldBuffIDList = lists:sort([BuffId || {BuffId,_} <- OldBuffList]) ,
	case NewBuffIDList =/= OldBuffIDList of
		true ->
			NewBuffList = [{MonRcd#temp_mon_layout.id,NewBuffList} | BuffList ] ;
		false ->
			NewBuffList = BuffList 
	end ,
	NewMonRcd = MonRcd#temp_mon_layout{buff_list = NewBuffList} ,
	update_buff(LeftMonList,[NewMonRcd|NewMonList],NewBuffList) .



%% @spec 怪物掉落广播
%% handle_monster_drop(PlayerStatus,MonLayoutRcd) ->
%% 	case lib_drop:get_drop_goods(MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.drop_id) of
%% 		[] ->
%% 			skip ;
%% 		DataList ->
%% 			{DropX,DropY} = lib_mon:get_drop_postion(MonLayoutRcd#temp_mon_layout.pos_x,MonLayoutRcd#temp_mon_layout.pos_y) ,
%% 			NowTime = util:unixtime() ,
%% 			Fun = fun({GoodsId,GoodsNum}) ->
%% 						  DropRcd = #mon_drop_goods{
%% 													mon_id = MonLayoutRcd#temp_mon_layout.id ,
%% 													goods_id = GoodsId ,
%% 													goods_num = GoodsNum ,
%% 													x = DropX ,
%% 													y = DropY ,
%% 													drop_time =  NowTime 
%% 												   } ,
%% 						  DropRcd
%% 				  end ,
%% 			NewDataList = lists:map(Fun, DataList) ,
%% 			OldDropList = lib_mon:get_monster_drops() ,
%% 			?TRACE("===1 =handle_monster_drop====~p~n",[[NewDataList,OldDropList]]) ,
%% 			NewDropList = lib_mon:refresh_monster_drops(NewDataList ++ OldDropList,[],NowTime) ,
%% 			?TRACE("===2 =handle_monster_drop====~p~n",[NewDropList]) ,
%% 			lib_mon:save_monster_drops(NewDropList) ,
%% 			
%% 			{ok,DropBin} = pt_12:write(12015, [NewDataList]) ,
%% 			lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, DropBin) 
%% 	end .


%% 怪物产出发放
handle_monster_output(MonLayoutRcd,UId) ->
	%% 获取需要发放的物品
	case lib_drop:get_drop_goods(MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.output_id) of
		[] ->
			skip ;
		DataList ->
			PlayerProcessName = misc:player_process_name(UId) ,
			case misc:whereis_name({local,PlayerProcessName}) of
				PlayerPId when is_pid(PlayerPId) ->
					gen_server:cast(PlayerPId,{add_goods, DataList, ?LOG_GOODS_MON})  ;
				_ ->
					skip
			end 
	end .

%% 清除副本里面的怪物
clear_monsters() ->
%% 	DunMons = lib_mon:get_monsters(),
%% 	lists:foreach(fun(MonRcd)->
%% 						  lib_mon:update_monster_warn_area(MonRcd#temp_mon_layout.id,
%% 														   MonRcd#temp_mon_layout.x,
%% 														   MonRcd#temp_mon_layout.y,
%% 							 								0,0,
%% 							 							   MonRcd#temp_mon_layout.monrcd#temp_npc.warn_range),
%% 				end, DunMons),
	erase(?SECNE_MON) .

