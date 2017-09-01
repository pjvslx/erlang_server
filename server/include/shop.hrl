%%%-------------------------------------- 
%%% @Module: common_shop
%%% @Author: 
%%% @Created: 
%%% @Description: 
%%%-------------------------------------- 

%% desc: 特价商区
-record(bar_shop, {
                           init_time = 0,
                           end_time = 0,
                           goods1 = [],  % [goods_tid, left_num, o_price, price, price_type]
                           goods2 = [],
                           goods3 = [],
                           bar_tid_1 = 0, 
                           left_1 = 0, 
                           price1 = 0,
                           price_type1 = 0,
                           bar_tid_2 = 0, 
                           left_2 = 0, 
                           price2 = 0,
                           price_type2 = 0,
                           bar_tid_3 = 0, 
                           left_3 = 0, 
                           price3 = 0,
                           price_type3 = 0
                       }).

%% desc: 商店状态
-record(shop_state, {
					      barlist = #bar_shop{}, 
                          mystery_id = 0   % 神秘商店日志ID
                    }).


%% desc: 神秘商店
-record(mystery_shop, {
                       player_id = 0,
                       sells = [],   % 当前出售的物品类型ID列表[{GoodsTid, State}...]
                       nextime = 0,   % 下次刷新商店的时间
                       clear_date = {0, 0, 0},   % 最近一次玩家主动的刷新日期
                       left_clear = 0   % 今日剩余免费刷新次数
                       }).

%% desc: 神秘商店日志
-record(mystery_log, {
                      id = 0,   % 自动生成ID
                      player_id = 0,   % 玩家ID
                      player_name = <<>>,   % 玩家昵称
                      goods_tid = 0   % 物品类型ID
                      }).

%% desc: 淘宝积累费用
-record(trea_total_cost, {
                          player_id = 0,   % 玩家ID
                          gold = 0   % 当前积累元宝
                          }).
						  
						  
-define(MYSTERY_CLEAN_TIMES, 2).   %% 每日免费刷新神秘商店的次数

-define(REFRESH_INTERVAL, 6 * 60 * 60).              %% 特价区刷新时间间隔 6小时
-define(BAR_LASTING_TIME, 6 * 60 * 60).   % 商城特价区出售物品持续时间
-define(REFRESH_MYSTERY_INTERVAL, 3 * 60 * 60).   % 神秘商店刷新间隔3小时

-define(ETS_SHOP, ets_shop).                               %% 商店ETS表
-define(ETS_SHOP_GOODS_TYPE, ets_shop_goods_type).         %% 商城销售物品类型表
-define(ETS_CONSUME_BAR, ets_consume_bar).         %% 商店特价区ETS表
-define(ETS_D_SHOP, ets_d_shop).                         %% 商店销量ETS表
-define(ETS_MYSTERY_SHOP, ets_mystery_shop).        %% 神秘商店ETS表
-define(ETS_MYSTERY_LOG, ets_mystery_log).           %% 神秘商店日志
-define(ETS_TREA_COST, trea_total_cost).               %% 淘宝积累消费表

-define(LOCAL_SHOP_PROC, local_shop_proc).          %% 全局商店进程PID
-define(GLOBAL_SHOP_B_PROC, global_shop_b_proc).    %% 全局商店进程PID(购买抢购物品)


-define(ETS_TREA_INFO, ets_trea_info).                  %% 淘宝信息表
-define(TOP_TEN, 10).                                        %% 前十
-define(KEEP_DAYS, 90).                                     %% 销售记录保留天数

-define(TREA_SILVER, 1). % 银宝阁
-define(TREA_GOLD, 2). % 金宝阁
-define(TREA_JADE, 3). % 玉宝阁

-define(TREA_MAX_LOG_ITEM, 30). % 淘宝日志最多30条记录

%% 淘宝 TypeId:
%% 1- 银宝阁淘宝1次
%% 2- 银宝阁淘宝10次
%% 3- 银宝阁淘宝50次
%% 4- 金宝阁淘宝1次
%% 5- 金宝阁淘宝10次
%% 6- 金宝阁淘宝50次
%% 7- 玉宝阁淘宝1次
%% 8- 玉宝阁淘宝10次
%% 9- 玉宝阁淘宝50次
-define(TREA_TIMES_SILVER_1, 1).
-define(TREA_TIMES_SILVER_10, 2).
-define(TREA_TIMES_SILVER_50, 3).

-define(TREA_TIMES_GOLD_1, 4).
-define(TREA_TIMES_GOLD_10, 5).
-define(TREA_TIMES_GOLD_50, 6).

-define(TREA_TIMES_JADE_1, 7).
-define(TREA_TIMES_JADE_10, 8).
-define(TREA_TIMES_JADE_50, 9).



%% 商店类型
-define(SHOP_T_EMPORIUM, 1).	% 商城
-define(SHOP_T_NPC, 	 2).	% npc商人
-define(REMOTE_STORE, 0).   % 远程仓库
-define(REMOTE_GOODS_SHOP, 1).   % 远程道具店
-define(COST_OPEN_REMOTE, 2).   % 开启远程店/仓库花费的元宝


-define(NPC_SHOP_BUY, 1).  % 表示购买页面
-define(NPC_SHOP_EXCHANGE, 2).  % 表示兑换页面
-define(NPC_SHOP_DUNGEON, 4).   % 副本商人


%% 与商城有关的宏
%% -define(SHOP, 1).   % 商城
-define(OBJECT_REMOTE_SHOP, 1028).             % 远程药店
-define(NPC_SUB_PAY, 1).   % Npc商店购买子页
-define(NPC_SUB_CHANGE, 2).   % Npc商店兑换子页
-define(OBJECT_EMPORIUM, 1).          % 商城
-define(SHOP_T_GOODS_PRICE, 4).   % 不在商城显示的物品价格

-define(EMPORIUM_SUB_NEW, 1).             % 商城子页：新品热销
-define(EMPORIUM_SUB_USUAL, 2).           % 商城子页：常用道具
-define(EMPORIUM_SUB_STONE, 3).           % 商城子页：宝石护符
-define(EMPORIUM_SUB_VIP, 4).           % 商城子页：VIP专区
-define(EMPORIUM_SUB_RARE, 5).           % 商城子页：奇珍异宝
-define(EMPORIUM_SUB_MOJING, 6).           % 商城子页：奇珍异宝
-define(SUB_MAX, 6).                      % 商城子页上限


-define(BARGAIN_1, 1).   % 特价1物品	
-define(BARGAIN_2, 2).	% 特价2物品
-define(BARGAIN_3, 3).	% 特价3物品
-define(SHOP_CONSUME_NUMS, 10).	% 特价物品购买个数

%% 消费类型
-define(SHOP_N_EMPORIUM, "shop").  % 商城
-define(SHOP_N_BARGAIN, "shop_bargain").   % 商城特价区
-define(SHOP_N_NPC, "npc").   % npc商店
-define(SHOP_N_REMOTE, "remote_shop").   % 远程商店
-define(SHOP_N_EXCHANGE, "exchange_shop").   % 兑换商店
-define(SHOP_N_GUILD, "guild_shop").   % 帮派商店
-define(SELL_GOODS, "sell_goods").   % 出售物品

%% 购买状态
-define(BUY_STATE_NOTYET, 0). 
-define(BUY_STATE_ALREADY, 1). 

%% SQL 
-define(SQL_GET_MAX_MYSTERY_LOG_ID, "max(id)").
%% -define(SQL_GET_MAX_MYSTERY_LOG_ID, io_lib:format(<<"select max(id) from `mystery_log`">>, [])).
-define(SQL_SELECT_ALL_MYSTERY_LOG, "id, player_id, player_name, goods_tid").
-define(SQL_SELECT_MYSTERY_SHOP, "sells, nextime, clear_date, left_clear").

%% 装备兑换1页显示装备数
-define(NPC_EQUIP_SHOW, 6).
%% 装备商人1页显示装备数
-define(NPC_EXCHANGE_EQUIP_SHOW, 8).