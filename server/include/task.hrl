%%%------------------------------------------------
%%% File    : task.hrl
%%% Author  : Johnathe_Yip
%%% Created : 2013-01-16
%%% Description: 任务定义 
%%%------------------------------------------------

%% 避免头文件多重包含
-ifndef(__HEADER_TASK_H__).
-define(__HEADER_TASK_H__, 0).
-include("debug.hrl").
%%-----------任务模块日志--------------
-undefine(task_debug).
%-define(task_debug,1).

-ifdef(task_debug).
	-define(TASK_TRACE(Str), ?TRACE(Str)).
    -define(TASK_TRACE(Str, Args), ?TRACE(Str, Args)).
-else.
	-define(TASK_TRACE(Str), void).
    -define(TASK_TRACE(Str, Args), void).
-endif. 

%%任务类别
-define(MAIN_TASK,0). %%主线任务
-define(BRANCHE_TASK,1). %%支线任务
-define(FACTION_TASK,2).%%帮派任务 --
-define(DREAMLAND_TASK,3).%%桃园任务 %%删除掉了
-define(GOD_COMMAND_TASK,4).%%天道令任务
-define(CAMP_TASK,5).%%阵营任务 --
-define(MINE_TASK,6).%%聚宝阁任务
-define(EXERCISE_TASK,7).%%千锤百炼任务
-define(SELF_IMPROVE_TASK,8).%%自强不息
-define(MASTER_TASK,9).%%师门任务
-define(ALL_TASK_TYPE,%%所有任务类型
		[?FACTION_TASK,?GOD_COMMAND_TASK,?CAMP_TASK,?MINE_TASK,?EXERCISE_TASK,?SELF_IMPROVE_TASK,?MASTER_TASK]).
-define(ALL_CAN_ACCEPT_TYPE,%%所有可接任务类型
		[?FACTION_TASK,?CAMP_TASK,?MINE_TASK,?EXERCISE_TASK,?SELF_IMPROVE_TASK]).

%%日常任务对应的npcID
-define(NPC_ID_OF_FACTION_TASK,10042).%%帮派任务
-define(NPC_ID_OF_DREAMLAND_TASK,3).%%桃园任务
-define(NPC_ID_OF_GOD_COMMAND_TASK,10031).%%天道令任务
-define(NPC_ID_OF_CAMP_TASK,10023).%%阵营任务
-define(NPC_ID_OF_MINE_TASK,10030).%%聚宝阁任务
-define(NPC_ID_OF_EXERCISE_TASK,10039).%%千锤百炼任务
-define(NPC_ID_OF_SELF_IMPROVE_TASK,10027).%%自强不息
-define(NPC_ID_OF_MASTER_TASK,10074).%%师门任务
-define(All_DAILY_NPC_ID_LIST, 
		[?NPC_ID_OF_FACTION_TASK, ?NPC_ID_OF_DREAMLAND_TASK,
		 ?NPC_ID_OF_GOD_COMMAND_TASK, ?NPC_ID_OF_CAMP_TASK,
		 ?NPC_ID_OF_MINE_TASK, ?NPC_ID_OF_EXERCISE_TASK,
		 ?NPC_ID_OF_SELF_IMPROVE_TASK, ?NPC_ID_OF_MASTER_TASK]).%%所有日常任务npcId

%%----------任务事件------------
-define(KILL_EVENT,1). 		%%杀怪事件类型
-define(COLLECT_EVENT,2). 	%%采集事件类型
-define(NPC_TALK_EVENT,0). 	%%npc对话事件类型

%%到达一定的等级(如10)
    %%target_type 设置为 4 
    %%target_property 设置为 [{Level}]  (其中Level表示等级,比如10)
-define(LEVEL_EVENT,4). 	

-define(SHOPPING_EVENT,3).	%%商城购物事件
-define(NPC_GOODS_EVENT,6).	%%npc购物

%%发布天道令任务
    %%target_type 设置为 7
    %%target_property 设置为 [{}]
-define(GOD_COMMAND_EVENT,7).

%%进入到达副本层数， 已废弃
%%target_type 设置为 8 
%%target_property 设置为 [{SId,FloorNum}] (SID表示副本场景id,FloorNum表示指定层数)
-define(SCENE_EVENT,8).	
-define(DUNGEON_EVENT,9).	%%进入副本事件

%%完成一定的充值金额(如100)
 %%target_type 设置为 10 
%%target_property 设置为 [{0,ChargeNum,0}] 
-define(CHARGE_EVENT,10).	

%%完成一定次数的副本 target_property -> [{306,5,0}]
%%target_type 设置为 11 
%%target_property 设置为 [{SId,Num,0}] (SID表示副本场景id,Num表示指定进入该副本次数)
-define(DUNGEON_FINISH_EVENT,11).  

%%探索地图
%%target_type 设置为 12 
%%target_property 设置为 [{}]
-define(FIND_MAP_EVENT,12). 



%%----------npc状态--------------
-define(NPC_NO_TASK,0).%%npc对于角色没有任何任务关联
-define(NPC_UNFIN_TASK,1).%%npc对于角色已触发任务，但没有完成
-define(NPC_CAN_TRIGGER,2).%%npc对于角色有可接任务
-define(NPC_FINISH_TASK,3).%%npc对于玩家有完成任务

%%----------任务模板-------
-define(TASK_AUTO_FIN_FLAG,0).%%任务自动完成标识
-define(TASK_AUTO_TRIG_FLAG,0).%%任务自动触发标识

%%----------任务奖励标识类型---------------
-define(NULL_TASK_FLAG,0).%%无标识类型
-define(CAREER_TASK_FLAG,1).%%职业标识类型

%%----------玩家职业---------
-define(NULL_CAREER,0).%无职业限制
-define(SOLDIER_CAREER,1).%%战士 
-define(MASTER_CAREER,2).%%法师
-define(SHOOTER_CAREER,3).%%射手

%%----------玩家性别限制-------
-define(NULL_SEX,2).%无性别限制
-define(BOY_SEX,1).%男
-define(GIRL_SEX,0).%女

%%----------日常任务状态-------
-define(CAN_TRIGGER,0).%%可触发
-define(CAN_NOT_TRIGGER,1).%%不可触发
-define(OUT_OF_MAX_TRIGGER_TIME,2).%%超过最大轮数
-define(OUT_OF_MAX_CYCLE_TIME,3).%%超过本轮最大次数
-define(OUT_OF_MAX_MEANW_TIME,4).%%超过同时触发任务数
-define(OUT_OF_TIME_LIMIT, 5). %%超出时间限制

-define(RESET_TIME,24*60*60).%%重置等待时间
-define(MIN_REFRESH_NEED_GOLD,5).%%元宝刷新最少需要的元宝个数
%%成功编码
-define(OPT_SUCCESS,100).%%操作成功 
%%错误编码 
-define(TASK_ALREADY_TRIGGER,102).%%该任务已经触发过了，不能接
-define(TASK_LEVEL_NOTENOUGHT, 103).%%任务等级不足
-define(TASK_ALREADY_FINISH,104).%%任务已完成
-define(TASK_NOT_EXIT,101).%%任务不存在
-define(TASK_WRONG_CAREER,105).%%不满足职业限定
-define(TASK_WRONG_SEX,106).%%不满足性别限定
-define(PRE_TASK_UNFIN,107).%%前置任务未完成
-define(DAILY_TASK_REJECT,108).%%不满足日常任务触发条件 
-define(TASK_TIME_LIMIT,109).%%任务不在可接时间段
-define(TASK_NOT_IN_PROCESS,201).%%任务不在进度列表
-define(TASK_UNFINISH,202).%%任务未完成
-define(TASK_NOT_TRIGGER,203).%%任务没有触发
-define(NO_TASK_IN_DETAIL,204).%%任务不在任务模板子表
-define(TASK_NOT_ENOUGH_COIN,205).%%完成任务所需元宝不足
-define(NOT_COIN_TASK,206).%%该任务不能用元宝完成
-define(UNKNOW_ERROR,207).%%未知错误
-define(GET_GOOD_FAIL,208).%%获取任务奖品失败
-define(FAIL_FOR_EXCEED_BAG_CELL,209).%%背包已满， 不能完成主线任务
-define(FAIL_FOR_OTHER,210).%%其他错误
-define(TASK_FINISH_BY_AUTO,211).%%任务自动完成

%%天道令开启等级
-define(TASK_HEAVEN_OPEN_LEVEL,32). %%发布

%%天道令返回错误码
-define(TASK_HEAVEN_NO_HEAVEN_RECEIVE,401).%%没有天道令任务可以领取
-define(TASK_HEAVEN_HAVE_NO_HEAVEN_ORDER,402).%%没有天道令物品
-define(TASK_HEAVEN_TIMES_LIMITED,403).%%次数限制
-define(TASK_HEAVEN_ALREADY_RECEIVED,404).%%已经领取天道令任务, 请完成天道令任务然后在领取
-define(TASK_HEAVEN_LEVEL_TOO_LOW,405).%%等级太低，不可以发布天道令

%%------------任务状态用于30501/30008协议----------------
-define(TASK_NOT_FINISH,0).%任务已触发未完成
-define(TASK_FINISH,1).%%任务已满足完成条件
-define(TASK_CAN_TRIGGER,2).%%任务可触发
-define(TASK_AUTO_TRIGGER,3).%%任务自动触发

%%师门令任务配置
-define(TASK_MASTER_CD_TIME,10).%%师门令刷新cd时间 60
%%天道令返回错误码
-define(TASK_MASTER_CD_ERROR,300).%%cd时间错误
-define(TASK_MASTER_NOT_IN_LIST,301).%%数据不在列表
-define(TASK_MASTER_ORDER_LESS,302).%%天道令数量少
-define(TASK_MASTER_GOLD_LESS,303).%%元宝数量少

%%任务默认等级
-define(TASK_COMMON_GRADE, 0).%%任务默认等级
%%-----------师门令任务品质---------------------
-define(TASK_MASTER_GRADE_WHITE, 1).%%白色
-define(TASK_MASTER_GRADE_GREEN, 2).%%绿色
-define(TASK_MASTER_GRADE_BLUE, 3).%%蓝色
-define(TASK_MASTER_GRADE_PURPLE, 4).%%紫色Purple
-define(TASK_MASTER_GRADE_ORANGE, 5).%%橙色Orange

%%-----------天道令任务品质---------------------
-define(TASK_HEAVEN_GRADE_TIAN, 1).%%天.天道令
-define(TASK_HEAVEN_GRADE_DI, 2).%%地.天道令
-define(TASK_HEAVEN_GRADE_XUAN, 3).%%玄.天道令
-define(TASK_HEAVEN_GRADE_HUANG, 4).%%黄.天道令

%%-----------全局天道令数据库id---------------------
-define(TASK_HEAVEN_ID_TIAN, 1).%%天.天道令id
-define(TASK_HEAVEN_ID_DI, 2).%%地.天道令id
-define(TASK_HEAVEN_ID_XUAN, 3).%%玄.天道令id
-define(TASK_HEAVEN_ID_HUANG, 4).%%黄.天道令id
-define(ALL_TASK_HEAVEN_IDS, [?TASK_HEAVEN_ID_TIAN, 
							  ?TASK_HEAVEN_ID_DI, 
							  ?TASK_HEAVEN_ID_XUAN, 
							  ?TASK_HEAVEN_ID_HUANG]).%%所有天道令id
-define(TASK_HEAVEN_UPDATA_DB_TIME, 30 * 60 * 1000).%%天道令任务同步更新时间间隔
%%-----------师门令任务状态-------------------
-define(TASK_MASTER_STATE_COMMON, 0).%%正常， 可以接
-define(TASK_MASTER_STATE_ACCEPTED, 1).%%已接任务

%%特殊物品id
%师门令物品id
-define(GOODS_ID_MASTER_ORDER, 382004205). %%师门令
-define(GOODS_ID_MASTER_ORDER_BIND, 383004205). %%绑定师门令
%%天道令相关物品id
-define(GOODS_ID_HEAVEN_ORDER_TIAN, 380014202). %%天·天道令
-define(GOODS_ID_HEAVEN_ORDER_TIAN_BIND, 381014202). %%天·天道令(绑)
-define(GOODS_ID_HEAVEN_ORDER_DI, 380024203). %%地·天道令
-define(GOODS_ID_HEAVEN_ORDER_DI_BIND, 381024203). %%地·天道令(绑)
-define(GOODS_ID_HEAVEN_ORDER_XUAN, 380034204). %%玄·天道令
-define(GOODS_ID_HEAVEN_ORDER_XUAN_BIND, 381034204). %%玄·天道令(绑)
-define(GOODS_ID_HEAVEN_ORDER_HUANG, 380044205). %%黄·天道令
-define(GOODS_ID_HEAVEN_ORDER_HUANG_BIND, 381044205). %%黄·天道令(绑)
-endif.   
 
