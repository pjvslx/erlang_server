%%%------------------------------------------------
%%% File    : common.hrl
%%% Author  : csj
%%% Created : 2010-09-15
%%% Description: 公共定义
%%%------------------------------------------------
-define(ALL_SERVER_PLAYERS, 100000).

%%-define(SLICEWIDTH, 25).
%%-define(SLICEHEIGHT, 15).
-define(SLICEWIDTH, 15).
-define(SLICEHEIGHT, 9).
-define(SOLUT_X,30) .  				%% 默认手机分表率X
-define(SOLUT_Y,20) .				%% 默认手机分表率Y

%%数据库模块选择 (db_mysql 或 db_mongo)
-define(DB_MODULE, db_mysql).            
%%数据库模块(日志数据库)
-define(DB_LOG_MODULE, db_mysql_admin).

-define(DB_SERVER, mysql_dispatcher).            
%%数据库模块(日志数据库)
-define(DB_SERVER_ADMIN, mysql_admin_dispatcher).

-define(DB_LOG_DELAY,1). %延迟写日志（批量写,已做优化）
-define(DB_LOG_NORMAL,0).%普通方式写数据库 （立即写）

%%mongo主数据库链接池
-define(MASTER_POOLID,master_mongo).
%%mongo从数据库链接池
-define(SLAVE_POOLID,slave_mongo).

%%Mysql数据库连接 
-define(DB_POOL, mysql_conn). 

%%消息头长度
-define(HEADER_LENGTH, 4).               %%消息头长度 2Byte 长度 + 2Byte 消息编号

%% 心跳包时间间隔
-define(HEART_TIMEOUT, 5*60*1000).    %%心跳包超时时间
%% 最大心跳包检测失败次数
-define(HEART_TIMEOUT_TIME, 2).      %%心跳包超时次数
-define(TCP_TIMEOUT, 1000).      % 解析协议超时时间

%% 每个场景的工作进程数
-define(SCENE_WORKER_NUMBER, 5).

%% 代理进程数
-define(SCENE_AGENT_NUMBER, 30).

%% 每个场景的最多容纳人数
-define(SCENE_PLAYER_MAX_NUMBER, 50).
%% 最大分场景数
-define(SCENE_MAX_NUMBER, 70).

-define(GRID_CANGO,1).			% 可走格子
-define(GRID_SHADE,2).			% 阴影格子
-define(GRID_BLOCK,3).			% 障碍格子
-define(ETS_SCENE_MAP_INFO,ets_map_info). %地图信息表
%%安全校验
-define(TICKET, "SDFSDESF123DFSDF"). 

%%tcp_server监听参数
-define(TCP_OPTIONS, [binary, {packet, 0}, {active, false}, {reuseaddr, true}, {nodelay, false}, {delay_send, true}, {send_timeout, 5000}, {keepalive, true}, {exit_on_close, true}]).
-define(RECV_TIMEOUT, 5000).

%%出师等级限制 
-define(FINISHED_MASTER_LV,35).
%%徒弟未汇报时间
-define(UNREPORT_DAYS,3).
%%师傅未登陆时间
-define(UNLOGIN_DAYS,3).
  
%%人物和宠物死亡后的最低血量
-define(LIMIT_HP, 10).

%%自然对数的底
-define(E, 2.718281828459).

%% ---------------------------------
%% Logging mechanism
%% Print in standard output
-define(PRINT(Format, Args),
    io:format(Format, Args)).
-define(TEST_MSG(Format, Args),
    logger:test_msg(?MODULE,?LINE,Format, Args)).
-define(DEBUG(Format, Args),
    logger:debug_msg(?MODULE,?LINE,Format, Args)).
-define(INFO_MSG(Format, Args),
    logger:info_msg(?MODULE,?LINE,Format, Args)).
-define(WARNING_MSG(Format, Args),
    logger:warning_msg(?MODULE,?LINE,Format, Args)).
-define(ERROR_MSG(Format, Args),
    logger:error_msg(?MODULE,?LINE,Format, Args)).
-define(CRITICAL_MSG(Format, Args),
    logger:critical_msg(?MODULE,?LINE,Format, Args)).

%% log event manager name
-define(LOGMODULE, logger_mgr).

-define(INIT_SCENE_ID, 101).      %%新手村
-define(INIT_SCENE_XY, {10,10}).  %%新建帐号位置

%性别
-define(GENDER_ANY, 0).  
-define(GENDER_MALE,1).
-define(GENDER_FEMALE, 2).

%%玩家状态  
-define(PLAYER_NORMAL_STATE,0). %%正常
-define(PLAYER_BATTLE_STATE,1). %%战斗 


%职业
-define(CAREER_F, 1). 	%战士
-define(CAREER_M, 2). 	%法师
-define(CAREER_D, 3). 	%射手
-define(CAREER_ANY, 4). %各职业通用
-define(CAREER_PET, 5). 	%宠物
-define(CAREER_MOUNT, 6). 	%战骑

%% 性别
-define(SEX_ANY,    0).    % 男女通用
-define(SEX_MALE,   1).    % 男
-define(SEX_FEMALE, 2).    % 女

%VIP类型定义
-define(VIP_NOT, 0).  %不是VIP
-define(VIP_EXPERIENCE, 1).  %VIP钟点卡(试用装)
-define(VIP_DAY, 11).  %VIP日卡
-define(VIP_WEEK, 12). %VIP周卡
-define(VIP_MONTH, 13).  %VIP月卡
-define(VIP_HALF_YEAR, 21).  %VIP半年卡
-define(VIP_YEAR, 22).       %VIP年卡
-define(VIP_FOREVER, 99).    %VIP终身卡

-define(ELEMENT_PLAYER, 1).  %% 玩家
-define(ELEMENT_MONSTER, 2).  %% 怪物
-define(ELEMENT_ALL, 3).  %% 玩家,怪物
-define(ELEMENT_PET, 4).  %% 宠物

-define(EXP_DUNGEON,399).

%% 攻击目标类型
-define(DEST_SINGLE, 0).   		% 单体攻击
-define(DEST_ATTACK, 1).     	% 自身为中心
-define(DEST_DEFEND, 2).    	% 目标为中心
-define(DEST_GROUND,  3).   	% 地面为中心


%%打开发送消息客户端进程数量 
-define(SEND_MSG, 1).

%%player.switch开关位定义(32位)
-define(SW_PET_BIT,      16#00000001).  %宠物
-define(SW_MOUNT_BIT,    16#00000002).  %座骑
-define(SW_GUILD_BIT,    16#00000004).  %帮派  
-define(SW_RELATION_BIT, 16#00000000).  %关系 16#00000008
-define(SW_SKILL_BIT,    16#00000010).  %技能   
-define(SW_CAMP_BIT, 	 16#00000020).	%阵营 
-define(SW_MER_BIT, 	 16#00000040).  %经脉

-define(SW_BIT7, 16#00000080).

-define(SW_BIT8,  16#00000100).
-define(SW_BIT9,  16#00000200).
-define(SW_BIT10, 16#00000400).
-define(SW_BIT11, 16#00000800).

-define(SW_BIT12, 16#00001000).
-define(SW_BIT13, 16#00002000).
-define(SW_BIT14, 16#00004000).
-define(SW_BIT15, 16#00008000).

-define(SW_BIT16, 16#00010000).
-define(SW_BIT17, 16#00020000).
-define(SW_BIT18, 16#00040000).
-define(SW_BIT19, 16#00080000).

-define(SW_BIT20, 16#00100000).
-define(SW_BIT21, 16#00200000).
-define(SW_BIT22, 16#00400000).  
-define(SW_BIT23, 16#00800000).

-define(SW_BIT24, 16#01000000).
-define(SW_BIT25, 16#02000000).
-define(SW_BIT26, 16#04000000).
-define(SW_BIT27, 16#08000000).

-define(SW_BIT28, 16#10000000).
-define(SW_BIT29, 16#20000000).
-define(SW_BIT30, 16#40000000).
-define(SW_BIT31, 16#80000000).

%% 联盟进程的工作进程数
-define(MON_LIMIT_NUM, 100000000).                                %% 怪物数量限制数
-define(DIFF_SECONDS_1970_1900, 2208988800).
-define(DIFF_SECONDS_0000_1900, 62167219200).
-define(ONE_DAY_SECONDS,        86400).                    %%一天的时间（秒）
-define(ONE_DAY_MILLISECONDS, 86400000).                %%一天时间（毫秒）

-define(COMMON_ATTR_SPEED,1200).		%默认攻速
-define(COMMON_MOVE_SPEED,7).   		%默认移动速度
-define(COMMON_MOVE_PATROL,3).   		%默认巡逻速度
-define(COMMON_MOVE_SURROUND,3).   		%默认漫游速度

-define(DEFAULT_NAME, "匿名") .    
%%ETS
-define(ETS_SERVER, ets_server).
-define(ETS_GET_SERVER,ets_get_server).
-define(ETS_GET_SCENE,ets_get_scene).
-define(ETS_SYSTEM_INFO,  ets_system_info).                        %% 系统配置信息
-define(ETS_MONITOR_PID,  ets_monitor_pid).                        %% 记录监控的PID
-define(ETS_STAT_SOCKET, ets_stat_socket).                        %% Socket送出数据统计(协议号，次数)
-define(ETS_STAT_DB, ets_stat_db).                                %% 数据库访问统计(表名，操作，次数)
-define(ETS_SYS_ANNONUCE,sys_announce) .
%% -define(ETS_BASE_MON, ets_base_mon).                            %% 基础_怪物信息
%% -define(ETS_MONGROUP, ets_mongroup).                            %% 基础_怪物信息  

-define(ETS_NPC, temp_npc).                                     %% 基础_NPC/怪物信息
-define(ETS_TEMP_SCENE, temp_scene).                            %% 基础_场景信息
-define(ETS_SCENE, ets_scene).                                    %% 本节点场景实例
-define(ETS_NPC_LAYOUT, npc_layout).                            %% 实例-场景NPC布局
-define(ETS_TEMP_MON_LAYOUT, temp_mon_layout).                    %% 基础_场景怪物布局
-define(SECNE_MON, scene_mon).                                    %% 场景中怪物保存，可以用作ETS，可以用这dict key
-define(SECNE_DROP, scene_drop).                                    %% 场景中怪物怪物掉落
-define(MON_STATE_TIMER_KEY, mon_state_timer_key).               %% 怪物状态的TimerKey
-define(DUNGEON_MON_STATE_TIMER_KEY, dungeon_mon_state_timer_key).               %% 怪物状态的TimerKey

-define(ETS_TEMP_GUILD_LEVEL,temp_guild_level).              %%帮派等级配置

-define(MON_STATE_SPEED_7,143).								%% 怪物状态管理 143 毫秒一轮询,每一秒7步
-define(MON_STATE_SPEED_BIAS_7,202).						%% 怪物状态管理 202 毫秒一轮询,每一秒7步（斜线）
-define(MON_STATE_SPEED_3,333).								%% 怪物状态管理 333 毫秒一轮询,每一秒3步
-define(MON_STATE_SPEED_BIAS_3,470).						%% 怪物状态管理 470 毫秒一轮询,每一秒3步（斜线）

-define(BUFF_TIMER_TIME,200).  %buff技能计时器刷新时间
-define(SKILL_TIMER_KEY,skill_timer_key).			        %% 技能状态的TimerKey

-define(MON_STATE_1_GUARD,	1) .
-define(MON_STATE_2_TRYATT,	2) .
-define(MON_STATE_3_MOVE,	3) .
-define(MON_STATE_4_FIGHT,	4) .
-define(MON_STATE_5_RETURN,	5) .
-define(MON_STATE_6_DEAD,	6) .
-define(MON_STATE_7_CHANT,	7) . 
-define(PLAYER_STATE_TIMER_KEY, player_state_timer_key).               %% 玩家状态的TimerKey
-define(PLAYER_STATE_LOOP_TIME,500).								%% 玩家状态管理 500 毫秒先
-define(MON_SKILL_TIMER_LIST,mon_skill_timer_list).			        %% 怪物技能状态的列表
-define(MON_SKILL_TIMER_LOOP_TIME,250).								%% 怪物技能管理 250 毫秒先

-define(ETS_ONLINE, ets_online).                                %% 本节点在线玩家
-define(ETS_ONLINE_SCENE, ets_online_scene).                    %% 本节点场景中玩家
  

%% -define(ETS_BASE_SCENE_POSES, ets_base_scene_poses).            %% 基本_场景坐标表
-define(ETS_BASE_SCENE_MON, ets_base_scene_mon).                %% 基础_场景怪物信息
-define(ETS_BASE_SCENE_NPC, ets_base_scene_npc).                %% 基础_场景NPC信息


-define(ETS_SCENE_MON, ets_mon).                                %% 本节点场景中怪物
-define(ETS_SCENE_NPC, ets_npc).                                %% 本节点场景中NPC
-define(ETS_DUNGEON_DAILY, dungeon_daily).                      %% 玩家每日副本记录
-define(ETS_DUNGEON_FINISH, dungeon_finish).                    %% 玩家已经完成的副本记录
-define(ETS_DUNGEON_MASTER, dungeon_master).                    %% 玩家已经完成的副本记录

-define(ETS_OPERA, opera).                    %% 玩家已经完成的副本记录
-define(ETS_SCENE_GIFT, scene_gift).                    %% 玩家已经领取过的场景礼包

-define(ETS_BLACKLIST,ets_blacklist).                           %% 黑名单记录表  

-define(ETS_GOODS_ONLINE, ets_goods_online).                    %% 在线物品表
-define(ETS_GOODS_EQUIP, ets_goods_equip).                      %% 装备物品类型表

-define(ETS_GUILD,        ets_guild). 						     %% 联盟
-define(ETS_GUILD_MEMBER, ets_guild_member).                    %% 联盟成员
-define(ETS_GUILD_APPLY,  ets_guild_apply).                     %% 联盟申请
-define(ETS_GUILD_INVITE, ets_guild_invite).                    %% 联盟邀请

-define(ETS_MOUNT, ets_mount).                                  %%座骑ETS表名
-define(ETS_ACTIVITY, ets_activity).							%%活跃度
-define(ETS_CONTACT, ets_contact).
-define(ETS_RELATION, ets_relation).                            %%关系ETS表名
-define(ETS_RELATION_AGENT,ets_relation_agent).                 %%玩家关系代理进程ets
-define(ETS_TEAM, ets_team).                                    %%队伍表ETS
-define(ETS_TEAM_MEMBER, ets_team_member).                      %%队伍成员表ETS

-define(ETS_TEMP_SHOP, ets_temp_shop).							%% 商城模版表				
-define(ETS_SHOP_LOG, ets_shop_log).							%% 商城购买物品记录
-define(ETS_NPC_SHOP_LOG, ets_npc_shop_log).					%% npc商店购买物品记录
-define(ETS_RAND_SHOP, rand_shop).							%% 随机商城记录

-define(ETS_TPL_TASK, tpl_task).                              %%角色任务模板
%-define(ETS_TASK_DAILY_FINISH, ets_task_daily_finish).	%%日常任务完成进度
-define(ETS_TASK_PROCESS,  task_process). 							%% 角色任务记录
-define(ETS_TASK_FINISH, task_finish).							%% 角色任务历史记录  
-define(ETS_TASK_QUERY_CACHE, ets_task_query_cache).    	 	%% 当前所有可接任务
-define(ETS_TASK_DETAIL, ets_task_datil).						%%任务模板子表
-define(ETS_TASK_MASTER,task_master).%玩家师门令，刷新列表
-define(ETS_HEAVEN,heaven).%天道令数据
-define(ETS_TASK_HEAVEN, task_heaven).%玩家天道数据记录表
-define(ETS_TASK_DAILY, task_daily).%日常任务统计表 
-define(ETS_MOUNT_LEVEL_STAR,ets_mount_lv_star).%%坐骑星阶外观绑定表

%新手引导
-define(ETS_LEADER,ets_newbie_leader).%玩家新手引导记录表
-define(ONE_DAY_MSECONDS, (24 * 60 * 60 * 1000)).  % 一天的毫秒数

-define(ONE_HOUR_SECONDS, (60 * 60)).   % 一小时的秒数
-define(ONE_HOUR_MSECONDS, (60 * 60 * 1000)).   % 一小时的毫秒数

-define(ONE_MINUTE_SECONDS, 60).   % 一分钟的秒数
-define(ONE_MINUTE_MSECONDS, (60 * 1000)).   % 一分钟的毫秒数


-define(START_NOW, {-1, 0, 0}).   %% {-1, 0, 0}:表示从当前时间开始 
-define(START_TOMORROW, {-2, 0, 0}).   %% {-2, 0, 0}:表示从每日零点开始

%% 通知客户端刷新
-define(REFRESH_ROLE_ATTRI, 1).   %刷新人物属性
-define(REFRESH_BAG, 2).   %刷新背包
-define(REFRESH_P_EQUIP, 3).   %武将装备
-define(REFRESH_MONEY, 4).   %刷新三种货币
-define(REFRESH_GOODS_INFO, 5).   %刷新物品信息
-define(REFRESH_R_EQUIP, 6).   %玩家装备
-define(REFRESH_ROLE_POWER, 7).   %刷新人物体力条
-define(REFRESH_ROLE_HP, 8).   %刷新人物血条
-define(REFRESH_PAR_ATTRI, 9).   %刷新武将属性
-define(REFRESH_PAR_HP, 10).   %刷新武将血条
-define(REFRESH_STORE, 11).   %刷新仓库
-define(REFRESH_TREA, 12).   %刷新淘宝仓库
-define(REFRESH_DAN, 13).   % 刷新丹药仓库

%% 角色战斗力的调节参数
%-define(ROLE_BATTLE_CAPACITY_CONTROLLED_PARA, -242).
-define(HURT_CALL_BACK,0).	   	   %玩家受到伤害后 触发反伤技能
-define(HURT_NOT_CALL_BACK,1).	   %玩家受到伤害后不触发反伤技能
 
%% 体力的增减
-define(PLAYER_POWER_LIMIT, 200).   % 玩家体力值上限(固定值)
-define(ADD_POWER_PER_30_MIN, 5).   % (自动回复)体力增加
-define(POWER_INCREASE, 40).   % (购买)体力增加
-define(POWER_DECREASE, 20).   % (关卡)体力消耗
-define(POWER_BUFF, 50).   % (体力buff)12、18点系统赠予50点体力buff
-define(COST_BUY_POWER, 20).   % 购买体力固定花费的元宝


%% 背包、仓库默认格子数
-define(DEFAUL_BAG_CELL, 36*2).
-define(DEFAULT_STORE_CELL, 24).

%% VIP等级
-define(VIP_LV_0, 0).   % 0级，表示不是vip
-define(VIP_LV_1, 1).   % 体验vip
-define(VIP_LV_2, 2).   % 日vip
-define(VIP_LV_3, 3).   % 周vip
-define(VIP_LV_4, 4).   % 月vip
-define(VIP_LV_5, 5).   % 半年vip
-define(VIP_LV_6, 6).   % 至尊vip

-define(VIP_TITLE_CHG_MAX_TIMES, 3).   % vip称号最多只能修改3次
-define(VIP_TITLE_MAX_LENGTH, 18).   % vip称号上限6个汉字
-define(VIP_INFINATE_TIME,2000000000). % 至尊VIP有效时间(无限)

-define(BOOKING_GIFT, 181000005).	%预定礼包

% 定时更新称号（单位：秒）为18分钟
-define(UPDATE_TITLE_TIMER, 18*60*1000).

%% 游戏中流通的货币
-define(MONEY_T_GOLD,  		1).         %% 元宝
-define(MONEY_T_BGOLD, 		2).         %% 绑定元宝
-define(MONEY_T_COIN,  		3).         %% 铜钱
-define(MONEY_T_BCOIN, 		4).   	   %% 绑定铜钱
-define(MONEY_T_COUPON,		5).   	   %% 礼券
-define(MONEY_T_HONOR, 		6).   	   %% 积分/礼券
-define(MONEY_T_EXCHANGE, 	7).   	   %% 兑换

%% 物品、装备相关宏
-define(LOCATION_BAG,         0).   % 背包位置
-define(LOCATION_PLAYER,     1).    % 玩家身上
-define(LOCATION_PET,   2).     	% 宠物
-define(LOCATION_TREA,        4).   % 淘宝仓库 5页300格
-define(LOCATION_WINGS,        5).   % 衣柜
-define(LOCATION_HOLY_PLATFORM,        6).   % 圣坛
-define(LOCATION_MAIL,        11).   % 虚拟位置：邮件（用于标记邮件中的附件）
-define(LOCATION_MARKET,    12).   % 虚拟位置：市场（用于标记市场中挂售的物品）
-define(LOCATION_PARTNER_TRANSFORM,  20).   % 武将装备转档仓库
-define(TenMinute, 10 * 60 * 1000).




%% 返回结果：
-define(RESULT_OK,   1).  %% 成功
-define(RESULT_FAIL, 0).  %% 失败
-define(DELAY_CALL, 5000).

%% -define(ETS_TEMP_GOODS, temp_goods).                        %% 物品类型表
-define(ETS_COMPOSE_RULE, ets_compose_rule).                  %% 宝石合成规则表
-define(ETS_GOODS_INLAY, ets_goods_inlay).                      %% 宝石镶嵌规则表
-define(ETS_MARKET_GOODS_ONLINE, ets_market_goods_online).      %% 市场的上架物品信息表
-define(ETS_MARKET_GOODS_ATTR, ets_market_goods_attr).          %% 市场的上架物品的附加属性信息表
-define(ETS_GOODS_DROP, ets_goods_drop).                        %% 物品掉落表
-define(ETS_DROP_TYPE, ets_drop_type).                          %% 物品掉落类型
-define(ETS_DROP_NUM, ets_drop_num).                            %% 物品掉落上限值
-define(ETS_DROP_CONTENT, ets_drop_content).                    %% 物品掉落包中物品
-define(ETS_MARKET_SELLING, ets_mk_selling).                    %% 市场上架物品表
-define(ETS_MARKET_REQUEST, ets_mk_request).                    %% 市场求购物品表
-define(GLOBAL_MARK_PROCESS, g_market_process). %% 市场/拍卖行
-define(ETS_PET_INFO, ets_pet_info). %% 宠物
-define(ETS_GOODS_BUFF, ets_goods_buff). 
-define(ETS_ZIP_PROTO,ets_zip_proto).
% 32位有符号数的最大值
-define(MAX_S32, 2147483647).  

% 16位有符号数的最大值
-define(MAX_S16, 32767).

% 8位有符号数的最大值
-define(MAX_S8, 127).

% 8位无符号数的最大值
-define(MAX_U8, 255).

%% 宠物
-define(PET_REST, 	   0). 		% 宠物休息
-define(PET_FIGHTING,  1).	    % 出战
-define(PET_NOT_EXIST, 2).		% 不存在

%% 换装
-define(DEFAULT_T_WEAPON, 0). % 武器
-define(DEFAULT_T_ARMOR, 0). % 盔甲
-define(DEFAULT_T_FASHION, 0). % 时装
-define(DEFAULT_T_WINGS, 0). % 翅膀
-define(DEFAULT_T_WEAPONACCESSORIES, 0). % 武饰
-define(DEFAULT_T_MOUNT, 0). % 战骑

%%经脉
-define(ETS_MERIDIAN,player_meridian).%经脉模板表
-define(ETS_TPL_BONES,base_bones).%筋骨模板表

%%副本物件
-define(CONDITION_NULL,1).
-define(CONDITION_END,2).
-define(CONDITION_MON_DEAD,3).
-define(CONDITION_NULLEND,4).

%% 互动通知右边圆圈图标类型
-define(NOTICE_ICON_TYPE_FRIEND,     1).      	%% 好友
-define(NOTICE_ICON_TYPE_GUILD,     2).      	%% 帮派
-define(NOTICE_ICON_TYPE_MAIL,     3).      	%% 邮件
-define(NOTICE_ICON_TYPE_GIFT,     4).      	%% 礼物
-define(NOTICE_ICON_TYPE_FIGHT,     5).      	%% 打架
-define(NOTICE_ICON_TYPE_FLOWER,     6).      	%% 送花
%%定义需要做协议压缩的协议号
-define(ZIP_PROTO,[12002,12003,12007,12010,12012,12013,12015,13000,13001,13002,13003,13007,14001,14002
,14003,14005,15000,15002,15004,15015,15021,15026,19002,19011,20001,21000,25001,30006
,30601,30701,35002,40001,40005,44000,45001,45006,45008,50001]).

-define(ZONE_POS,[{0,0},{0,1},{1,1},{1,0},{1,-1},{0,-1},{-1,-1},{-1,0},{-1,1}]).
-record(scene_map_info,{
		map_id,
		grid_row,
		grid_col,
		grid_type
}).

-define(PLAYER_EXIT_UNORMAL,0). %玩家正常退出标识

-define(ALL_CAMP_TYPE,[1,2,3]). %所有阵营的类别

%%充值处理状态
-define(HANDLE_CHARGE_ORDER, 1).    % 已处理充值订单
-define(UNHANDLE_CHARGE_ORDER, 0).  % 未处理充值订单

%%充值订单状态
-define(CHARGE_ORDER_STATUS_SUCCESSFUL, 1).
-define(CHARGE_ORDER_STATUS_FAILED, 0).

%%充值渠道
-define(CHARGE_CHANEL_GM, 50). %GM指令渠道
-define(CHARGE_CHANEL_4399_SHOU_YOU_BI, 1). %4399手游币
-define(CHARGE_CHANEL_SHEN_ZHOU_XING, 2). %移动神州行
-define(CHARGE_CHANEL_LIAN_TONG, 3). %联通
-define(CHARGE_CHANEL_ALIPAY, 4). %支付宝
