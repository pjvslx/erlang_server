%%%--------------------------------------
%%% @Module  : pp_scene
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description:  场景
%%%--------------------------------------
-module(pp_scene).
-include("common.hrl").
-include("log.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).


%% 玩家进入场景
%% 1、进入新场景
%% 2、刷新进入
%% 4、进入副本不修改玩家结构上的scene
handle(12001, Status, [SceneId,PosX,PosY]) ->   
	{NewSceneId,X,Y} = lib_scene:check_eneter(SceneId,Status,PosX,PosY) ,
	?TRACE("======handle(12001:~p ~p ~p~n", [NewSceneId,X,Y]) ,
	if
		NewSceneId > 0 ->  
			case mod_scene:enter_scene(NewSceneId,Status,X,Y) of 
				{ok,NewStatus} ->
					%%1.0 判断是不是副本场景
					case lib_scene:is_dungeon_scene(NewSceneId) of
						true ->
							skip ;  
						false ->
							%%1.0  场景代理广播有新玩家加入
							{ok, EnterBin} = pt_12:write(12003, [NewStatus]),
							mod_scene_agent:send_to_matrix(NewStatus#player.scene, 
														   NewStatus#player.battle_attr#battle_attr.x, 
														   NewStatus#player.battle_attr#battle_attr.y,
														   EnterBin,NewStatus#player.id) 
					end ,
					%%2.0 离开原来的场景
					%%case Status#player.scene =/= NewSceneId of
					%%	true ->
					%%		mod_scene:leave_scene(Status#player.scene,Status#player.other#player_other.pid_scene,Status#player.id),
					%%		{ok,LeaveBin} = pt_12:write(12004, [Status#player.id]) ,
					%%		mod_scene_agent:send_to_matrix(Status#player.scene, Status#player.battle_attr#battle_attr.x, Status#player.battle_attr#battle_attr.y, LeaveBin) ;
					%%	false ->
					%%		skip
					%%end , 
                    pp_scene:handle(12011, NewStatus,[X,Y]),
					{ok,NewStatus} ;
				_ ->
					pack_and_send(Status, 12001, [0,0,0])
            end;
		true ->
			pack_and_send(Status, 12001, [0,0,0])
	end ;


%% 玩家离开场景
handle(12004, Status, []) ->
	{ok, BinData} = pt_12:write(12004, [Status#player.id]),
	mod_scene_agent:send_to_matrix(Status#player.scene, Status#player.battle_attr#battle_attr.x, Status#player.battle_attr#battle_attr.y, BinData,Status#player.id),
	mod_scene:leave_scene(Status#player.scene,Status#player.other#player_other.pid_scene,Status#player.id),
	ok ;

%%前端创建场景ok返回
handle(12005, Status, []) ->
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		true ->
			mod_dungeon:enter_scene_ok(Status);
		false ->
			mod_scene:enter_scene_ok(Status)
	end,
	ok;

%% 玩家走路广播
handle(12010, Status, [X,Y,Len,WarkPathBin]) ->
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		false -> 
			{DestX,DestY} = lib_scene:check_stoptable_pos(X,Y,Status#player.battle_attr),
            if
                Status#player.battle_attr#battle_attr.hit_point> 0 ->
			        %%1.0  告诉同屏的玩家，某人要开始走路了
					{ok, BinData} = pt_12:write(12010, [Status#player.id,DestX,DestY,Len,WarkPathBin]) ,
					mod_scene_agent:send_to_matrix(Status#player.scene, 
												Status#player.battle_attr#battle_attr.x, 
												Status#player.battle_attr#battle_attr.y, 
												BinData,Status#player.id) ,
					case lib_scene:get_scene_player(Status#player.scene,Status#player.id) of
						Player when is_record(Player,player) ->
							BattleAttr = Player#player.battle_attr#battle_attr{walk_path = [DestX,DestY,Len,WarkPathBin]} ,
							lib_scene:update_scene_player(Player,{#player.battle_attr,BattleAttr});
						_ ->
							skip
					end,
			        %OldX = Status#player.battle_attr#battle_attr.x,
			        %OldY = Status#player.battle_attr#battle_attr.y,
			        %%2.0 查看目标和当前位置的关系
			        %if 
			        %	OldX =/=  DestX andalso OldY =/= DestY andalso lib_scene:check_newposition(Status,[DestX,DestY]) ->
			        %		BattleAttr = Status#player.battle_attr#battle_attr{x = DestX, y = DestY } ,
			        %		NewStatus = Status#player{battle_attr = BattleAttr } ;
			        %	true ->
			        %		NewStatus = Status
			        %end ,
			
%% 			       {ok,NewStatus} ;
                    ok;
                true ->
                    ok
            end;
		true ->
			ok
    end; 
	

%% 玩家位置同步(在需要同步的客户端请求协议)
handle(12011, Status, [X,Y]) ->
    PlayerId = Status#player.id,
    NowTime = util:longunixtime() , 
    _MinTimeStamp = 100/Status#player.battle_attr#battle_attr.speed,%%允许接受协议最小的时间间隔

    case tool:is_operate_ok(lists:concat([pp_12011]), 0) andalso Status#player.battle_attr#battle_attr.hit_point> 0 of
		true ->    
			{DestX,DestY} = lib_scene:check_stoptable_pos(X,Y,Status#player.battle_attr),
            case lib_scene:check_newposition(Status,[DestX,DestY]) of
                true->

			        BattleAttr = Status#player.battle_attr#battle_attr{x = DestX, y = DestY } ,
		        	NewStatus = Status#player{battle_attr = BattleAttr } ,
		        	case lib_scene:is_dungeon_scene(Status#player.scene) of
			        	false ->
					        mod_scene:update_postion(Status#player.other#player_other.pid_scene,Status,DestX,DestY)  ,
  
							%%MonIdList = mod_scene:get_warn_monsters(Status#player.other#player_other.pid_scene,
							%%						   BattleAttr#battle_attr.x,
							%%						   BattleAttr#battle_attr.y),
                            %%[playerComingInEvent(Status#player.other#player_other.pid_scene,MonId,Status,NowTime) || MonId <- MonIdList],

							mod_scene:trigger_warn_monsters(Status#player.other#player_other.pid_scene,Status,
													   BattleAttr#battle_attr.x,
													   BattleAttr#battle_attr.y);
			        	true ->
							mod_dungeon:update_postion(Status#player.other#player_other.pid_dungeon,Status,DestX,DestY),
							%%MonIdList = mod_dungeon:get_warn_monsters(Status#player.other#player_other.pid_dungeon,
							%%							  BattleAttr#battle_attr.x,
							%%						   BattleAttr#battle_attr.y),
                            %%[playerComingInEvent(Status#player.other#player_other.pid_dungeon,MonId,Status,NowTime) || MonId <- MonIdList],

							mod_dungeon:trigger_warn_monsters(Status#player.other#player_other.pid_dungeon,Status,
													   BattleAttr#battle_attr.x,
													   BattleAttr#battle_attr.y)
                     end,
                     lib_task:checkMove(NewStatus),
                     {ok,change_online,NewStatus};
                 false->
					 %?TRACE("[SCENE_POS_ERR]player position x -> ~p y -> ~p ~n",[DestX,DestY]),
                     ok
			end ;
		false ->
			 %?TRACE("[SCENE_PT_ERR]player position x -> ~p y -> ~p ~n",[DestX,DestY]),
			ok
	end ;

%% 怪物掉落拾取
handle(12016, Status, [DropId]) ->
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		true ->
			[_Code,GoodsList] = mod_dungeon:pick_drop(Status#player.other#player_other.pid_dungeon,DropId) ;
		false ->
			[_Code,GoodsList] = mod_scene:pick_drop(Status#player.other#player_other.pid_scene,DropId) ,
			case length(GoodsList) > 0 of
				true ->
					{ok,BrodBin} = pt_12:write(12023, [DropId]) ,
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BrodBin) ;
				_ ->
					lib_player:send_tips(5002034, [], Status#player.other#player_other.pid_send) 
			end 
	end ,
	case length(GoodsList) > 0 of
		true ->
			NewStatus = case lib_mail:check_bag_enough(Status, GoodsList) of
				true ->
					goods_util:send_goods_and_money(GoodsList, Status, ?LOG_GOODS_MON);
				false ->
					GoodsListMail = lists:foldl(fun({Id,Num},Result) ->
								Result ++ [{0,Id,Num}]
						end,[],GoodsList),
					lib_mail:send_mail_to_one(Status#player.id,1,4,GoodsListMail),
					Status	
			end,
			%%NewStatus = goods_util:send_goods_and_money(GoodsList, Status, ?LOG_GOODS_MON) ,
			{ok,DropBin} = pt_12:write(12016, [1,DropId]) ,
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, DropBin) ,
			lib_player:send_player_attribute3(NewStatus),
			{ok,NewStatus} ;
		_ ->
			{ok,DropBin} = pt_12:write(12016, [0,0]) ,
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, DropBin),
			ok
	end ;


%% 玩家开始采集
handle(12017, Status, [TaskId,NpcId]) ->
	[Code] = 
		case  lib_task:check_collect_task(TaskId,NpcId,Status#player.id) of
			true ->
				case tpl_npc_layout:get(Status#player.scene div 100, NpcId) of
					NpcLayout when is_record(NpcLayout,temp_npc_layout) ->
						DistX = abs(NpcLayout#temp_npc_layout.x - Status#player.battle_attr#battle_attr.x ) ,
						DistY = abs(NpcLayout#temp_npc_layout.y - Status#player.battle_attr#battle_attr.y ) ,
						case DistX > 2 andalso DistY > 2 of
							false ->
								put(player_collect,{TaskId,NpcId,util:unixtime()}) ,
								[1] ;
							true ->
								[4] 
						end ;
					_ ->
						[3] 
				end ;
			false ->
				[2] 
		end ,
	
	pack_and_send(Status, 12017, [Code]) ;

%% 
%% %% 玩家中断采集
handle(12018, Status, []) ->
	erase(player_collect) ,
	pack_and_send(Status, 12018, [1]) ;	

%% 
%% %% 玩家结束采集
handle(12019, Status, [TaskId,NpcId]) ->
	NowTime = util:unixtime() ,
	[Code] = 
		case  get(player_collect) of
			{BTaskId,BNpcId,BTime}  ->
				if
					TaskId =/= BTaskId orelse NpcId =/= BNpcId ->
						[2] ;
					NowTime - BTime < 2 ->
						[3] ;
					true ->
						lib_task:call_event(Status,item,{NpcId,1}) ,
						erase(player_collect) ,
						[1]
				end ;
			_ ->
				[2] 
		end ,
	pack_and_send(Status, 12019, [Code]) ;	


%% 玩家原地复活
handle(12020, Status, []) -> 
	NewStatus = lib_player:revive(Status, here), 
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		true ->
			mod_dungeon:update_dungeon_last_time(Status);
		false ->
			skip
	end,
	%%{ok,NewPS1} = pp_scene:handle(12001, NewStatus, [NewStatus#player.scene, NewStatus#player.battle_attr#battle_attr.x, NewStatus#player.battle_attr#battle_attr.y]),
	lib_battle:pack_and_send(NewStatus, 20007,
							 [?PLAYER_NORMAL_STATE,0]), 
	pack_and_send(Status, 12020, [1,
								  NewStatus#player.scene,
								  NewStatus#player.battle_attr#battle_attr.x,
								  NewStatus#player.battle_attr#battle_attr.y]) ,
	{ok,NewStatus} ;
%%元宝复活功能 暂时不要
%% 			ReviveTimes = case lib_dungeon:get_dungeon_daily(Status#player.id) of
%% 				DDRcd when is_record(DDRcd, ?ETS_DUNGEON_DAILY) ->
%% 					DDRcd#?ETS_DUNGEON_DAILY.revive_times;
%% 				_ ->
%% 					0
%% 			end,
%% 			CostGold = data_config:get_revive_gold(ReviveTimes),
%% 			case lib_money:has_enough_money(Status,CostGold,?MONEY_T_GOLD) of 
%% 				true ->
%% 					case lib_dungeon:get_dungeon_daily(Status#player.id) of
%% 						DDRcd2 when is_record(DDRcd2, ?ETS_DUNGEON_DAILY) ->
%% 							Times = DDRcd2#?ETS_DUNGEON_DAILY.revive_times,
%% 							NewDDRcd = DDRcd2#?ETS_DUNGEON_DAILY{revive_times = Times+1},
%% 							lib_dungeon:save_dungeon_daily(NewDDRcd);
%% 						_ ->
%% 							skip
%% 					end,
%% 					lib_money:cost_money(Status,CostGold,?MONEY_T_GOLD,?DUNGEON_REBORN),
%% 					NewStatus = lib_player:revive(Status, here),
%% 					pack_and_send(Status, 12020, [1]) ,
%% 					{ok,NewStatus} ;
%% 				false ->
%% 					lib_player:send_tips(1302003, [], Status#player.other#player_other.pid_send) ,
%% 					pack_and_send(Status, 12020, [0]) 
%% 			end

%% 玩家重生点复活
handle(12021, Status, [_SceneId]) ->
	NewStatus = lib_player:revive(Status, city),  %#player{hit_point = round(Status#player.hit_point_max * 0.2) } ,
	%% 1.0 更新副本最后活动时间
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		true ->
			mod_dungeon:update_dungeon_last_time(Status);
		false ->
			skip
	end,
	%% 2.0 获取复活场景
	case lib_scene:get_scene_tmpl(NewStatus#player.scene) of
		Scene when is_record(Scene,temp_scene) ->
			case Scene#temp_scene.revive_sid > 0 of
				true ->
					case lib_scene:is_dungeon_scene(NewStatus#player.scene) 
						andalso (NewStatus#player.scene div 100) =/= Scene#temp_scene.revive_sid of
						true ->
							mod_dungeon:leave_dungeon(NewStatus#player.other#player_other.pid_dungeon,NewStatus);
						false ->
							skip
					end,
					lib_battle:pack_and_send(NewStatus, 20007,
											 [?PLAYER_NORMAL_STATE,0]), 
					pack_and_send(NewStatus, 12021, [1,Scene#temp_scene.revive_sid,Scene#temp_scene.revive_x,Scene#temp_scene.revive_y]) ,
					{ok,NewStatus} ;
				false ->
					lib_battle:pack_and_send(NewStatus, 20007,
											 [?PLAYER_NORMAL_STATE,0]), 
					pack_and_send(Status, 12021, [2,Scene#temp_scene.revive_sid,Scene#temp_scene.revive_x,Scene#temp_scene.revive_y]) 
			end ;
		_ ->
			pack_and_send(Status, 12021, [0,0,0,0]) 
	end  ;

%% 剧情结束
handle(12031, Status, []) ->
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		true ->
			mod_dungeon:dungeon_dialogue_finish(Status);
		false ->
			skip
	end,
	ok;

handle(12040,Status,[SceneGiftId]) ->
	lib_scene_gift:reward_scene_gift(Status#player.id,Status#player.other#player_other.pid_send,SceneGiftId),
	ok;

handle(_Cmd, _Status, _Data) ->
	%%     ?DEBUG("pp_scene no match", []),
	{error, "pp_scene no match"}.


pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_12:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).


playerComingInEvent(Pid,MonRcdId,PlayerStatus,NowTime) ->
    MonRcd = gen_server:call(Pid, {'get_monrcd',MonRcdId}),
    if
        %%一定要保证MonRcd非空，否则下面的代码无法继续运行而导致位置不同步
        is_record(MonRcd,temp_mon_layout) andalso PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->
            MonRcd#temp_mon_layout.pid ! {'player_coming',MonRcd,Pid,PlayerStatus};
        true ->
            skip
    end.
