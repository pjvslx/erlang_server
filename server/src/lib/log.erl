%%%-----------------------------------
%%% @Module  : log
%%% @Author  : 
%%% @Email   : 
%%% @Created :
%%% @Description:
%%% attention:
%%%-----------------------------------
-module(log).
-include("record.hrl").
-include("common.hrl").
-include("log.hrl"). 
-include("debug.hrl").

-compile(export_all).


%------------------------
%-	模块自身数据日志
%------------------------

%% 铜钱消耗日志
%% CostType 消耗类型
log_cost_coin(PlayerId, CostCoin, CostBCoin, CostType) ->
	spawn(fun()-> db_agent_log:insert_cost_coin(PlayerId, CostCoin, CostBCoin, CostType) end).

%% 元宝消耗日志
%% CostType 消耗类型
log_cost_gold(PlayerId, CostGold, CostBGold, CostType) ->
	spawn(fun()-> db_agent_log:insert_cost_gold(PlayerId, CostGold, CostBGold, CostType) end).

%% 物品消耗日志
log_cost_goods(PlayerId, Gtid, GoodsNum, Bind, Source) ->
	spawn(fun()-> db_agent_log:insert_cost_goods(PlayerId, Gtid, GoodsNum, Bind, Source) end).

%% 发放铜钱
log_add_coin(PlayerId, Money, Source) ->
	spawn(fun()-> db_agent_log:insert_add_coin(PlayerId,Money, Source) end).

%% 发放绑定铜钱
log_add_bcoin(PlayerId, Money, Source) ->
	spawn(fun()-> db_agent_log:insert_add_bcoin(PlayerId,Money, Source) end).

%% 发放元宝
log_add_gold(PlayerId, Money, Source) ->
	spawn(fun()-> db_agent_log:insert_add_gold(PlayerId,Money, Source) end).

%% 奖励经验
log_add_exp(PlayerId, Num, Source, ObjId) ->
	spawn(fun()-> db_agent_log:insert_add_exp(PlayerId,Num, Source, ObjId) end).

%% 发放绑定元宝
log_add_bgold(PlayerId, Money, Source) ->
	spawn(fun()-> db_agent_log:insert_add_bgold(PlayerId,Money, Source) end).

%% 发放物品
log_add_goods(PlayerId, Gtid, GoodsNum, Bind, Source) ->
	spawn(fun()-> db_agent_log:insert_add_goods(PlayerId, Gtid, GoodsNum, Bind, Source) end).

%% 记录商店销售记录
log_shop(PlayerId, AccName, Lv, Career, GuildId, MoneyType, Amount, GoodsType, GoodsSubType, GoodsTid, GoodsNum) ->
	spawn(fun()-> db_agent_log:insert_log_shop(PlayerId, AccName, Lv, Career, GuildId, MoneyType, Amount, GoodsType, GoodsSubType, GoodsTid, GoodsNum) end).

%% ----------------------------------------------
%% 宠物日志
%% ----------------------------------------------
%% 宠物进阶
log_pet_upgrade_quality(PlayerId, OldQualityLv, NewQualityLv, SuccRate, AddRate, CostGold, CostCoin, CostGoodsTid) ->
	spawn(fun()-> db_agent_log:add_pet_upgrade_quality_log(PlayerId, OldQualityLv, NewQualityLv, SuccRate, AddRate, CostGold, CostCoin, CostGoodsTid) end).

%% 宠物进化
log_pet_evolve(PlayerId, GrowthLv, GrowthProgress, NewGrowthLv, NewGrowthProgress, CostCoin, CostGold, CostGoodsTid) ->
	spawn(fun()-> db_agent_log:add_pet_evolve_log(PlayerId, GrowthLv, GrowthProgress, NewGrowthLv, NewGrowthProgress, CostCoin, CostGold, CostGoodsTid) end).

%% 宠物提升
log_pet_upgrade(PlayerId, AptitudeLv, AptitudeProgress, NewAptitudeLv, NewAptitudeProgress, CostCoin, CostGold, CostGoodsTid) ->
	spawn(fun()-> db_agent_log:add_pet_upgrade_log(PlayerId, AptitudeLv, AptitudeProgress, NewAptitudeLv, NewAptitudeProgress, CostCoin, CostGold, CostGoodsTid) end).

%% ----------------------------------------------
%% 铸造日志
%% ----------------------------------------------
%% desc: 强化日志写入
log_stren(GoodsInfo, NewGoodsInfo, CostGoodsTid, CoinCost, GoldCost) ->
%% 	?TRACE("-------------------start ~p ----------------~n", [util:unixtime()]),
%% 	L = lists:seq(10000, 30000),
%% 	F = fun(Seq) ->
%% 				db_agent_log:add_stren_log(GoodsInfo#goods.uid + Seq, GoodsInfo#goods.gtid + Seq, GoodsInfo#goods.stren_lv, 
%% 											 GoodsInfo#goods.stren_percent, NewGoodsInfo#goods.stren_lv, 
%% 											 NewGoodsInfo#goods.stren_percent, CoinCost + Seq, GoldCost + Seq, CostGoodsTid + Seq)
%% 		end,
%% 	lists:foreach(F, L),  
%% 	?TRACE("-------------------end ~p ----------------~n", [util:unixtime()]).
	spawn(fun()-> db_agent_log:add_stren_log(GoodsInfo#goods.uid, GoodsInfo#goods.gtid, GoodsInfo#goods.stren_lv, 
											 GoodsInfo#goods.stren_percent, NewGoodsInfo#goods.stren_lv, 
											 NewGoodsInfo#goods.stren_percent, CoinCost, GoldCost, CostGoodsTid) end).

%% 任务日志
%% 角色id PlayerId
%% 平台账户名字 Acnm
%% 职业       Career
%% 帮派	 GuildId
%% 任务类型 TaskType
%% 任务id	 TaskId
%% 任务状态 Action
log_task(PlayerId, Acnm, Career, GuildId, TaskType, TaskId,Action) ->
	spawn(fun()-> db_agent_log:add_task_log(PlayerId, Acnm, Career, GuildId, TaskType, TaskId,Action) end).

%% %% desc: 升级日志写入
%% 
%% log_upg_equip(GoodsInfo, NewId, Coin) ->
%%     [PlayerId, GoodsId, GoodsTid, Date, Time] = lib_casting:get_base_log_data(GoodsInfo),
%%     
%% 	spawn(fun()-> db:bg_insert(log_upg, [player_id, gid, goods_tid, coin, new_gid, date, time], [PlayerId, GoodsId, GoodsTid, Coin, NewId, Date, Time]) end).
%% 
%% %% desc: 合成日志写入
%% 
%% log_compose(StoneList, PlayerId, GoodsTid, NewGid, Coin, State) ->
%%     Len = length(StoneList),
%%     [[Id1, Num1], [Id2, Num2], [Id3, Num3], [Id4, Num4]] = 
%%         if
%%             Len =< 4 ->
%%                 StoneList ++ lists:duplicate(4 - Len, [0, 0]);
%%             true ->
%%                 ?ERROR_MSG("stone list length error:~p", [StoneList]),
%%                 lists:duplicate(4, [0, 0])
%%         end,
%%     [Date, Time] = [lib_casting:get_date_list(), lib_casting:get_time_list()],
%%     
%% 	spawn(fun()-> db:bg_insert(log_compose, [player_id, goods_tid, coin, id1, num1, id2, num2, id3, num3, id4, num4, new_gid, state, date, time], [PlayerId, GoodsTid, Coin, Id1, Num1, Id2, Num2, Id3, Num3, Id4, Num4, NewGid, State, Date, Time]) end).
%% 
%% %% desc: 镶嵌日志写入
%% 
%% log_inlay(GoodsInfo, StoneList, Coin) ->
%%     Len = length(StoneList),
%%     [Id1, Id2, Id3, Id4] = if
%%                                    Len =< 4 ->
%%                                        StoneList ++ lists:duplicate(4 - Len, 0);
%%                                    true ->
%%                                        ?ERROR_MSG("stone list length error:~p", [StoneList]),
%%                                        lists:duplicate(4, 0)
%%                                end,
%%     [PlayerId, GoodsId, GoodsTid, Date, Time] = lib_casting:get_base_log_data(GoodsInfo),
%%     
%% 	spawn(fun()-> db:bg_insert(log_inlay, [player_id, gid, goods_tid, coin, id1, id2, id3, id4, date, time], [PlayerId, GoodsId, GoodsTid, Coin, Id1, Id2, Id3, Id4, Date, Time]) end).
%% 
%% %% desc: 拆除日志写入
%% 
%% log_backout(GoodsInfo, StoneTlist, Coin) ->
%%     Len = length(StoneTlist),
%%     [StoneTid1, StoneTid2, StoneTid3, StoneTid4] = 
%%         if
%%             Len =< 4 ->
%%                 StoneTlist ++ lists:duplicate(4 - Len, 0);
%%             true ->
%%                 ?ERROR_MSG("stonetype list length error:~p", [StoneTlist]),
%%                 lists:duplicate(4 , 0)
%%         end,
%%     [PlayerId, GoodsId, GoodsTid, Date, Time] = lib_casting:get_base_log_data(GoodsInfo),
%%     
%% 	spawn(fun()-> db:bg_insert(log_backout, [player_id, gid, goods_tid, stone1, stone2, stone3, stone4, coin, date, time], [PlayerId, GoodsId, GoodsTid, StoneTid1, StoneTid2, StoneTid3, StoneTid4, Coin, Date, Time]) end).
%% 
%% %% desc: 洗炼日志写入
%% %% washtuple: [{attriId, lv, val}...
%% 
%% log_wash(GoodsInfo, Coin, Gold, StoneId, WashList) when is_integer(StoneId), is_integer(Gold) ->
%%     [PlayerId, GoodsId, GoodsTid, Date, Time] = lib_casting:get_base_log_data(GoodsInfo),
%%     [W1, W2, W3, W4, W5] = lib_casting:wash_data_to_list(WashList, []),
%%     
%% 	spawn(fun()-> db:bg_insert(log_wash, [player_id, gid, goods_tid, coin, gold, stone_id, wash1, wash2, wash3, wash4, wash5, date, time], [PlayerId, GoodsId, GoodsTid, Coin, Gold, StoneId, W1, W2, W3, W4, W5, Date, Time]) end);
%% log_wash(GoodsInfo, Coin, Gold, _Stone, WashList) ->
%%     log_wash(GoodsInfo, Coin, Gold, 0, WashList).
%%     
%% 

%% 
%% %% desc: 消费日志
%% %% ConsumeType: "shop", "shop_bargain", "npc", "remote_shop", "exchange_shop", "guild_shop"
%% 
%% log_consume(ConsumeType, GoodsTid, PS, NewPS) ->
%%     CostCoin = abs(PS#player_status.coin - NewPS#player_status.coin),
%%     CostGold = abs(PS#player_status.gold - NewPS#player_status.gold),
%%     CostZTB = abs(PS#player_status.bcoin - NewPS#player_status.bcoin),
%%     CostPres = abs(PS#player_status.guild_prestige - NewPS#player_status.guild_prestige),
%%     PlayerId = NewPS#player_status.id,
%%     [Date, Time] = [lib_casting:get_date_list(), lib_casting:get_time_list()],
%%     
%% 	spawn(fun()-> db:bg_insert(log_consume, [player_id, consume_type, goods_tid, cost_coin, cost_gold, cost_ztb, guild_prestige, date, time], [PlayerId, ConsumeType, GoodsTid, CostCoin, CostGold, CostZTB, CostPres, Date, Time]) end).
%%     
%% %% desc: 淘宝日志
%% log_trea(PS, Cost, Type) ->
%%     CurGold = PS#player_status.gold,
%%     [Date, Time] = [lib_casting:get_date_list(), lib_casting:get_time_list()],
%%     Fields = ["player_id", "cur_gold", "cost_gold", "trea_type", "date", "time"],
%%     Data = [PS#player_status.id, CurGold, Cost, Type, Date, Time],
%%     
%% 	spawn(fun()-> db:bg_insert(log_trea, Fields, Data) end).
%%     
%% 
%% 
%% %% 任务日志
%% %% MissionStatus 1代表接受任务;2代表放弃任务;3代表完成任务
%% %%类型 0主线 1支线 2日常 4帮派 5、6挑战 7、8、9 10 11酒馆
%% log_mission(Status, MissionID, MissionStatus) ->
%% 	case data_task:get(MissionID, Status) of
%% 		null ->
%% 			error;
%% 		Minfo ->
%% 			TaskType = change_mission_type(Minfo#task.type),
%% 			if TaskType == 5 -> skip;
%% 			   true ->
%% 					Stamp = util:unixtime(),
%% 					DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(Stamp))),
%% 					TaskLv = Minfo#task.level,
%% 					DB_table_name = if
%% 								 		TaskLv =< 10 -> t_log_mission1;
%% 								 		TaskLv =< 20 -> t_log_mission2;
%% 								 		true -> t_log_mission3
%% 									end,
%% 					lib_common:actin_new_proc(db, bg_insert, [
%% 												   DB_table_name,
%% 												   ["role_id", "role_name", "account_name", "role_level", "mission_id", "mission_name", "mission_type", "min_level", "status", "date_stamp", "time_stamp"], 
%% 												   [Status#player_status.id, Status#player_status.nickname, Status#player_status.accname, Status#player_status.lv, MissionID, tool:to_list(Minfo#task.name), change_mission_type(Minfo#task.type), TaskLv, MissionStatus, DateStamp, Stamp]
%% 												   ]),
%% 					ok
%% 			end
%% 	end.

%% %% 角色登入登出日志
%% log_in_out(Status, LogoutStamp) ->
%% 	LoginDate = date_convert(util:stamp_to_date(Status#player_status.last_login_time)),
%% 	LoginDateStamp = util:date_to_stamp(LoginDate),
%% %% 	LogoutStamp = util:unixtime(),	
%% 	LogoutDate = date_convert(util:stamp_to_date(LogoutStamp)),
%% 	LogoutDateStamp = util:date_to_stamp(LogoutDate),
%% 	TotalPay = 0,
%% 	lib_common:actin_new_proc(
%% 	  db, bg_insert, [
%% 					  t_log_in_out,
%% 					  ["role_id", "role_name", "account_name", "login_time", "logout_time", "online_time", "total_pay", "role_level", "last_login_ip", "login_date_stamp", "logout_date_stamp"],
%% 					  [Status#player_status.id, Status#player_status.nickname, Status#player_status.accname,  Status#player_status.last_login_time, 
%% 					   LogoutStamp, LogoutStamp - Status#player_status.last_login_time, TotalPay, Status#player_status.lv, Status#player_status.last_login_ip, LoginDateStamp, LogoutDateStamp]
%% 					  ]
%% 	  ).
%% %% 	db:insert(t_log_in_out, 
%% %% 								  ["role_id", "role_name", "account_name", "login_time", "logout_time", "online_time", "total_pay", "role_level", "last_login_ip", "login_date_stamp", "logout_date_stamp"],
%% %% 								  [Status#player_status.id, Status#player_status.nickname, Status#player_status.accname,  Status#player_status.last_login_time, 
%% %% 								   LogoutStamp, LogoutStamp - Status#player_status.last_login_time, TotalPay, Status#player_status.lv, Status#player_status.last_login_ip, LoginDateStamp, LogoutDateStamp]).
%% 
%% %% 角色注册日志
%% log_register(Id, RoleName, AccName, Sex, Career, Ip) ->
%% 			CreateTime = util:unixtime(),
%% 			%%取出当日在该星期中的排位
%% 			Date = date(),
%% 			WeekDay = calendar:day_of_the_week(Date),
%% 			{Year, Month, Day} = Date,
%% 			{Hour, _Minute, _Sec} = time(),
%% 			DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(CreateTime))),
%% 			lib_common:actin_new_proc(
%% 			  db, bg_insert, [
%% 							  t_log_register,
%% 							  ["role_id", "role_name", "account_name", "create_time", "role_sex", "role_career", "ip", "week_day", "year", "month", "day", "hour", "date_stamp"],
%% 							  [Id, RoleName, AccName, CreateTime, Sex, Career, Ip, WeekDay, Year, Month, Day, Hour, DateStamp]
%% 							  ]
%% 			  ).
%% 
%% %% 玩家到达创建角色页面统计日志
%% log_create_page(AccountName, Ip) ->
%% 	EnterTime = util:unixtime(),
%% 	DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(EnterTime))),
%% 	{Year, Month, Day} = date(),
%% 	{Hour, _Minute, _Sec} = time(),
%% 	lib_common:actin_new_proc(
%% 	  db, bg_insert, [
%% 					  t_log_create_page,
%% 					  ["account_name", "ip", "time_stamp", "date_stamp", "year", "month", "day", "hour"],
%% 					  [AccountName, Ip, EnterTime, DateStamp, Year, Month, Day, Hour]
%% 					  ]
%% 	  ).
%% %% 	db:insert(t_log_create_page,
%% %% 								  ["account_name", "ip", "time_stamp", "date_stamp", "year", "month", "day", "hour"],
%% %% 								  [AccountName, Ip, EnterTime, DateStamp, Year, Month, Day, Hour]).
%% 
%% %%记录即时玩家在线情况
%% log_online(OnlineNum) ->
%% 	TimeStamp = util:unixtime(),
%% 	DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(TimeStamp))),
%% 	WeekDay = calendar:day_of_the_week(date()),
%% 	{Year, Month, Day} = date(),
%% 	{Hour, Minute, _Sec} = time(),
%% 	lib_common:actin_new_proc(
%% 	  db, bg_insert, [
%% 					  t_log_online,
%% 					  ["online", "log_time_stamp", "date_stamp", "week_day", "year", "month", "day", "hour", "min"],
%% 					  [OnlineNum, TimeStamp, DateStamp, WeekDay, Year, Month, Day, Hour, Minute]
%% 					  ]
%% 	  ).
%% %% 	db:insert(t_log_online,
%% %% 								  ["online", "log_time_stamp", "date_stamp", "week_day", "year", "month", "day", "hour", "min"],
%% %% 								  [OnlineNum, TimeStamp, DateStamp, WeekDay, Year, Month, Day, Hour, Minute]).
%% 
%% %%记录新用户完全进入到游戏记录的日志
%% log_new_user_entrance(Status) ->
%% 	case Status#player_status.logout_time of
%% 		0  ->
%% 			TimeStamp = util:unixtime(),
%% 			DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(TimeStamp))),
%% 			{Hour, _Minute, _Sec} = time(),
%% 			
%% 			lib_common:actin_new_proc(db, bg_insert, 
%% 									  [
%% 									    t_log_new_user_entrance,
%% 										["account_name", "role_id", "role_name", "lv", "ip", "time_stamp", "date_stamp", "hour"],
%% 										[Status#player_status.accname, Status#player_status.id, Status#player_status.nickname, Status#player_status.lv, Status#player_status.last_login_ip, TimeStamp, DateStamp, Hour]
%% 									  ]
%% 									 );
%% 		_ ->
%% 			skip
%% 	end.
%% 
%% %%记录被踢的玩家的日志
%% %% 参数：KickType - 被踢类型（1：心跳包频率过快；2：被手动踢下线；3: 消息包数量过多；4: 移动速度过快）
%% log_kick_off(Status, KickType, KickTime) ->
%% 	spawn(fun()-> db:bg_insert(log_kick_off,
%% 								  ["player_id", "nickname", "kick_type", "time", "scene", "x", "y"],
%% 								  [Status#player_status.id, Status#player_status.nickname, KickType, KickTime, lib_scene:get_res_id(Status#player_status.scene), Status#player_status.x, Status#player_status.y]) end).
%% 
%% 
%% %%记录每天使用游戏各系统的玩家
%% log_enter_system_day(PlayerId, SysType) ->
%% 	NowStamp = util:unixtime(),
%% 	DateStamp = util:date_to_stamp(date_convert(util:stamp_to_date(NowStamp))),
%% 	System = get_system_name_by_type(PlayerId, SysType),
%% 	?TRACE("LDS\n log System = ~p~n", [System]),
%% 	Flag = case get(System) of
%% 			   {Time} ->
%% 				   case Time == DateStamp of
%% 					   true -> false;
%% 					   _ -> put(System, {DateStamp}),
%% 							true
%% 				   end;
%% 			   _ -> put(System, {DateStamp}),
%% 					true
%% 		   end,
%% 	?TRACE("LDS\n log Flag = ~p~n", [Flag]),
%% 	Fun = fun() ->
%% 				  case db:select_row(log_enter_system_day, "id", 
%% 									 [{player_id, PlayerId},{day, DateStamp},{sys_type, SysType}]) of
%% 						[] ->
%% 							db:insert(log_enter_system_day, 
%% 									  [player_id, day, sys_type], 
%% 									  [PlayerId, DateStamp, SysType]);
%% 						_R -> skip
%% 				  end
%% 		  end,
%% 	case Flag of
%% 		true -> spawn(Fun);
%% 		_ -> skip
%% 	end.
%% 	
%% log_enter_system_day(PlayerId, SysType, SysId) ->
%% 	Type = tool:to_integer(SysType) * 100000 + tool:to_integer(SysId),
%% 	log_enter_system_day(PlayerId, Type).
%% 	
%% %%取出给出详细日期时间在当天凌晨0点日期时间
%% date_convert(DateTime) ->
%% 	{Date, _DayTime} = split_binary(DateTime, 10),
%% 	NewDate = binary_to_list(Date) ++ binary_to_list(<<" 00:00:00">>),
%% 	list_to_binary(NewDate).
%% 	
%% get_system_name_by_type(PlayerId, Type) ->
%% 	[log_enter_system] ++ [Type] ++ [PlayerId].
%% 
%% %%玩家上线初始化消费日志信息
%% log_currency_consume_init(Status) ->
%% 	case db:select_row(log_currency_consume, "recharge, cost_gold, cost_zt_money, cost_coin, cost_ubcoin, cost_prestige, cost_g_prestige, cost_acc_points", [{role_id, Status#player_status.id}]) of
%% 		[] -> ets:insert(?ETS_LOG_CURRENCY_CONSUME, 
%% 						 #ets_log_currency_consume{id = Status#player_status.id}),
%% 			  db:insert(log_currency_consume, [
%% 											   {role_id, Status#player_status.id}
%% 											  ,{accname, Status#player_status.accname}
%% 											  ,{nickname, Status#player_status.nickname}
%% 											  ,{lv, Status#player_status.lv}
%% 											  ]);
%% 		[Recharge, C_gold, C_ztm, C_coin, C_ubcoin, C_pres, C_gpres, C_point] ->
%% 			ets:insert(?ETS_LOG_CURRENCY_CONSUME, 
%% 					   #ets_log_currency_consume{id = Status#player_status.id
%% 												,recharge = Recharge
%% 												,cost_gold = C_gold
%% 												,cost_zt_money = C_ztm
%% 												,cost_coin = C_coin
%% 												,cost_ubcoin = C_ubcoin
%% 												,cost_prestige = C_pres
%% 												,cost_g_prestige = C_gpres
%% 												,cost_acc_points = C_point});
%% 		_ -> ?ERROR_MSG("log log_currency_consume_init error playerID = ~p", [Status#player_status.id]),
%% 			 ok
%% 	end.
%% 			 
%% %%玩家下线保存消费日志信息
%% log_currency_consume_save(Status) ->	
%% 	AccPionts = case mod_arena:query_arena_info(Status) of
%% 					{ok, Arena} -> Arena#arena.acc_points;
%% 					_ -> 0
%% 				end,
%% 	case ets:lookup(?ETS_LOG_CURRENCY_CONSUME, Status#player_status.id) of
%% 		[] -> ?ERROR_MSG("log_currency_consume_save error playerID = ~p", [Status#player_status.id]);
%% 		[Rd] ->
%% 			lib_common:actin_new_proc(db, update, [log_currency_consume, 
%% 					  [{recharge, Rd#ets_log_currency_consume.recharge}
%% 					  ,{gold, Status#player_status.gold}
%% 					  ,{cost_gold, Rd#ets_log_currency_consume.cost_gold}
%% 					  ,{zt_money, Status#player_status.bcoin}
%% 					  ,{cost_zt_money, Rd#ets_log_currency_consume.cost_zt_money}
%% 					  ,{coin, Status#player_status.coin}
%% 					  ,{cost_coin, Rd#ets_log_currency_consume.cost_coin}
%% 					  ,{ubcoin, Status#player_status.ubcoin}
%% 					  ,{cost_ubcoin, Rd#ets_log_currency_consume.cost_ubcoin}
%% 					  ,{prestige, Status#player_status.repu}
%% 					  ,{cost_prestige, Rd#ets_log_currency_consume.cost_prestige}
%% 					  ,{g_prestige, Status#player_status.guild_prestige}
%% 					  ,{cost_g_prestige, Rd#ets_log_currency_consume.cost_g_prestige}
%% 					  ,{acc_points, AccPionts}
%% 					  ,{cost_acc_points, Rd#ets_log_currency_consume.cost_acc_points}
%% 					  ], 
%% 					  [{role_id, Status#player_status.id}]]),
%% 			ets:delete(?ETS_LOG_CURRENCY_CONSUME, Status#player_status.id)
%% 	end.
%% 
%% %%货币消耗记录
%% %%@Id: 玩家ID
%% %%@CurType: 货币类型
%% %%@Num: 数量
%% log_currency_consume(Id, CurType, Num) ->
%% 	gen_server:cast({global, ?GLOBAL_LOG_PROCESS}, {apply_cast, log, handle_log_currency_consume, [Id, CurType, Num]}).
%% %% 	lib_common:actin_new_proc(log, handle_log_currency_consume, [Id, CurType, Num]).
%% 
%% handle_log_currency_consume(Id, CurType, Num) ->
%% 	case ets:lookup(?ETS_LOG_CURRENCY_CONSUME, Id) of
%% 		[] -> ?ERROR_MSG("log: log_currency_consume error, id = ~p record not exists~n", [Id]);
%% 		[Rd] ->
%% 			NewRd = 
%% 				case CurType of
%% 					recharge -> Recharge = Rd#ets_log_currency_consume.recharge,
%% 								if Recharge == 0 -> %%首次充值
%% 									   lib_title:add_firstpay_title(Id);
%% 								   true -> skip
%% 								end,
%% 								Rd#ets_log_currency_consume{recharge = Recharge + Num};
%% 					gold -> Rd#ets_log_currency_consume{cost_gold = Rd#ets_log_currency_consume.cost_gold + Num};
%% 					bcoin -> Rd#ets_log_currency_consume{cost_zt_money = Rd#ets_log_currency_consume.cost_zt_money + Num};
%% 					coin -> Rd#ets_log_currency_consume{cost_coin = Rd#ets_log_currency_consume.cost_coin + Num};
%% 					ubcoin -> Rd#ets_log_currency_consume{cost_ubcoin = Rd#ets_log_currency_consume.cost_ubcoin + Num};
%% 					prestige -> Rd#ets_log_currency_consume{cost_prestige = Rd#ets_log_currency_consume.cost_prestige + Num};
%% 					guild_prestige -> Rd#ets_log_currency_consume{cost_g_prestige = Rd#ets_log_currency_consume.cost_g_prestige + Num};
%% 					acc_points -> Rd#ets_log_currency_consume{cost_acc_points = Rd#ets_log_currency_consume.cost_acc_points + Num};
%% 					_Type -> ?ERROR_MSG("log: log_currency_consume error, id = ~p currency type = ~p~n", [_Type]),
%% 							 ok
%% 				end,
%% 			if is_record(NewRd, ets_log_currency_consume) -> ets:insert(?ETS_LOG_CURRENCY_CONSUME, NewRd);
%% 			   true -> skip
%% 			end
%% 	end.

%% 道具产出/消耗日志
log_tbllog_items(PS,Opt,ActionId,ItemId,ItemNumber,HappenedTime,LogTime) ->
	log_tbllog_items(PS#player.id,PS#player.account_name,PS#player.level,Opt,ActionId,ItemId,ItemNumber,PS#player.scene,HappenedTime,LogTime).
log_tbllog_items(PlayerId, AccountName, DimLevel, Opt, ActionId, ItemId, ItemNumber, MapId, HappenedTime, LogTime) ->
	db_agent_log:insert_tbllog_items(PlayerId, AccountName, DimLevel, Opt, ActionId, ItemId, ItemNumber, MapId, HappenedTime, LogTime).

%% 装备锻造、洗练、合成日志
log_tbllog_equipment(PS, ItemId, ValueBefore, ValueAfter, ChangeType, Material, HappenedTime, LogTime) ->
	log_tbllog_equipment(PS#player.id, PS#player.account_name, PS#player.level, ItemId, ValueBefore, ValueAfter, ChangeType, Material, HappenedTime, LogTime).
log_tbllog_equipment(PlayerId, AccountName, DimLevel, ItemId, ValueBefore, ValueAfter, ChangeType, Material, HappenedTime, LogTime) ->
	db_agent_log:insert_tbllog_equipment(PlayerId, AccountName, DimLevel, ItemId, ValueBefore, ValueAfter, ChangeType, Material, HappenedTime, LogTime).

%% 货币变动日志
log_tbllog_gold(PS, MoneyType, Amount, Opt, Action1, Action2, ItemNumber, HappenedTime, LogTime) ->
	case MoneyType of
		?MONEY_T_GOLD -> MoneyRemain = PS#player.gold;
		?MONEY_T_BGOLD -> MoneyRemain = PS#player.bgold;
		?MONEY_T_COIN -> MoneyRemain = PS#player.coin;
		?MONEY_T_BCOIN -> MoneyRemain = PS#player.bcoin;
		_ -> MoneyRemain = 0
	end,  
	log_tbllog_gold(PS#player.id, PS#player.account_name, PS#player.level, PS#player.career, MoneyType, Amount, MoneyRemain, Opt, Action1, Action2, ItemNumber, HappenedTime, LogTime).
log_tbllog_gold(PlayerId, AccountName, DimLevel, DimProf, MoneyType, Amount, MoneyRemain, Opt, Action1, Action2, ItemNumber, HappenedTime, LogTime) ->
	db_agent_log:insert_tbllog_gold(PlayerId, AccountName, DimLevel, DimProf, MoneyType, Amount, MoneyRemain, Opt, Action1, Action2, ItemNumber, HappenedTime, LogTime).
