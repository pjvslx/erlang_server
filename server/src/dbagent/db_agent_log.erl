%% Author: Administrator
%% Created: 2013-3-6
%% Description: TODO: Add description to db_agent_log
-module(db_agent_log).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).


%----------------------
%-	数据库日志统一入口
%----------------------
write_insert_log(LogType,TableName,FieldList,ValueList)->
	Pid = mod_db_log:get_db_log_pid(),
	gen_server:cast(Pid, {do_log,insert,LogType,TableName,FieldList,ValueList}).

write_update_log(LogType,TableName,FieldList,ValueList)->
	Pid = mod_db_log:get_db_log_pid(),
	gen_server:cast(Pid, {do_log,update,LogType,TableName,FieldList,ValueList}).


%%mysql玩家日志记录
insert_log_player(Uid,Acid,Acnm,Nick,Sex,Crr) -> 

	write_insert_log(?DB_LOG_DELAY,log_create_role,[uid,acid,acnm,nick,sex,career], [Uid,Acid,Acnm,Nick,Sex,Crr]).
%	?DB_LOG_MODULE:insert(log_create_role,[uid,acid,acnm,nick,sex,career], [Uid,Acid,Acnm,Nick,Sex,Crr]).

%% 玩家登陆日志记录
insert_log_login(RoleId, AccountName, DimLevel, UserIp, LoginSceneId, Os, OsVersion, Device, DeviceType, Screen, Mno, Nm) ->
	Now = util:unixtime(),
	write_insert_log(?DB_LOG_DELAY,tbllog_login,
		[role_id, account_name, dim_level, user_ip, login_scene_id, os, os_version, device, device_type, screen, mno, nm, happend_time, log_time], 
		[RoleId, AccountName, DimLevel, UserIp, LoginSceneId, Os, OsVersion, Device, DeviceType, Screen, Mno, Nm, Now, Now]).

%% 玩家退出日志记录 
insert_log_quit(Ps) ->   
	Now = util:unixtime(),
	OsNum = Ps#player.other#player_other.hardware_info#hardware_info.os,
	Os = config:get_client_os(OsNum),
	OsVersion = Ps#player.other#player_other.hardware_info#hardware_info.os_version, 
	Device = Ps#player.other#player_other.hardware_info#hardware_info.device,
	DeviceTypeNum = Ps#player.other#player_other.hardware_info#hardware_info.device_type,
	DeviceType = config:get_client_device_type(DeviceTypeNum),
	Screen = Ps#player.other#player_other.hardware_info#hardware_info.screen,
	MnoNum = Ps#player.other#player_other.hardware_info#hardware_info.mno,
	Mno = config:get_client_isp(MnoNum),
	NmNum = Ps#player.other#player_other.hardware_info#hardware_info.nm, 
	Nm = config:get_client_net_type(NmNum),
	write_insert_log(?DB_LOG_DELAY,tbllog_quit,[uid,acnm,time_duration,reason_id,login_lv,logout_lv,login_ip,login_time,logout_time,     
											  logout_scene_id,msg,os,os_version,device,device_type,screen,mno,nm  ], 
					 [Ps#player.id, Ps#player.nick, (Now - Ps#player.last_login_time), 1,Ps#player.login_level,
					  Ps#player.level, Ps#player.last_login_ip,Ps#player.last_login_time,Now,Ps#player.scene,"",
					  Os,OsVersion,Device,DeviceType,Screen,Mno,Nm]).
	%?DB_LOG_MODULE:insert(log_quit,[uid, acnm, time_duration, reason_id], [Uid, Acnm, Time, ReasonId]).

%%创建角色日志
insert_log_create_role(RoleId, AccountName, DimProf, Os, OsVersion, Device, DeviceType, Screen, Mno, Nm) ->
	Now = util:unixtime(),
	write_insert_log(?DB_LOG_DELAY, tbllog_role, 
		[role_id, account_name, dim_prof, os, os_version, device, device_type, screen, mno, nm, happend_time, log_time],
		[RoleId, AccountName, DimProf, Os, OsVersion, Device, DeviceType, Screen, Mno, Nm, Now, Now]).

%% 在线人数日志
insert_log_online(OnlineNum) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_online Now:~p OnlineNum:~p ~n", [Now, OnlineNum]),
	write_insert_log(?DB_LOG_DELAY,tbllog_online,[log_time, num], [Now, OnlineNum]).
	%?DB_LOG_MODULE:insert(log_online,[log_time, num], [Now, OnlineNum]).

%% 等级日志
insert_log_level(RoleId, AccountName,CurrentLevel,LastExp,CurrentExp) ->
	Now = util:unixtime(), 
	write_insert_log(?DB_LOG_DELAY,tbllog_level_up,[role_id, account_name, last_level,current_level,last_exp,current_exp,happend_time],
					  [RoleId, AccountName,CurrentLevel-1,CurrentLevel,LastExp,CurrentExp,Now]).
	%?DB_LOG_MODULE:insert(log_level,[log_time, num, level], [Now, Num, Lv]).

insert_log_shop(PlayerId, AccName, Lv, Career, MoneyType, Amount, GoodsType, GoodsSubType, GoodsTid, GoodsNum) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_shop Now:~p~n", [Now]),
	write_insert_log(?DB_LOG_DELAY,tbllog_shop,
		[role_id,account_name,dim_level,dim_prof,money_type,amount,item_type_1,item_type_2,item_id,item_number,happend_time],
		[PlayerId,AccName,Lv,Career,MoneyType,Amount,GoodsType,GoodsSubType,GoodsTid,GoodsNum,Now]).

insert_log_sale(SaleId,PlayerId,GoodsId,MoneyType,Amount,GoodsNum,ActionId) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_sale Now:~p~n", [Now]),
	write_insert_log(?DB_LOG_DELAY,tbllog_sales,
		[sales_id,role_id,item_id,price_type,price_unit,item_number,action_id,happened_time],
		[SaleId,PlayerId,GoodsId,MoneyType,Amount,GoodsNum,ActionId,Now]).

insert_log_auction(AuctionId,PlayerId,AccoutName,GoodsId,GoodsNum,Cost) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_auction Now:~p~n", [Now]),
	write_insert_log(?DB_LOG_DELAY,tbllog_auction,
		[auction_id,role_id,account_name,opt_type_id,item_id,item_number,bid_price_list,happened_time],
		%%[AuctionId,PlayerId,AccoutName,1,GoodsId,GoodsNum,lists:concat("<gold:",Cost,">"),"",0,Now]).
	[AuctionId,PlayerId,AccoutName,1,GoodsId,GoodsNum,"<gold:"++util:term_to_string(Cost)++">",0,Now]).

insert_log_dungeon(DungeonId,PlayerId,AccoutName,PlayerLv,DungeonLv,DunStatus) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_dungeon Now:~p~n", [Now]),
	write_insert_log(?DB_LOG_DELAY,tbllog_fb,
		[fb_id,role_id,account_name,dim_level,fb_level,status,happened_time],
		[DungeonId,PlayerId,AccoutName,PlayerLv,DungeonLv,DunStatus,Now]).

insert_log_scene_online(SceneId,PlayerNum) ->
	Now = util:unixtime(),
	?INFO_MSG("insert_log_scene_online Now:~p~n", [Now]),
	write_insert_log(?DB_LOG_NORMAL,tbllog_scene_online,
		[scene_id,player_num,happened_time],
		[SceneId,PlayerNum,Now]).

%%获取玩家总的充值金额
get_log_charge(AccountId) ->
    TotalCharge = ?DB_LOG_MODULE:select_one(tbllog_pay, "sum(gold)", [{account_name, AccountId}]),
    if
        TotalCharge =:= undefined ->
            NewTotalCharge = 0;
        true ->
            NewTotalCharge = TotalCharge
    end,
    NewTotalCharge.

%% %% 创建角色后, 真正进入游戏, 写记录
%% log_real_play(Uid) ->
%% 	Now = util:unixtime(),
%% 	?DB_LOG_MODULE:insert(log_real_play, [pt,uid],[Now,Uid]).

%% %% 获取玩家的最后充值时间
%% get_last_pay_time(PlayerId) ->
%% 	?DB_LOG_MODULE:select_one(log_pay,"insert_time",[{player_id,PlayerId},{pay_status,1}],[{insert_time,desc}],[1]).

%% 玩家踢出日志
insert_kick_off_log(Uid, NickName, K_type, Now_time, Scene, X, Y, Other) ->
	?DB_LOG_MODULE:insert(log_kick_off, [uid, nick, k_type, time, scene, x, y, other], [Uid, NickName, K_type, Now_time, Scene, X, Y, Other]).



%% 铜钱消耗日志
insert_cost_coin(PlayerId, CostCoin, CostBCoin, CostType) ->
	?DB_LOG_MODULE:insert(log_cost_coin, [uid, coin, bcoin, cost_type], [PlayerId, CostCoin, CostBCoin, CostType]).

%% 元宝消耗日志
insert_cost_gold(PlayerId, CostGold, CostBGold, CostType) ->
	?DB_LOG_MODULE:insert(log_cost_gold, [uid, gold, bgold, cost_type], [PlayerId, CostGold, CostBGold, CostType]).

%% 物品消耗
insert_cost_goods(PlayerId, Gtid, GoodsNum, Bind, Source) ->
	?DB_LOG_MODULE:insert(log_cost_goods, [uid, gtid, num, bind, cost_type], [PlayerId, Gtid, GoodsNum, Bind, Source]).

%% 发放铜钱
insert_add_coin(PlayerId, Money, Source) ->
	?DB_LOG_MODULE:insert(log_add_coin, [uid, num, type, source], [PlayerId, Money, 1, Source]).

%% 发放绑定铜钱
insert_add_bcoin(PlayerId,Money, Source) ->
	?DB_LOG_MODULE:insert(log_add_coin, [uid, num, source], [PlayerId, Money, Source]).

%% 发放元宝
insert_add_gold(PlayerId,Money, Source) ->
	?DB_LOG_MODULE:insert(log_add_gold, [uid, num, type, source], [PlayerId, Money, 1, Source]).

%% 发放绑定元宝
insert_add_bgold(PlayerId,Money, Source) ->
	?DB_LOG_MODULE:insert(log_add_gold, [uid, num, source], [PlayerId, Money, Source]).

%% 发放物品
insert_add_goods(PlayerId, Gtid, GoodsNum, Bind, Source) ->
	?DB_LOG_MODULE:insert(log_add_goods, [uid, gtid, num, bind, add_type], [PlayerId, Gtid, GoodsNum, Bind, Source]).

%% 强化日志
add_stren_log(PlayerId, Gtid, OldStrenLv, OldStrenPerc, NewStrenLv, NewStrenPerc, Coin, Gold, CostGoodsTid) ->
	?DB_LOG_MODULE:insert(log_stren, [uid, gtid, old_stren, old_stren_percent, new_stren, new_stren_percent, coin, gold, cost_goods], 
						  [PlayerId, Gtid, OldStrenLv, OldStrenPerc, NewStrenLv, NewStrenPerc, Coin, Gold, CostGoodsTid]).
%% 宠物进阶  
add_pet_upgrade_quality_log(PlayerId, OldQualityLv, NewQualityLv, SuccRate, AddRate, CostGold, CostCoin, CostGoodsTid) ->
	?DB_LOG_MODULE:insert(log_pet_upgrade_quality, [uid, old_quality_lv, new_quality_lv, succ_rate, add_rate, gold, coin, cost_goods], 
						  [PlayerId, OldQualityLv, NewQualityLv, SuccRate, AddRate, CostGold, CostCoin, CostGoodsTid]).

%% 宠物进化
add_pet_evolve_log(PlayerId, GrowthLv, GrowthProgress, NewGrowthLv, NewGrowthProgress, CostCoin, CostGold, CostGoodsTid) ->
	?DB_LOG_MODULE:insert(log_pet_evolve, [uid, old_growth_lv, new_growth_lv, old_growth_progress, new_growth_progress, gold, coin, cost_goods], 
						  [PlayerId, GrowthLv, NewGrowthLv, GrowthProgress, NewGrowthProgress, CostGold, CostCoin, CostGoodsTid]).

%% 宠物提升
add_pet_upgrade_log(PlayerId, AptitudeLv, AptitudeProgress, NewAptitudeLv, NewAptitudeProgress, CostCoin, CostGold, CostGoodsTid) ->
	?DB_LOG_MODULE:insert(log_pet_upgrade, [uid, old_aptitude_lv, new_aptitude_lv, old_aptitude_progress, new_aptitude_progress, gold, coin, cost_goods], 
						  [PlayerId, AptitudeLv, NewAptitudeLv, AptitudeProgress, NewAptitudeProgress, CostCoin, CostGold, CostGoodsTid]).
%% 副本日志
add_dungeon_log(UId,Did,Gid,BeginTime,EndTime,LeftTimes,Assess) ->
	FieldList = [uid,sid,gid,enter_time,end_time,left_times,assess] ,
	ValueList = [UId,Did,Gid,BeginTime,EndTime,LeftTimes,Assess] ,
	?DB_LOG_MODULE:insert(log_dungeon, FieldList, ValueList).

%% 修改领取通关奖励
update_dungeon_log(UId,BeginTime,RewardList) ->
	NowTime = util:unixtime() ,
	?DB_LOG_MODULE:update(log_dungeon,[{rewards,util:term_to_string(RewardList)},{reward_time,NowTime}],[{uid,UId},{enter_time,BeginTime}]) .

%% 任务日志
add_task_log(PlayerId, Acnm, Career, Level,TaskId, TaskStatus,Happend_time) ->
    write_insert_log(
        ?DB_LOG_DELAY,
        tbllog_task,
        [role_id, account_name, dim_prof, dim_level, task_id, status, happend_time],
        [PlayerId, Acnm, Career, Level, TaskId,TaskStatus,Happend_time]
    ).
	%%?DB_LOG_MODULE:insert(tbllog_task, [role_id, account_name, dim_prof, dim_level, task_id, status, happend_time],[PlayerId, Acnm, Career, Level, TaskId,TaskStatus,Happend_time]).

%% 玩家奖励经验记录
insert_add_exp(PlayerId, Num, Source, ObjId) ->
	?DB_LOG_MODULE:insert(log_add_exp, [uid, num, source, obj_id], [PlayerId, Num, Source, ObjId]).

%% 通过玩家Id和副本组Id获取副本组次数情况
get_dungeon_group_num(PlayerId,DGroupId) ->
    TotalData = ?DB_LOG_MODULE:select_all(log_dungeon,"*", [{uid,PlayerId},{gid,DGroupId}]),
    length(TotalData).

%% 道具产出/消耗日志
insert_tbllog_items(PlayerId,AccountName,DimLevel,Opt,ActionId,ItemId,ItemNumber,MapId,HappenedTime,LogTime) ->
	write_insert_log(
        ?DB_LOG_NORMAL,
        tbllog_items,
        [role_id,account_name,dim_level,opt,action_id,item_id,item_number,map_id,happend_time,log_time],
        [PlayerId,AccountName,DimLevel,Opt,ActionId,ItemId,ItemNumber,MapId,HappenedTime,LogTime]
    ).

%% 装备锻造、洗练、合成日志
insert_tbllog_equipment(PlayerId,AccountName,DimLevel,ItemId,ValueBefore,ValueAfter,ChangeType,Material,HappenedTime,LogTime) ->
	write_insert_log(
        ?DB_LOG_NORMAL,
        tbllog_equipment,
        [role_id,account_name,dim_level,item_id,value_before,value_after,change_type,material,happend_time,log_time],
        [PlayerId,AccountName,DimLevel,ItemId,ValueBefore,ValueAfter,ChangeType,Material,HappenedTime,LogTime]
    ).

%% 货币变动日志
insert_tbllog_gold(PlayerId,AccountName,DimLevel,DimProf,MoneyType,Amount,MoneyRemain,Opt,Action1,Action2,ItemNumber,HappenedTime,LogTime) ->
	write_insert_log(
        ?DB_LOG_NORMAL,
        tbllog_gold,
        [role_id,account_name,dim_level,dim_prof,money_type,amount,money_remain,opt,action_1,action_2,item_number,happend_time,log_time],
        [PlayerId,AccountName,DimLevel,DimProf,MoneyType,Amount,MoneyRemain,Opt,Action1,Action2,ItemNumber,HappenedTime,LogTime]
    ).

%% 充值日志
insert_charge_log(RoleId, AccountName, DimLevel, Gold, PayType, OrderId, PayMoney, HappendTime) ->
	Now = util:unixtime(),
	write_insert_log(?DB_LOG_NORMAL, 
		tbllog_pay,
		[role_id, account_name, dim_level, gold, pay_type, order_id, pay_money, happend_time, log_time],
		[RoleId, AccountName, DimLevel, Gold, PayType, OrderId, PayMoney, HappendTime, Now]).

%% 邮件流水日志
insert_mail_log(MailSenderId,MailSenderName,MailRecvId,MailRecvName,MailTitle,MailContent,MailType,MailMoneyList,MailItemList,MailStatus) ->
	%%write_insert_log(?DB_LOG_DELAY,log_online,[log_time, num], [Now, OnlineNum]).
	Now = util:unixtime(),
	write_insert_log(?DB_LOG_DELAY,tbllog_mail, 
					 [mail_sender_id,
					  mail_sender_name,
					  mail_receiver_id,
					  mail_receiver_name,
					  mail_title,
					  mail_content,
					  mail_type,
					  mail_money_list,
					  mail_item_list,
					  mail_status,
					  happend_time,
					  log_time],
					 [MailSenderId,MailSenderName,MailRecvId,MailRecvName,MailTitle,MailContent,MailType,MailMoneyList,MailItemList,MailStatus,Now,Now]).
