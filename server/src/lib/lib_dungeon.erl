%% Author: kexp
%% Created: 2011-10-14
%% Description: TODO: Add description to lib_dungeon
-module(lib_dungeon).


-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-define(PASS_TYPE_1,1) .
-define(PASS_TYPE_2,2) .

-export([get_dungeon_daily/1 ,
		 get_dungeon_finish/1,
		 get_dungeon_state/2,
		 on_player_logon/1 ,
		 on_player_logoff/1 ,
		 perform_trigger/3 ,
		 enter_dungeon/7 ,
		 get_player/0 ,
		 add_kill_monster/2 ,
		 reset_dungeon/0,
		 check_reconn_dungeon/1,
		 get_revive_scene/1,
		 save_dungeon_daily/1,
		 save_dungeon_finish/1,
		 clear_dungeon_times/0,
		 finish_dungeon/1,
		 leave_dungeon/1,
		 update_log/3,
		 get_monsters/0,
		 get_used_times/1,
		 load_master/0,
		 refresh_master/0,
		 set_master/3,
		 pass_progress/1,
		 test/1,
		 use_item_cb/0,
		 init_dungeon_monsters/1,
		 check_pre_dungeon/3,
		 info_dungeon_rewards/1,
		 save_master/0,
		 dungeon_dialogue_finish/1,
         eraseMonProcess/0,
		 update_dungeon_last_time/1,
         get_daily_dungeon_info/1,
		 send_finish_data/2,
		 enter_scene_ok/1
		]).  
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%====以下玩家进程调用 begin ======%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%加载霸主数据
load_master() ->
	DataList =  db_agent_dungeon:select_master() ,
	Fun = fun(MDRcd) ->
            ets:insert(?ETS_DUNGEON_MASTER, MDRcd)
    end ,
	lists:foreach(Fun, DataList) .
	
%%加载霸主数据
refresh_master() ->
	db_agent_dungeon:delete_master() ,
	Fun = fun(MDRcd) ->
				  case tpl_dungeon:get(MDRcd#?ETS_DUNGEON_MASTER.sid) of
					  DunTplRcd when is_record(DunTplRcd,temp_dungeon) andalso MDRcd#?ETS_DUNGEON_MASTER.muid > 0 ->
						  RewardList = DunTplRcd#temp_dungeon.king_rewards ,
						  MainCont = data_dungeon:get_master_content(DunTplRcd#temp_dungeon.name) ,
						  lib_mail:send_mail_to_one(MDRcd#?ETS_DUNGEON_MASTER.muid,0,MainCont,RewardList) ;
					  _ ->
						  skip
				  end ,
				  
				  NewMDRcd = MDRcd#?ETS_DUNGEON_MASTER{muid = 0, score = 0 , update_time = 0,nick=""} ,
				  db_agent_dungeon:insert_master(NewMDRcd) ,
				  ets:insert(?ETS_DUNGEON_MASTER, NewMDRcd)
		  end ,
	lists:foreach(Fun, ets:tab2list(?ETS_DUNGEON_MASTER)) .

%%保存霸主数据
save_master() ->
%% 	db_agent_dungeon:delete_master() ,
	Fun = fun(MDRcd) ->
			DBMDRcd = db_agent_dungeon:select_master(MDRcd#?ETS_DUNGEON_MASTER.sid),
			if 
				MDRcd =/= DBMDRcd ->
					db_agent_dungeon:update_master(MDRcd);
				true ->
					skip
			end
		  end ,
	lists:foreach(Fun, ets:tab2list(?ETS_DUNGEON_MASTER)) .

%%重置霸主数据
set_master(SId,UId,Score) ->
	case ets:lookup(?ETS_DUNGEON_MASTER, SId) of
		[MDRcd | _] ->
			update_master_ets(MDRcd,Score,SId,UId);
		_ ->
			MDRcd = #?ETS_DUNGEON_MASTER{sid = SId,muid = 0, score = 0, update_time = 0,nick = ""} ,
			ets:insert(?ETS_DUNGEON_MASTER, MDRcd),
			update_master_ets(MDRcd,Score,SId,UId)
	end,
	save_master().

update_master_ets(MDRcd,Score,SId,UId) ->
	case MDRcd#?ETS_DUNGEON_MASTER.score < Score of
		true ->
			%%清除低等级的霸主
			Fun = fun(M) ->
				if 
					M#?ETS_DUNGEON_MASTER.muid =:= UId andalso M#?ETS_DUNGEON_MASTER.sid =< SId ->
						ets:update_element(?ETS_DUNGEON_MASTER, 
							   M#?ETS_DUNGEON_MASTER.sid, 
							   [{#?ETS_DUNGEON_MASTER.muid,0},
								{#?ETS_DUNGEON_MASTER.score,0},
								{#?ETS_DUNGEON_MASTER.update_time,0},
								{#?ETS_DUNGEON_MASTER.nick,""}]);
					true -> 
						skip
				end
		  	end ,
			lists:foreach(Fun, ets:tab2list(?ETS_DUNGEON_MASTER)),

			NeedUpdate = lists:all(fun(M) ->
							M#?ETS_DUNGEON_MASTER.muid =/= UId
						end, ets:tab2list(?ETS_DUNGEON_MASTER)),
			case  NeedUpdate of
				true ->
					NowTime = util:unixtime() ,
					NickName = case lib_player:get_player(UId) of
					Player when is_record(Player, player) ->
						Player#player.nick;
					_ ->
						"OffLine"
					end,
					ets:update_element(?ETS_DUNGEON_MASTER, 
							   SId, 
							   [{#?ETS_DUNGEON_MASTER.muid,UId},
								{#?ETS_DUNGEON_MASTER.score,Score},
								{#?ETS_DUNGEON_MASTER.update_time,NowTime},
								{#?ETS_DUNGEON_MASTER.nick,NickName}]);
				false ->
					skip
			end;
		false ->
			skip
	end.

clear_dungeon_times() ->
	DunRcd = get_dungeon_daily(get(uid)) ,
	NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{times = 0} ,
	save_dungeon_daily(NewDunRcd) .

%% 在进入场景之前判断一下，免得重复
%% 判断是否需要进入副本
check_reconn_dungeon(PlayerStatus) ->
	NowTime = util:unixtime() ,
	ReconnTime = data_dungeon:get_recon_time() ,
	DunRcd = get_dungeon_daily(PlayerStatus#player.id) ,
	TimePassed = NowTime - DunRcd#?ETS_DUNGEON_DAILY.last_time ,
	EndTime = DunRcd#?ETS_DUNGEON_DAILY.begin_time + data_dungeon:get_duration(DunRcd#?ETS_DUNGEON_DAILY.sid) ,
	case DunRcd#?ETS_DUNGEON_DAILY.sid > 0  of
		true ->
			 %%case TimePassed > ReconnTime orelse NowTime > EndTime of
			 case NowTime > EndTime of
				 true ->
					 mod_dungeon:leave_dungeon(PlayerStatus#player.other#player_other.pid_dungeon,PlayerStatus) ,
%% 					 put(dungeon_reward,{DunRcd#?ETS_DUNGEON_DAILY.begin_time,DunRcd#?ETS_DUNGEON_DAILY.rewards}) ,
%% 					 {ok,RewarBin} = pt_23:write(23034, [DunRcd#?ETS_DUNGEON_DAILY.rewards]) , 
%% 					 lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, RewarBin) ,
					 {fail_timeout,DunRcd#?ETS_DUNGEON_DAILY.pre_sid, DunRcd#?ETS_DUNGEON_DAILY.pre_sx, DunRcd#?ETS_DUNGEON_DAILY.pre_sy} ;
				 false ->
					 DunID = lib_scene:get_base_scene(PlayerStatus#player.scene) ,
					 PosX = PlayerStatus#player.battle_attr#battle_attr.x ,
					 PosY = PlayerStatus#player.battle_attr#battle_attr.y ,
					 [Code,LeftTime] = mod_dungeon:enter_dungeon(PlayerStatus#player.other#player_other.pid_dungeon,
						 						PlayerStatus,
											   reconn ,
											   DunRcd#?ETS_DUNGEON_DAILY.sid,
											   DunID ,
											   PosX ,
											   PosY ,
											   PlayerStatus#player.other#player_other.pid_send) ,
					 ScnTplRcd = lib_scene:get_scene_tmpl(DunID),
					 {ok, BinData} = pt_23:write(23001, [Code,LeftTime,DunID,PosX,PosY]),
    				 lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData),
					 {succ,DunRcd#?ETS_DUNGEON_DAILY.pre_sid, DunRcd#?ETS_DUNGEON_DAILY.pre_sx, DunRcd#?ETS_DUNGEON_DAILY.pre_sy}
			 end ;
		false ->
			{fail,0,0,0}
	end .
		





%% 从ETS里面获取
get_dungeon_daily(UId) ->
	case ets:lookup(?ETS_DUNGEON_DAILY, UId) of
		[] ->
			[] ;
		[DunRcd|_] ->
			DunRcd
	end .
get_dungeon_finish(UId) ->
	case ets:lookup(?ETS_DUNGEON_FINISH, UId) of
		[] ->
			[] ;
		[DunRcd|_] ->
			DunRcd
	end .


%% 获取副本组的情况
get_dungeon_state(DunGrpId,UId) ->
	GrpDunList = tpl_dungeon:get_by_grp(DunGrpId) ,
	DunGrp = tpl_dungeon_group:get(DunGrpId),
	GrpDunIds = lists:map(fun(T) -> 
					  T#temp_dungeon.sid
			  end, GrpDunList),
	DFRcd = get_dungeon_finish(UId) ,
	{PassNum,DunState} = check_dungeon_state(lists:sort(GrpDunIds),[],0,DFRcd#?ETS_DUNGEON_FINISH.dlv) ,
	DDRcd = get_dungeon_daily(UId) ,
	case util:is_same_date(DDRcd#?ETS_DUNGEON_DAILY.last_time,util:unixtime()) of
		true ->
			%%LeftTime = max(0,data_dungeon:get_dungeon_times() - DDRcd#?ETS_DUNGEON_DAILY.times) ;
			LeftTime = max(0,DunGrp#temp_dungeon_group.times - DDRcd#?ETS_DUNGEON_DAILY.times) ;
		false ->
			%%LeftTime = data_dungeon:get_dungeon_times() 
			LeftTime = DunGrp#temp_dungeon_group.times
	end ,
	[LeftTime,PassNum,DunState] .
	
	
check_dungeon_state([],DunState,PassNum,_PassedList) ->
	{PassNum,DunState} ;
check_dungeon_state([DunId|LeftDunList],DunState,PassNum,PassedList) ->
	case lists:member(DunId, PassedList) of
		true ->
			NewDunState = [{DunId,1} | DunState] ,
			check_dungeon_state(LeftDunList,NewDunState,PassNum+1,PassedList) ;
		false ->
			NewDunState = [{DunId,2} | DunState] ,
			check_dungeon_state(LeftDunList,NewDunState,PassNum,PassedList)
%% 			{PassNum,NewDunState} 
	end .
											   


test(List) ->
	Fun = fun({_,KilledNum,MaxNum},Flag) ->
				  case Flag of
					  true ->
						  KilledNum >= MaxNum ;
					  false ->
						  false 
				  end 
		  end ,
	Passed = lists:foldl(Fun, true, List) ,
	Passed .


get_revive_scene(UId) ->
	case get_dungeon_daily(UId) of
		DunRcd when is_record(DunRcd,dungeon_daily) ->
			case data_dungeon:get_dungeon(DunRcd#?ETS_DUNGEON_DAILY.sid) of
				DunTpl when is_record(DunTpl,temp_dungeon) ->
					lib_scene:get_scene_tmpl(DunTpl#temp_dungeon.sid);
				_ ->
					[]
			end ;
		_ ->
			[]
	end .

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%====以上玩家进程调用  end ======%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%====以下副本进程调用 begin ======%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 重置玩家的副本信息
reset_dungeon(DunRcd) ->
	NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{sid = 0, 
							   triggers = [] ,
							   pass_assess = 0 ,
							   pass_type = 0 , 
							   pass_value = [] ,
							   monsters = [] ,
							   dungeon_score = [0,0,0],
							   obj_state = []
							   } ,
	save_dungeon_daily(NewDunRcd) ,
	NewDunRcd .
reset_dungeon() ->
	reset_dungeon(get_dungeon_daily(get(uid))) .

%% 保存玩家副本数据
save_dungeon_daily(DDRcd) ->
	ets:insert(?ETS_DUNGEON_DAILY, DDRcd) .
save_dungeon_finish(DFRcd) ->
	ets:insert(?ETS_DUNGEON_FINISH, DFRcd) .

%% 玩家登陆时加载副本信息
on_player_logon(UId) ->
	DDunRcd =
		case get_dungeon_daily(UId) of
			DDRcd when is_record(DDRcd,?ETS_DUNGEON_DAILY) ->
				DDRcd ;
			_ ->
				db_agent_dungeon:select_daily(UId) 
		end ,
	
	NowTime = util:unixtime() ,
	case util:is_same_date(DDunRcd#?ETS_DUNGEON_DAILY.last_time, NowTime) of
		true ->
%% 			ets:insert(?ETS_DUNGEON_DAILY, DDunRcd#?ETS_DUNGEON_DAILY{last_time = NowTime}) ;
			ets:insert(?ETS_DUNGEON_DAILY, DDunRcd);
		false ->
			%%ets:insert(?ETS_DUNGEON_DAILY, DDunRcd#?ETS_DUNGEON_DAILY{last_time = NowTime, times = 0})
			ets:insert(?ETS_DUNGEON_DAILY, DDunRcd#?ETS_DUNGEON_DAILY{times = 0})
	end ,
	
	FDunRcd = 
		case get_dungeon_finish(UId) of
			DFRcd when is_record(DFRcd,?ETS_DUNGEON_FINISH) ->
				DFRcd ;
			_ ->
				db_agent_dungeon:select_finish(UId) 
		end ,
	ets:insert(?ETS_DUNGEON_FINISH, FDunRcd) .
		  
%% 玩家下线时处理
on_player_logoff(UId) ->
	misc:cancel_timer(dungeon_timer) ,
	case get_dungeon_daily(UId) of
		DDRcd when is_record(DDRcd,dungeon_daily) ->
			ets:delete(?ETS_DUNGEON_DAILY, UId) ,
			NewDDRcd = DDRcd#?ETS_DUNGEON_DAILY{last_time = util:unixtime()},
			db_agent_dungeon:update_daily(NewDDRcd) ;
		_ ->
			skip
	end ,
	case get_dungeon_finish(UId) of
		DFRcd when is_record(DFRcd,dungeon_finish) ->
			ets:delete(?ETS_DUNGEON_FINISH, UId) ,
			db_agent_dungeon:update_dungeon(DFRcd) ;
		_ ->
			skip
	end .


%% 获取副本玩家信息
get_player() ->
	case ets:lookup(?ETS_ONLINE, get(uid)) of
		[Player|_] ->
			Player ;
		_ ->
			[]
	end .

%% 玩家进入副本
enter_dungeon(Status,Type,DunId,SceneId,PosX,PosY,PidSend) ->
	NowTime = util:unixtime() ,
	DunRcd = get_dungeon_daily(get(uid)) ,
	DunTpl = data_dungeon:get_dungeon(DunId) ,  
	?ASSERT(is_record(DunTpl, temp_dungeon)),  
	Duration = data_dungeon:get_duration(DunId) ,
	case DunRcd#?ETS_DUNGEON_DAILY.sid > 0 andalso 
		 DunRcd#?ETS_DUNGEON_DAILY.sid =:= DunId andalso 
		 NowTime - DunRcd#?ETS_DUNGEON_DAILY.begin_time < Duration of
		true ->			%% 断线重新进入
			NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{sid = DunId, last_time = NowTime } ;
		false ->
			UsedTimes = add_used_times(Type,DunRcd) ,
			Trigger = get_triggers(DunId) ,
			Rewards = get_dungeon_rewards(Type,DunTpl),
			PassValue = init_pass_value(DunTpl#temp_dungeon.pass_type,DunTpl#temp_dungeon.pass_cond) ,
			NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{sid = DunId,
												  times = UsedTimes ,
												  triggers = Trigger ,
												  begin_time = NowTime ,
												  last_time = NowTime ,		%% 最后运动时间
												  pre_sid = SceneId ,
												  pre_sx = PosX ,
												  pre_sy = PosY,
												  pre_attr = [Status#player.level],
												  pass_type = DunTpl#temp_dungeon.pass_type ,
												  pass_value = PassValue ,
												  %%rewards = DunTpl#temp_dungeon.rewards,
												  rewards = Rewards,
												  monsters = [],
												  dungeon_score = [0,0,0],%%可配置初始评分{时间评分 ,道具使用,杀怪个数}
												  obj_state = []
												  } 
	end ,
	save_dungeon_daily(NewDunRcd) ,
	
	TimeLeft = max(0,NewDunRcd#?ETS_DUNGEON_DAILY.begin_time + Duration - NowTime) ,
	misc:cancel_timer(dungeon_timer) ,
	FinishTimer = erlang:send_after(TimeLeft * 1000, self(), {'finish_dungeon', PidSend}) ,
	put(dungeon_timer,FinishTimer) ,
	put(finish_time,util:unixtime()+TimeLeft),

	lib_dungeon_exp:enter_dungeon(Status,DunId),
	lib_dungeon_exp:trigger_call_back(Status,?CONDITION_END),
	[1,TimeLeft] .

pass_progress(PidSend) ->
	DunRcd = get_dungeon_daily(get(uid)) ,
	case DunRcd#?ETS_DUNGEON_DAILY.sid > 0 of
		true ->
			DunTpl = data_dungeon:get_dungeon(DunRcd#?ETS_DUNGEON_DAILY.sid) , 
			DialogId =  DunTpl#temp_dungeon.begin_dialog,
			if 
				DialogId =/= 0 ->
					 case lib_opera:notify_opera_dialogue(DunRcd#dungeon_daily.uid,PidSend,DialogId) of
						 true ->
					 		%%副本时间暂停
							misc:cancel_timer(dungeon_timer),
					 		NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{last_time = util:unixtime()},
					 		save_dungeon_daily(NewDunRcd);
						 false ->
							 skip
					 end;
				true ->
		 			 skip
			end,
			send_pass_data(PidSend, DunRcd#?ETS_DUNGEON_DAILY.pass_type, DunRcd#?ETS_DUNGEON_DAILY.pass_value) ;
		false ->
			skip
	end .

%%副本通关情况
send_pass_data(PidSend,PassType,PassValue) ->
	case PassType of
		?PASS_TYPE_1 ->
			{ok,PassBin} = pt_23:write(23031, PassValue) ;
		?PASS_TYPE_2 ->
			{ok,PassBin} = pt_23:write(23032, PassValue) ;
		_ ->
			PassBin = <<>>
	end ,
	case byte_size(PassBin) > 0 of
		true ->
			lib_send:send_to_sid(PidSend,PassBin) ;
		false ->
			skip
	end .


get_used_times(UId) when is_integer(UId) ->
	DDRcd = get_dungeon_daily(UId) ,
	NowTime = util:unixtime() ,
	case util:is_same_date(DDRcd#?ETS_DUNGEON_DAILY.last_time,NowTime) of
		true ->
			DDRcd#?ETS_DUNGEON_DAILY.times ;
		false ->
			0
	end .

add_used_times(Type,DDRcd)  ->
	NowTime = util:unixtime() ,
	case util:is_same_date(DDRcd#?ETS_DUNGEON_DAILY.last_time,NowTime) of
		true ->
			case Type of
				trail ->
					DDRcd#?ETS_DUNGEON_DAILY.times + 1;
				_ ->
					DDRcd#?ETS_DUNGEON_DAILY.times
			end ;
		false ->
			case Type of
				trail ->
					1 ;
				_ ->
					0
			end 
	end .
					
get_dungeon_rewards(Type,DunTpl) ->
	case Type of
		task ->
			[];
		_ ->
			DunTpl#temp_dungeon.rewards
	end.
	

get_triggers(DunId) ->
	TriggerList = tpl_dungeon_trigger:get_by_sid(DunId) ,
	lists:map(fun(T) -> 
					  T#temp_dungeon_trigger.action
			  end, TriggerList) .
init_pass_value(PassType,PassCond) ->
	case PassType of
		?PASS_TYPE_1 ->
			lists:map(fun({MonId,MaxNum}) ->
							  {MonId,0,MaxNum}
					  end , PassCond) ;
		?PASS_TYPE_2 ->
			[0|PassCond] ;
		_ ->
			[]
	end .

%%增加杀怪数量
add_kill_monster(PidSend,MonTplId) ->
	DunRcd = get_dungeon_daily(get(uid)) ,
	DunTpl = data_dungeon:get_dungeon(DunRcd#?ETS_DUNGEON_DAILY.sid) ,

	case DunRcd#?ETS_DUNGEON_DAILY.pass_type of
		?PASS_TYPE_1 ->
			case lists:keyfind(MonTplId, 1, DunRcd#?ETS_DUNGEON_DAILY.pass_value) of
				{_Id,KillNum,MaxNum} ->
					NeedRefresh = true ,
					NewPassValue = lists:keyreplace(MonTplId, 1, DunRcd#?ETS_DUNGEON_DAILY.pass_value, {MonTplId,KillNum+1,MaxNum}) ;
				_ ->
					NeedRefresh = false ,
					NewPassValue = DunRcd#?ETS_DUNGEON_DAILY.pass_value 
			end ,
			Fun = fun({_,KilledNum,MaxNum},Flag) ->
						  case Flag of
							  true ->
								  KilledNum >= MaxNum ;
							  false ->
								  false 
						  end 
				  end ,
			Passed = lists:foldl(Fun, true, NewPassValue);
		?PASS_TYPE_2 ->
			NeedRefresh = true ,
			[KilledNum,MaxNum] = DunRcd#?ETS_DUNGEON_DAILY.pass_value ,
			NewPassValue = [KilledNum+1,MaxNum] ,
			Passed = KilledNum+1 >= MaxNum ;
		_ ->
			NeedRefresh = false ,
			Passed = true ,
			NewPassValue = DunRcd#?ETS_DUNGEON_DAILY.pass_value
	end ,
	
	%% 是否通知客户端刷新完成数量
	case  NeedRefresh of
		true ->
			send_pass_data(PidSend,DunRcd#?ETS_DUNGEON_DAILY.pass_type,NewPassValue) ;
		false ->
			skip
	end ,
	
	%% 是否通关副本
	case Passed of
		false ->
			NewDunRcd2 = DunRcd#?ETS_DUNGEON_DAILY{pass_value = NewPassValue};
%% 			save_dungeon_daily(NewDunRcd2)  ;
		true ->
			case DunRcd#?ETS_DUNGEON_DAILY.pass_assess =:= 0 of
				true ->
					PassAssess = data_config:get_pass_assess(DunRcd#?ETS_DUNGEON_DAILY.begin_time,DunTpl#temp_dungeon.duration) ,
					NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{pass_assess = PassAssess, pass_value = NewPassValue} ,
%% 					save_dungeon_daily(NewDunRcd) ,
					NewDunRcd2 = finish_dungeon(PidSend,NewDunRcd,true);
				false ->
					NewDunRcd2 = DunRcd
			end
	end,
%% 	NewDunRcd2 = get_dungeon_daily(get(uid)),
	MonsterList = lib_mon:get_monsters(),
	NewMonsterList = lists:map(fun(M) ->
						  			{M#temp_mon_layout.x,
									 M#temp_mon_layout.y,
									 M#temp_mon_layout.monid}
				  					end , MonsterList) ,
	NewDunRcd3 = NewDunRcd2#?ETS_DUNGEON_DAILY{monsters = NewMonsterList},
	NewDunRcd4 = do_dungeon_kill(NewDunRcd3),
	save_dungeon_daily(NewDunRcd4).

%% 客户端触发器
perform_trigger(TrigerTpl,SceneId,PidSend) ->
	DunRcd = get_dungeon_daily(get(uid)) ,
	NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{triggers = DunRcd#?ETS_DUNGEON_DAILY.triggers -- [TrigerTpl#temp_dungeon_trigger.action], last_time = util:unixtime()} ,
	save_dungeon_daily(NewDunRcd) ,
	case TrigerTpl#temp_dungeon_trigger.event of
		1 ->
			lib_dungeon_monster:load_monster(SceneId,TrigerTpl#temp_dungeon_trigger.param) ,
			MonsterList = lib_mon:get_monsters(),
			NewMonsterList = lists:map(fun(M) ->
						  			{M#temp_mon_layout.x,
									 M#temp_mon_layout.y,
									 M#temp_mon_layout.monid}
				 					end , MonsterList) ,  
			NewDunRcd2 = NewDunRcd#?ETS_DUNGEON_DAILY{monsters = NewMonsterList},
			save_dungeon_daily(NewDunRcd2) ,
			%io:format("perform_trigger~p~n",[lib_mon:get_monsters()]),
			{ok,DataBin} = pt_12:write(12002, [DunRcd#?ETS_DUNGEON_DAILY.sid,[],lib_mon:get_monsters(),[]]) ,
			lib_send:send_to_sid(PidSend, DataBin) ;
		2 ->
			case TrigerTpl#temp_dungeon_trigger.param of
				[DialId] ->
					case lib_opera:notify_opera_dialogue(DunRcd#dungeon_daily.uid,PidSend,DialId) of
						false ->
							%%副本时间暂停
							misc:cancel_timer(dungeon_timer),  
							NewDunRcd2 = NewDunRcd#?ETS_DUNGEON_DAILY{last_time = util:unixtime()},
							save_dungeon_daily(NewDunRcd2);
						true ->
							skip
					end;
				_ ->
					skip
			end ;
		3 ->
			case TrigerTpl#temp_dungeon_trigger.param of
				[AnimId,ActId] ->
					case lib_opera:notify_opera_animation(DunRcd#dungeon_daily.uid,PidSend,AnimId) of
						false ->
							%%副本时间暂停
							misc:cancel_timer(dungeon_timer),  
							NewDunRcd2 = NewDunRcd#?ETS_DUNGEON_DAILY{last_time = util:unixtime()},
							save_dungeon_daily(NewDunRcd2);
						true ->
							skip
					end;
%% 					{ok,DataBin} = pt_23:write(23006, [AnimId,ActId]) ,
%% 					lib_send:send_to_sid(PidSend, DataBin) ;
				_ ->
					skip
			end ;
		_ ->
			skip
	end .

%%剧情结束
dungeon_dialogue_finish(Status) ->
	PidSend = Status#player.other#player_other.pid_send,
	lib_dungeon_exp:trigger_call_back(Status,?CONDITION_END),
	lib_opera:start_scene_mon_ai(Status#player.id),
	case get_dungeon_daily(Status#player.id) of 
		DunRcd when is_record(DunRcd, ?ETS_DUNGEON_DAILY) ->
			if 
				DunRcd#dungeon_daily.pass_assess > 0 ->
					send_finish_data(DunRcd,PidSend);
				true ->
					LeftTime = DunRcd#?ETS_DUNGEON_DAILY.begin_time 
							+ data_dungeon:get_duration(DunRcd#?ETS_DUNGEON_DAILY.sid)
	  						- DunRcd#?ETS_DUNGEON_DAILY.last_time,
					DunID = lib_scene:get_base_scene(Status#player.scene) ,
 					ScnTplRcd = lib_scene:get_scene_tmpl(DunID),
					{ok, BinData} = pt_23:write(23001, [1,LeftTime,DunID,ScnTplRcd#temp_scene.x,ScnTplRcd#temp_scene.y]),
					lib_send:send_to_sid(PidSend, BinData),
					%%TODO:副本计时开始
					misc:cancel_timer(dungeon_timer) ,
					?TRACE("lib_dungeon:dialogue_finish::~p~n",[LeftTime]),
					FinishTimer = erlang:send_after(LeftTime * 1000, self(), {'finish_dungeon', PidSend}) ,
					put(dungeon_timer,FinishTimer) ,
					put(finish_time,util:unixtime()+LeftTime)
			end,
			ok;
		_->
			skip
	end.
	
%%进入场景后副本初始化怪物
init_dungeon_monsters(Status) ->
	SceneId = Status#player.scene,
	case get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd, ?ETS_DUNGEON_DAILY) ->
			case lib_mon:get_monsters() of 
				MonsterList when length(MonsterList) =:= 0 ->
					%%重连情况
					lib_dungeon_monster:load_monster(SceneId,DunRcd#?ETS_DUNGEON_DAILY.monsters);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%%副本结束(各种方式的结束)
finish_dungeon(PidSend) ->
	case get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd,dungeon_daily) andalso DunRcd#?ETS_DUNGEON_DAILY.sid > 0 ->
			finish_dungeon(PidSend, DunRcd, false) ;
		_ ->
			[]
	end .

finish_dungeon(PidSend,DunRcd,NotFlag) when is_record(DunRcd,dungeon_daily)->
	%misc:cancel_timer(dungeon_timer) ,
	%misc:cancel_timer(?MON_STATE_TIMER_KEY) ,
%% 	lib_dungeon_monster:clear_monsters() ,
	DunRcd2 = do_time_score(DunRcd),
	set_master(DunRcd2#dungeon_daily.sid, DunRcd2#dungeon_daily.uid, get_dungeon_score()),
	%%TODO:是否已经播放剧情，这个副本是否有结束剧情，temp_dungeon
	if 
		DunRcd2#dungeon_daily.pass_assess =:= 0 ->
			send_finish_data(DunRcd2,PidSend);
		true ->	
			DunTpl = data_dungeon:get_dungeon(DunRcd2#dungeon_daily.sid) , 
			DialogId =  DunTpl#temp_dungeon.end_dialog,
			case check_end_dungeon(DunRcd#?ETS_DUNGEON_DAILY.sid) of
				false ->
					?TRACE("[lib_dungeon]boss die end~n"),
				if 
					DialogId =/= 0 ->
						case lib_opera:notify_opera_dialogue(DunRcd2#dungeon_daily.uid,PidSend,DialogId) of
							false ->
								send_finish_data(DunRcd2,PidSend);
							_ -> 
								skip
						end;
					true ->
						send_finish_data(DunRcd2,PidSend)
				end;
				true ->
					?TRACE("[lib_dungeon]boss die not end~n"),
					skip
			end
	end,
	case NotFlag of
		true ->
			DFRcd = get_dungeon_finish(DunRcd2#dungeon_daily.uid) ,
			case lib_player:get_player(DunRcd2#dungeon_daily.uid) of
				Player when is_record(Player, player) ->
					update_dungeon_finish(DFRcd,Player#player.level,DunRcd2#dungeon_daily.sid);
				_ ->
					skip
			end;
		false ->
			skip
	end ,
	%%spawn(fun() -> log_dungeon(DunRcd2) end ),
    lib_task:call_event(lib_player:get_player(DunRcd#dungeon_daily.uid),dungeon_finish,{DunRcd#?ETS_DUNGEON_DAILY.sid,1}),
	DunRcd2.

send_finish_data(DunRcd,PidSend) ->
	TimeLeft = get(finish_time) - util:unixtime(),
	UsedTime = data_dungeon:get_duration(DunRcd#?ETS_DUNGEON_DAILY.sid) - TimeLeft, 
	[TimeScore,ItemNum,KillNum] = DunRcd#?ETS_DUNGEON_DAILY.dungeon_score,
	MasterScore = case ets:lookup(?ETS_DUNGEON_MASTER, DunRcd#?ETS_DUNGEON_DAILY.sid) of
		[MDRcd | _] ->
			MDRcd#?ETS_DUNGEON_MASTER.score;
		_ ->
			0
	end,
	{ok,PassBin} = pt_23:write(23033, [TimeLeft,DunRcd#?ETS_DUNGEON_DAILY.pass_assess,
									  UsedTime,ItemNum,KillNum,get_dungeon_score(),MasterScore]),
	lib_send:send_to_sid(PidSend, PassBin),
	ok.

%% 玩家退出副本
leave_dungeon(Status) ->
	%misc:cancel_timer(dungeon_timer) ,
	%misc:cancel_timer(?MON_STATE_TIMER_KEY) ,
	lib_battle:erase_battle_player(get(uid)),%%改变玩家战斗状态
	lib_dungeon:eraseMonProcess(),	
	lib_dungeon_monster:clear_monsters() ,
	case get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd,dungeon_daily) andalso DunRcd#?ETS_DUNGEON_DAILY.sid > 0 ->
			PreAttr = DunRcd#?ETS_DUNGEON_DAILY.pre_attr,
			reset_dungeon(DunRcd),
			lib_dungeon_exp:leave_dungeon(Status,PreAttr);
		_ ->
			skip
	end .



%%写日志
log_dungeon(DunRcd) ->
    TempDungeonRcd = tpl_dungeon:get(DunRcd#?ETS_DUNGEON_DAILY.sid),
	db_agent_log:add_dungeon_log(DunRcd#?ETS_DUNGEON_DAILY.uid, DunRcd#?ETS_DUNGEON_DAILY.sid,TempDungeonRcd#temp_dungeon.grp,DunRcd#?ETS_DUNGEON_DAILY.begin_time, util:unixtime(), DunRcd#?ETS_DUNGEON_DAILY.times, DunRcd#?ETS_DUNGEON_DAILY.pass_assess) .

%%写日志
update_log(UId,BeginTime,RewardList) ->
	db_agent_log:update_dungeon_log(UId,BeginTime, RewardList) .

%%获取进程的所有怪物
get_monsters() ->
 	lib_mon:get_monsters().

%%
%%根据等级区间更新已完成副本ets
update_dungeon_finish(DFRcd, Level,DunId) -> 
	NewDFRcd = if 
		Level < 10 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv0=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv0))};
		Level < 20 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv1=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv1))};
		Level < 30 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv2=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv2))};
		Level < 40 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv3=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv3))};
		Level < 50 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv4=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv4))};
		Level < 60 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv5=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv5))};
		Level < 70 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv6=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv6))};
		Level < 80 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv7=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv7))};
		Level < 90 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv8=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv8))};
		Level < 100 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv9=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv9))};
		Level < 110 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv10=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv10))};
		Level < 120 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv11=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv11))};
		Level < 130 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv12=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv12))};
		Level < 140 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv13=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv13))};
		Level < 150 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv14=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv14))};
		Level < 160 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv15=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv15))};
		Level < 170 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv16=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv16))};
		Level < 180 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv17=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv17))};
		Level < 190 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv18=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv18))};
		Level < 200 ->
			DFRcd#?ETS_DUNGEON_FINISH{
							 dlv19=lists:append([DunId],lists:delete(DunId,DFRcd#?ETS_DUNGEON_FINISH.dlv19))};
		true ->
			DFRcd
 	end,
	NewDFRcd2 = NewDFRcd#?ETS_DUNGEON_FINISH{
						dlv=lists:append([DunId],lists:delete(DunId,NewDFRcd#?ETS_DUNGEON_FINISH.dlv))},
	save_dungeon_finish(NewDFRcd2).


%%副本时间评分
calc_time_score(ParamsList,UsedTime) ->
	{{_,_},Result} = lists:foldr(
		fun({Xv,Yv},{{Nx,Ny},Score}) ->
			NewScore = if 
				Score =< 0 andalso UsedTime < Nx andalso  Xv =< UsedTime ->
					((Yv-Ny)*(Nx-UsedTime))div(Nx-Xv) + Ny;
				true ->
					Score
			end,
			{{Xv,Yv},NewScore}
		end
		,{lists:last(ParamsList),0}
		,ParamsList
		),
	Result.

%%使用道具回调
use_item_cb() ->
	do_dungeon_item().

%%处理副本评分
do_dungeon_kill(DunRcd) ->
	[A,B,KillNum] = DunRcd#?ETS_DUNGEON_DAILY.dungeon_score,
	NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{dungeon_score = [A,B,KillNum+1]},
	NewDunRcd.

do_dungeon_item() ->
	DunRcd = get_dungeon_daily(get(uid)) ,
	[A,ItemNum,C] = DunRcd#?ETS_DUNGEON_DAILY.dungeon_score,
	NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{dungeon_score = [A,ItemNum,C]},
	save_dungeon_daily(NewDunRcd) .

do_time_score(DunRcd) ->
	NowTime = util:unixtime() ,
	FinishTime = get(finish_time),
	TimeUsed = util:unixtime() + data_dungeon:get_duration(DunRcd#?ETS_DUNGEON_DAILY.sid) - FinishTime,
	case tpl_dungeon:get(DunRcd#?ETS_DUNGEON_DAILY.sid) of
		DunTplRcd when is_record(DunTplRcd,temp_dungeon) ->
			ScoreParam = DunTplRcd#temp_dungeon.time_bonus,
			TimeScore = calc_time_score(ScoreParam, TimeUsed),
			[_,B,C] = DunRcd#?ETS_DUNGEON_DAILY.dungeon_score,
			NewDunRcd = DunRcd#?ETS_DUNGEON_DAILY{dungeon_score = [TimeScore,B,C]},
			save_dungeon_daily(NewDunRcd),
			NewDunRcd;
		_ ->
			DunRcd
	end.

get_dungeon_score() ->
	case get_dungeon_daily(get(uid)) of
		DunRcd when is_record(DunRcd, ?ETS_DUNGEON_DAILY) ->
			case tpl_dungeon:get(DunRcd#?ETS_DUNGEON_DAILY.sid) of
				DunTplRcd when is_record(DunTplRcd,temp_dungeon) ->
					TplItemScore = DunTplRcd#temp_dungeon.drug_take_off,
					TplKillScore = DunTplRcd#temp_dungeon.monster_bonus,
					[TimeScore,ItemNum,KillNum] = DunRcd#?ETS_DUNGEON_DAILY.dungeon_score,
					[_,BaseItemScore,BaseKillScore] = [0,20,0],%%初始分数，待配置
					ItemScore = max(0,BaseItemScore - ItemNum * TplItemScore),
					KillScore = min(30,BaseKillScore + KillNum * TplKillScore),
					TimeScore + ItemScore + KillScore;
				_ ->
					0
			end;
		_ ->
			skip
	end.
	
%%获得前置副本id
get_pre_dungeonIds(DunGrpId,DunId) ->
	DunTplRcd = tpl_dungeon:get_by_grp(DunGrpId),
	DungeonRcds = lists:filter(fun(Rcd) ->
										Rcd#temp_dungeon.next_sid =:= DunId
				  					end , DunTplRcd) ,
	DungeonIds = lists:map(fun(T) -> 
					  T#temp_dungeon.sid 
			  end , DungeonRcds),
	DungeonIds.

%%前置副本是否完成
check_pre_dungeon(DunGrpId,DunId,PlayerId)->
	PreDunIds = get_pre_dungeonIds(DunGrpId,DunId),
	FDunRcd = get_dungeon_finish(PlayerId) ,
	Is = lists:all(fun(Id) -> 
				lists:member(Id, FDunRcd#?ETS_DUNGEON_FINISH.dlv)
				end,PreDunIds),
	Is.

info_dungeon_rewards(Player) ->
%%上线提示副本奖励	
	case get_dungeon_daily(Player#player.id) of
		DDunRcd when is_record(DDunRcd, ?ETS_DUNGEON_DAILY) ->
			if 
				is_list(DDunRcd#?ETS_DUNGEON_DAILY.rewards) 
				andalso length(DDunRcd#?ETS_DUNGEON_DAILY.rewards) > 0 ->
				{ok,RewarBin} = pt_23:write(23034, [lib_scene:get_base_scene(Player#player.scene),DDunRcd#?ETS_DUNGEON_DAILY.rewards]) ,
				lib_send:send_to_sid(Player#player.other#player_other.pid_send, RewarBin);
				true ->
					skip
			end;
		_ ->
			skip
	end.

%%
update_dungeon_last_time(UId) ->
	case get_dungeon_daily(UId) of
		DDRcd when is_record(DDRcd,dungeon_daily) ->
			NewDunRcd = DDRcd#?ETS_DUNGEON_DAILY{last_time = util:unixtime()},
			save_dungeon_daily(NewDunRcd);
		_ ->
			skip
	end.

%%玩家退出游戏时候，清除玩家的副本怪物进程
eraseMonProcess() ->
    DunMons = lib_mon:get_monsters(),
    [singleEraseMP(SingleMon) || SingleMon <- DunMons].


singleEraseMP(MonRcd) ->
    if
        is_record(MonRcd,temp_mon_layout) ->
            gen_fsm:send_all_state_event(MonRcd#temp_mon_layout.pid,stop);
        true ->
            skip
    end.

%%获取副本组信息
get_daily_dungeon_info(PlayerId) ->
    DungeonGroupIds = db_agent_dungeon:get_all_dungeon_group(), 
    Fun = fun([GroupId],RetInfo) ->
            Num = db_agent_log:get_dungeon_group_num(PlayerId,GroupId),
            [{GroupId,Num} | RetInfo]
    end,
    lists:foldl(Fun,[],DungeonGroupIds).

check_end_dungeon(DunId) ->
	case data_dungeon:get_dungeon(DunId) of
		DunTpl when is_record(DunTpl,temp_dungeon) ->
			case tpl_dungeon_obj:get_by_dun_id(DunId) of
				DunObjList when length(DunObjList) > 0 ->
					lists:any(fun(T) -> DunTpl#temp_dungeon.pass_cond =:= T#temp_dungeon_obj.condition_param end,DunObjList);
				_ ->
					false
			end;
		_ ->
			false
	end.

enter_scene_ok(Player) ->
	lib_dungeon:init_dungeon_monsters(Player),
	lib_dungeon_exp:notify_dungeon_state(Player),
	lib_dungeon_exp:notify_level_up(Player).
