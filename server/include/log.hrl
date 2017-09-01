-ifndef(__LOG__).
-define(__LOG__, log).

-define(LOCAL_LOG_PROC, local_log_proc).            %% 全局日志进程

%---------------------------------------------------------
%生成规范
%　　最后为了方便维护与扩展，我这里提供一套log.hrl宏数字码的生成规范
%　　1. 所有数字吗都必须由6位数字组成　　
%　　2. 数字码前两位必须是对应模块协议的前两位，例如这个宏对应的是物品模块，
%而物品模块对应的协议号是16，所以改宏应改成
%-define(LOG_EQUIP_UPG, 16xxxx).		%装备升级
%   3. 我们定数字码时，必须在第3位与第4位体现其类型，
%　　关于用户字典的宏暂分以下几种：
%其他类（编号为0），物品类（编号为1），任务类（编号为2），宠物类（编号为3），
%商城类（编号为4），场景类（编号为5），副本类（编号为6），装备类（编号为7），邮件类（编号为8），
%帮派类（编号为9），经脉（编号为10），技能类（编号为11），好友（编号为12），排行榜（编号为13），
%充值（编号为14）,坐骑类（编号为15）
%基于这个约定上面第2点的宏 
%  -define(LOG_EQUIP_UPG, 16xxxx).		%装备升级 
%  修改成
%  -define(LOG_EQUIP_UPG, 1607xx).		%装备升级
%----------------------------------------------------------

%---------------------
%-	暂不用
%---------------------
-define(LOG_COMPOSE, 2012).			%宝石合成
-define(LOG_INLAY, 2013).			%宝石镶嵌
-define(LOG_BACLOUT, 2014).			%宝石拆除
-define(LOG_GODTRIED, 2015).		%宝石神炼
-define(LOG_GILING, 2009).			%镀金 
-define(LOG_EQUIP_UPG, 2016).		%装备升级
-define(LOG_PRODUCE_COMPOSE, 2019).	%生产合成
-define(LOG_MAIL_GOODS, 3).				%邮寄物品
-define(LOG_INLAY_GOODS, 6).			% 镶嵌宝石 
-define(LOG_UPG_GOODS, 10).				%装备升级
-define(LOG_GILING_GOODS, 9).			% 镀金
-define(LOG_GODTRIED_GOODS, 12).		%宝石神炼 
-define(LOG_GOODS_TREA_REFRESH, 1).		%淘宝刷新物品 
-define(LOG_MAIL_FEE, 190801).		%邮件手续费 
-define(LOG_MAIL_COIN, 190802).		%邮件寄送

-define(LOG_TASK_GOLD, 300201).		%任务系统的元宝花费

%%货币流通记录
%元宝类
-define(EXPAND_PACK, 1001).  % 扩展背包

-define(CANCEL_COOL_DOWN, 1005).	%消除CD时间
-define(LOG_TREASURE_CURRENCY, 1006).	%%寻灵
-define(LOG_OPEN_REMOTE_SHOP, 1012).	%打开远程道具店


%金钱类

-define(LOG_STREN, 150701).			%强化
-define(LOG_POLISH, 150702).			%洗练
-define(LOG_MARKET_FEE, 410401).		%拍卖手续费 
-define(LOG_MARKET_BUY, 410402).		%拍卖行购买 
-define(LOG_MARKET_SELL_MONEY, 410403).%拍卖行挂售货币
-define(LOG_CREATE_GUILD_FEE, 400901).%创建帮派费
-define(LOG_AUTO_FINISH_TASK,300202). %消耗元宝自动完成任务
-define(LOG_MONEY_MASTER_REFRESH,3002003). %%天道令刷新
-define(LOG_BUY_NPC_GOODS, 150101).	%购买NPC商店物品
-define(LOG_SHOP_BUY, 150402).		%购买商城物品
-define(LOG_MOUNT_SKILL, 441501).    %座骑技能
-define(LOG_MOUNT_STAR, 441502).    %座骑升星
-define(LOG_MOUNT_LEVEL, 441503).    %座骑升阶  
-define(LOG_MERIDIAN_COST,451001). %%经脉提升  
-define(LOG_SKILL_CLEAN,211101).     %%重置技能点
-define(LOG_PET_EVOLVE_COST,250301). %%宠物成长
-define(LOG_PET_UPGRADE_COST,250302). %%宠物提升
-define(LOG_PET_QUALITY_COST,250303). %%宠物进阶
-define(LOG_MONEY_GM, 110001).		%%GM指令		


%% 物品消耗类型操作日志
-define(LOG_USE_GOODS, 150102).				%使用物品
-define(LOG_ABANDON_GOODS, 150103).			%丢弃物品

-define(LOG_MARKET_GOODS, 150104).			%挂售物品
-define(LOG_SELL_GOODS, 150105).			%出售物品

-define(LOG_POLISH_GOODS, 150702).			% 洗练消耗
-define(LOG_STREN_GOODS, 150701).			% 强化消耗
-define(LOG_COMPOSE_GOODS, 150703).			%宝石合成
-define(LOG_EXCHANGE_GOODS, 150106).		%npc商店兑换

-define(LOG_PET_EVOLVE_GOODS, 250304).      %宠物进化
-define(LOG_PET_UPGRADE_GOODS, 250302).     %宠物提升
-define(LOG_PET_QUALITY_GOODS, 250303).     %宠物进阶
-define(LOG_PET_LEARN_SKILL, 250305).		%宠物学习技能

-define(LOG_FLY_GOODS, 150501).     	%筋斗云
-define(LOG_RELA_SEND_FLOWER,141201).   %好友赠送鲜花

-define(LOG_MASTER_TASK,300204).   %师门任务消耗
-define(LOG_HEAVEN_TASK,300203).   %天道令任务消耗
-define(LOG_MERIDIAN_SPEED_UP,451002). %经脉加速卡
-define(LOG_GUILD_CONTRIBUTION,400902). %帮派贡献
-define(LOG_MOUNT_FASHION,441504).	%坐骑幻化卡

%%物品来源操作
-define(LOG_GOODS_SHOP_BUY, 150402).	%商城购买物品
-define(LOG_GOODS_SELL, 150105).				%售卖物品
-define(LOG_GOODS_MAIL, 190803).             %邮件系统发放奖品
-define(LOG_GOODS_NPCSHOP_BUY, 150402).		%npc商店购买物品
-define(LOG_ADORE_PLAYER, 501301).			%玩家崇拜

-define(LOG_MONEY_CHARGE, 151401).			% 充值

-define(LOG_GOODS_TASK, 3002005).     % 任务奖励
-define(LOG_GOODS_MON, 120501).     % 打怪掉落

-define(DIC_TASKS_LOG, dic_tasks_log). 					%% 任务日志字典
-define(DIC_COMPOSE_LOG, dic_compose_log). 				%% 合成日志字典
-define(DIC_STRENGTH_LOG, dic_strength_log). 			%% 强化日志字典
-define(DIC_ENCHASE_LOG, dic_enchase_log).				%% 镶嵌/摘取日志字典
-define(DIC_REBUILD_LOG, dic_rebuild_log).				%% 洗练日志字典
-define(DIC_PK_LOG, dic_pk_log).						%% PK日志字典
-define(DIC_CONSUME_YUANBAO_LOG, dic_consume_log).		%% 元宝行为日志日志字典
-define(DIC_TRADE_LOG, dic_trade_log).					%% 交易日志
-define(DIC_ITEM_LOG, dic_item_log).					%% 物品消耗/产出日志

%% 装备锻造、洗练、合成日志(tbllog_equipment)
-define(LOG_EQUIPMENT_CHANGE_TYPE_STRENGTH,  	1). 	%%强化
-define(LOG_EQUIPMENT_CHANGE_TYPE_POLISH, 		2).		%%洗炼 
-define(LOG_EQUIPMENT_CHANGE_TYPE_GILD,  	 	3). 	%%镀金

  %% 道具产出/消耗日志
-define(LOG_ITEMS_OPT_CONSUME, 0).		%% 消耗道具
-define(LOG_ITEMS_OPT_OBTAIN,  1).		%% 获得道具

%% 货币变动日志
-define(LOG_GOLD_OPT_SUB, 0).	%%减少
-define(LOG_GOLD_OPT_ADD, 1).	%%增加

-endif.
