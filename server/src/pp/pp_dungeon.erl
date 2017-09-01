%% Author: Administrator
%% Created: 2011-10-14
%% Description: TODO: Add description to pp_dungeon
-module(pp_dungeon).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
%%
%% Exported Functions
%%
-compile([export_all]).

%% -----------------------------------------------------------------
%% 玩家进入副本
%% %% -----------------------------------------------------------------
handle(23001, Status, [TaskId,DunId]) ->
%% 	case lib_task:check_dungeon_task(TaskId,DunId,Status#player.id) of
%% 		true ->  
			FDunRcd = lib_dungeon:get_dungeon_finish(Status#player.id) ,
			case lists:member(DunId, FDunRcd#?ETS_DUNGEON_FINISH.dlv) of
				_ ->
					case lib_scene:get_scene_tmpl(DunId) of  
						ScnTplRcd when is_record(ScnTplRcd,temp_scene) ->
							if
								Status#player.level < ScnTplRcd#temp_scene.min_level orelse Status#player.level > ScnTplRcd#temp_scene.max_level ->
									lib_player:send_tips(2002002, [], Status#player.other#player_other.pid_send) ,
									pack_and_send(Status, 23001, [0,0]) ;
								true ->
									io:format("=====handle(23001:~p ~p~n", [Status#player.battle_attr#battle_attr.x,
																   Status#player.battle_attr#battle_attr.y]) ,
									[Code,LeftTime] = mod_dungeon:enter_dungeon(Status#player.other#player_other.pid_dungeon,
																	Status,
																   task,
																   DunId,
																   Status#player.scene,
																   Status#player.battle_attr#battle_attr.x,
																   Status#player.battle_attr#battle_attr.y,
																   Status#player.other#player_other.pid_send) ,
									pack_and_send(Status, 23001, [Code,LeftTime,DunId,ScnTplRcd#temp_scene.x,ScnTplRcd#temp_scene.y]),  
									lib_battle:do_scene_battle_expired(Status)
									%%{ok,NewStatus#player{status = ?PLAYER_NORMAL_STATE}}
							end ;
						_ ->
							lib_player:send_tips(2002002, [], Status#player.other#player_other.pid_send) ,
							pack_and_send(Status, 23001, [0,0,0,0,0]) 
					end ;
				true -> 
					%% 剧情副本已经打过
					lib_player:send_tips(2001003, [], Status#player.other#player_other.pid_send) ,
					pack_and_send(Status, 23001, [0,0,0,0,0])  
			end ;
%% 		false ->
%% 			%% 没有相关任务
%% 			lib_player:send_tips(2002010, [], Status#player.other#player_other.pid_send) ,
%% 			pack_and_send(Status, 23001, [0,0]) 
%% 	end ;
			
	

%% -----------------------------------------------------------------
%% 玩家使用触发器
%% -----------------------------------------------------------------
handle(23003, Status, [Action]) ->
	DunRcd = lib_dungeon:get_dungeon_daily(Status#player.id) ,
	?ASSERT(is_record(DunRcd,dungeon_daily)) ,
	case data_dungeon:get_trigger_tmpl(DunRcd#dungeon_daily.sid, Action) of
		TriggerRcd when is_record(TriggerRcd,temp_dungeon_trigger) ->
			[Code] = 
				case lists:member(Action, DunRcd#dungeon_daily.triggers) of
					true ->  
 						mod_dungeon:perform_trigger(Status#player.other#player_other.pid_dungeon,
															TriggerRcd,
															Status#player.scene,
															Status#player.other#player_other.pid_send) ,
								[1] ;
					false ->
						[4]
				end ,
			pack_and_send(Status, 23003, [Code]) ;
		_->
			?TRACE("[pp_dungeon] 23003 Action not match"),
			skip
	end;

%% -----------------------------------------------------------------
%% 查询副本组的情况
%% -----------------------------------------------------------------
handle(23011, Status, [DGId]) ->
	[LeftTimes,Total,DunStates] = lib_dungeon:get_dungeon_state(DGId,Status#player.id) ,
	Num = length(DunStates),
	pack_and_send(Status, 23011, [LeftTimes,length(DunStates),DunStates]) ;
	

%% -----------------------------------------------------------------
%% 玩家进入副本组
%% -----------------------------------------------------------------	
handle(23012, Status, [DunGrpId,DunId]) ->
	DunTplRcd = tpl_dungeon:get(DunId) ,
	DunGrpTplRcd = tpl_dungeon_group:get(DunGrpId) ,
	case is_record(DunTplRcd, temp_dungeon) andalso 
			 is_record(DunGrpTplRcd, temp_dungeon_group) andalso
			 DunTplRcd#temp_dungeon.grp =:= DunGrpId of
		true ->
			%%TotalTimes = data_dungeon:get_dungeon_times() ,
			TotalTimes = DunGrpTplRcd#temp_dungeon_group.times,
			UsedTimes = lib_dungeon:get_used_times(Status#player.id) ,
			case UsedTimes =<  TotalTimes of
				true ->
					case lib_scene:get_scene_tmpl(DunId) of
						ScnTplRcd when is_record(ScnTplRcd,temp_scene) ->
							CanDungeon = lib_dungeon:check_pre_dungeon(DunGrpId,DunId,Status#player.id),
							if
								Status#player.level < ScnTplRcd#temp_scene.min_level orelse Status#player.level > ScnTplRcd#temp_scene.max_level ->
									lib_player:send_tips(2001002, [], Status#player.other#player_other.pid_send) ,
									pack_and_send(Status, 23001, [0,0]) ;
								not CanDungeon ->%%前置副本是否打过
									lib_player:send_tips(2002002, [], Status#player.other#player_other.pid_send) ,
									pack_and_send(Status, 23001, [0,0]) ;								
								true ->
									[Code,LeftTime] = mod_dungeon:enter_dungeon(Status#player.other#player_other.pid_dungeon,
																Status,
															  trail,
															  DunId,
															  Status#player.scene,
															  Status#player.battle_attr#battle_attr.x,
															  Status#player.battle_attr#battle_attr.y,
															  Status#player.other#player_other.pid_send) ,
 									pack_and_send(Status, 23012, [Code,LeftTime,DunId,ScnTplRcd#temp_scene.x,ScnTplRcd#temp_scene.y])
 									%%pack_and_send(Status, 23001, [Code,LeftTime,DunId,ScnTplRcd#temp_scene.x,ScnTplRcd#temp_scene.y])
									%%{ok,NewStatus}
							end
					end ;
				false  ->
					lib_player:send_tips(2001003, [], Status#player.other#player_other.pid_send) ,
%% 					pack_and_send(Status, 23012, [0,0,0,0,0]) 
					pack_and_send(Status, 23001, [0,0,0,0,0]) 
			end ;
		false ->
			lib_player:send_tips(2002002, [], Status#player.other#player_other.pid_send) ,
%% 			pack_and_send(Status, 23012, [0,0,0,0,0]) 
			pack_and_send(Status, 23001, [0,0,0,0,0]) 
	end ;
	
		
%%查询副本霸主
handle(23014, Status, [DunId]) ->
	NickName = case ets:lookup(?ETS_DUNGEON_MASTER, DunId) of
		[MDRcd | _] ->
			MDRcd#?ETS_DUNGEON_MASTER.nick;
		_ ->
			"暂无霸主"
	end,
	pack_and_send(Status, 23014, [NickName]);

handle(23030, Status, []) ->
	mod_dungeon:pass_progress(Status#player.other#player_other.pid_dungeon,Status#player.other#player_other.pid_send) ;
							  

%%客户端请求副本结束
handle(23033, Status, []) ->
	case lib_dungeon:get_dungeon_daily(Status#player.id) of
%% 		DunRcd when is_record(DunRcd,dungeon_daily) andalso DunRcd#dungeon_daily.sid > 0 ->
%% 			mod_dungeon:finish_dungeon(Status#player.other#player_other.pid_dungeon,Status#player.other#player_other.pid_send) ,
%% 			{ok,Status#player{status = ?PLAYER_NORMAL_STATE}};
		_ ->
			skip
	end ;


%% 玩家领取副本奖励（有漏洞么）			
handle(23035, Status, [GoodsIndex]) ->
	case lib_dungeon:get_dungeon_daily(Status#player.id) of
		DunRcd when is_record(DunRcd,dungeon_daily) ->
%% 			case  lists:keyfind(GoodsTypeId, 1, DunRcd#?ETS_DUNGEON_DAILY.rewards) of
 			case  0 =< GoodsIndex andalso GoodsIndex < length(DunRcd#?ETS_DUNGEON_DAILY.rewards) of
				true ->
					case lists:nth(GoodsIndex+1,DunRcd#?ETS_DUNGEON_DAILY.rewards) of
						{GoodsTypeId,GoodsNumber} ->
							NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{rewards=[]},
							lib_dungeon:save_dungeon_daily(NewDunRcd),
							case goods_util:can_put_into_bag(Status,[{GoodsTypeId,GoodsNumber}]) of 
								true ->
									NewStatus = goods_util:send_goods_and_money([{GoodsTypeId,GoodsNumber}], Status, ?LOG_GOODS_MON) ,
									pack_and_send(Status, 23035, [1,GoodsTypeId,GoodsNumber]) ,
									spawn(fun() -> lib_dungeon:update_log(Status#player.id, 
														  DunRcd#?ETS_DUNGEON_DAILY.begin_time, 
														  [{GoodsTypeId,GoodsNumber}]) end ) ,
									{ok,NewStatus} ;
								false ->
						  			lib_mail:send_mail_to_one(Status#player.id,0,1,[{0,GoodsTypeId,GoodsNumber}]),
									pack_and_send(Status, 23035, [0,0,0])
							end;
						_ ->
							pack_and_send(Status, 23035, [2,0,0]) 
					end;
				false ->
					pack_and_send(Status, 23035, [2,0,0]) 
			end;
		_ ->
			skip
	end;

%%副本物件事件
handle(23041,Status,[DunObjId,ObjState,Type]) ->
	case lists:member(Type,[?CONDITION_NULL,?CONDITION_END]) of
		true ->
			case tpl_dungeon_obj:get(Status#player.scene div 100,DunObjId,1) of
				Obj when is_record(Obj,temp_dungeon_obj) ->
					io:format("23041::trigger_dungeon_object~p~p~n",[DunObjId,ObjState]),
					mod_dungeon:trigger_dungeon_object(Status,DunObjId,Type,ObjState);
				_ ->
					io:format("23041::trigger_call_back~n"),
					mod_dungeon:trigger_call_back(Status,Type)
			end;
		false ->
			skip
	end;

%% 退出副本
handle(23099, Status, []) ->
	case lib_dungeon:get_dungeon_daily(Status#player.id) of
		DunRcd when is_record(DunRcd,dungeon_daily) andalso DunRcd#dungeon_daily.sid > 0 ->
			mod_dungeon:leave_dungeon(Status#player.other#player_other.pid_dungeon,Status) ,   
			%%case DunRcd#dungeon_daily.pass_assess > 0 andalso DunRcd#dungeon_daily.times =< 0 of
			case DunRcd#dungeon_daily.pass_assess > 0 of
				true ->
					DunStatus = 2,
					lib_task:call_event(Status,dungeon,{DunRcd#dungeon_daily.sid}) ;
				false ->
					DunStatus = 1,
					skip
			end ,			
			DungeonLv = 1,
			spawn(fun() -> db_agent_log:insert_log_dungeon(DunRcd#dungeon_daily.sid,Status#player.id,Status#player.account_name,Status#player.level,DungeonLv,DunStatus) end ),
			%%离开副本满血满蓝  
			NewStatus = lib_player:full_hp_magic(Status),
			NewStatus3 = case pp_scene:handle(12001, NewStatus#player{status = ?PLAYER_NORMAL_STATE}, 
											  [DunRcd#dungeon_daily.pre_sid,
											   DunRcd#dungeon_daily.pre_sx,
											   DunRcd#dungeon_daily.pre_sy]) of
							 {ok,NewStatus2} ->  
							  	NewPs = lib_energy:reflesh_energy(NewStatus2),
								{ok, BinData} =  pt_20:write(20007,
											[?PLAYER_NORMAL_STATE,NewPs#player.battle_attr#battle_attr.energy#energy.energy_val]),
								 lib_send:send_to_sid(NewPs#player.other#player_other.pid_send, BinData),
 					 			 NewPs;
							 _ -> 
								 NewStatus
						 end,
			{ok,NewStatus3};
		_ ->
			skip
	end;

%% 剧情结束
handle(23005, Status, []) ->
	%%mod_dungeon:dungeon_dialogue_finish(Status),
	ok;

%% 获取到玩家的日常副本信息并发送到前端
handle(23043, Status, []) ->
    RetInfo = lib_dungeon:get_daily_dungeon_info(Status#player.id),
    {ok, BinData} = pt_23:write(23043,[RetInfo]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send,BinData);

handle(_Arg0, _Arg1, _Arg2) -> 
	ok.
%% 
%% 
%% %%
%% %% Local Functions
%% %%
%% 
pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_23:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).


