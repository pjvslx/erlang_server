%%%------------------------------------------------
%%% File    : goods.hrl
%%% Author  :
%%% Created :
%%% Description: 物品系统的相关宏定义
%%%------------------------------------------------

%% 避免头文件多重包含
-ifndef(__GOODS_H__).
-define(__GOODS_H__, 0).


%% desc: 物品ets上限个数
-define(MAX_GOODS_ETS_NUM, 100).
%% desc: 物品ets表玩家个数上限
-define(MAX_ROLE_NUM, 50).
%% desc: 在线玩家的背包物品表
-define(ETS_GOODS_ONLINE(X), mod_goods_l:goods_ets_name(X)).                    
%% desc: 在线玩家的背包物品属性表
-define(ETS_GOODS_ATTRIBUTE(X), mod_goods_l:goods_ets_attr_name(X)).      
%% desc: 在线玩家物品洗炼表    
-define(ETS_CASTING_POLISH(X), mod_goods_l:goods_ets_polish_name(X)).  

%% sql查询物品基本信息
-define(SQL_QRY_GOODS_BASE_INFO, "id, player_id, partner_id, gtid, type, subtype, subsubtype, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, phy_att, mag_att, spr_att,  phy_def, mag_def, spr_def , pursuit, block, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, wash, stren, stren_his, stren_fail, hole, hole1_goods, hole2_goods, hole3_goods, hole4_goods, location, cell, num, color, score").
%% sql查询物品总数
-define(SQL_QRY_GOODS_TOTAL, "count(1)").

%% sql查询物品附加属性
-define(SQL_QRY_GOODS_ATTR, "id, player_id, gid, attribute_type, stone_type_id, attribute_id, value, value_type, public").

%% desc: 物品类型ID固定减少的值
-define(FIX_SUB_GOODS_TID_VALUE, 500).

%% 目前装备加成的属性有13种：HpLim, PhyAtt, MagAtt, SprAtt, PhyDef, MagDef, Sprdef, Pursuit, Block, Hit, Dodge, Crit, Ten
-define(MAX_EQUIP_ADD_ATTR, 13).


%% 物品类型
-define(GOODS_T_EQUIP,    	1).    	   % 玩家装备类
-define(GOODS_T_PET_EQUIP,    	2).    % 宠物装备类
-define(GOODS_T_BOOK,    	4).
-define(GOODS_T_BUFF,    	8).    	% BUFF类物品
-define(GOODS_T_GIFTBAG,		9).		% 礼包类型		
-define(GOODS_T_PET_FACADE,    	10).	% 宠物幻化卡
-define(GOODS_T_MOUNT_FACADE,    	11).	% 战骑幻化卡
-define(GOODS_T_STONE,    	111).    % 宝石类
-define(GOODS_T_RUNE,     	12).    % 护符类
-define(GOODS_T_STATUS,   	13).    % 状态类
%% -define(GOODS_T_BOOK,     	14).    % 书类
-define(GOODS_T_PET,      	15).    % 宠物类
-define(GOODS_T_MAT,      	16).    % 材料类
-define(GOODS_T_MOUNT,    	17).    % 坐骑类
-define(GOODS_T_GIFT,     	18).    % 礼包类
-define(GOODS_T_RUNESTONE, 	19).   	% 符文石
-define(GOODS_T_DRUG,     	20).    % 药品类
-define(GOODS_T_VIP,     	21).    % VIP类
-define(GOODS_T_CARD,  	22).    % 消耗卡类物品
-define(GOODS_T_PARTNER_CARD,  	23).    % 武将卡
-define(GOODS_T_WUHUN,    	30).    % 武魂类
-define(GOODS_T_PAR_EQUIP,    	31).    % 武将装备类（武将装备不同于玩家装备）
-define(GOODS_T_VIRTUAL,    	32).    % 虚拟物品，经验， 金钱，历练，战功
-define(GOODS_T_GUILD,    	41).    % 帮派类
-define(GOODS_T_TASK,     	50).    % 任务类
-define(GOODS_T_SPECIAL,  	57).    % 特殊类
-define(GOODS_T_GOLDCHEST,  58).    % 宝箱类
-define(GOODS_T_MONEY,    	59).    % 货币类
-define(GOODS_T_OTHER,    	60).    % 其他
-define(GOODS_T_MAX,      	60).    % 最大值（用于程序做判定）


%% 装备子类型

-define(EQUIP_T_CAP,      201).      % 头盔
-define(EQUIP_T_SHOULDER, 203).     % 护肩
-define(EQUIP_T_WRISTER,  205).      % 护腕
-define(EQUIP_T_ARMOR,    207).		% 盔甲
-define(EQUIP_T_BELT, 	  209).		% 腰带
-define(EQUIP_T_SHOES, 	  211).		% 战靴
-define(EQUIP_T_NECK,     213).      % 项链
-define(EQUIP_T_FURNISHINGS, 215).		% 玉佩
-define(EQUIP_T_BRACELET,    217).		% 手镯
-define(EQUIP_T_RING,    	 219).      % 戒指
-define(EQUIP_T_WEAPON,  	 221).      % 武器
-define(EQUIP_T_WEAPONACCESSORIES,  	 223).      % 武饰
-define(EQUIP_T_FASHION,	 225).      % 时装
-define(EQUIP_T_WINGS,   	 229).    % 翅膀
-define(EQUIP_T_MARRYACCESSORIES,   	 70).    % 婚饰

-define(MIN_REWARD_STREN_LV, 3).
-define(MAX_EQUIP_REWARD_STREN, 11).
-define(ALL_STREN_EQUIP, [?EQUIP_T_CAP, ?EQUIP_T_SHOULDER, ?EQUIP_T_WRISTER, ?EQUIP_T_ARMOR, ?EQUIP_T_BELT,
						   ?EQUIP_T_SHOES, ?EQUIP_T_NECK, ?EQUIP_T_FURNISHINGS, ?EQUIP_T_BRACELET, ?EQUIP_T_RING, ?EQUIP_T_WEAPON]).

-define(EQUIP_T_CLOTHES, 3).      % 衣服
%% -define(EQUIP_T_SHOES,   5).      % 鞋子
%% -define(EQUIP_T_RING,    6).      % 戒指
%% -define(EQUIP_T_NECK,    7).      % 项链
%% -define(EQUIP_T_SPIRIT,  8).      % 灵器
%% -define(EQUIP_T_FASHION, 9).      % 时装
%% -define(EQUIP_T_KEEPSAKE, 10).    % 信物
%% -define(EQUIP_T_MAX,      11).    % 最大值（用于程序做判定）

%% 武将装备子类型
-define(PARTNER_EQUIP_T_MIN, 1).   % 最小值
-define(PARTNER_EQUIP_T_WEAPON,  1).    % 武器
-define(PARTNER_EQUIP_T_ORNAMENTS, 2).  % 饰品
-define(PARTNER_EQUIP_T_ARMOR, 3).      % 防具
-define(PARTNER_EQUIP_T_HOLY, 4).       % 圣物
-define(PARTNER_EQUIP_T_MAX, 4).        % 最大值（用于程序做判定）

%% 武器二级子类型
%-define(WPN_T_BLADE, 1).          % 刀
%-define(WPN_T_SWORD, 2).          % 剑
%-define(WPN_T_SPEAR, 3).          % 枪
%-define(WPN_T_ROD, 4).            % 棍
%-define(WPN_T_BOW, 5).            % 弓
%-define(WPN_T_FLYCUTTER, 6).      % 飞刀
%-define(WPN_T_NATURE, 7).      	  % 自然系（此编号已作废）
%-define(WPN_T_WAND, 8).			  % 法杖
%-define(SPIRIT_T_PHY, 9).   	  % 物理类灵器
%-define(SPIRIT_T_MAG, 10).   	  % 法术类灵器
%-define(WPN_T_MAX,       10).     % 最大值（用于程序做判定）



%% 宝石子类型
-define(STONE_T_STREN, 1).   % 强化
-define(STONE_T_WASH,  2).   % 洗炼
-define(STONE_T_ATTR,  3).   % 属性

%% 护符子类型
-define(RUNE_T_STREN,    1).     % 强化
-define(RUNE_T_BACKOUT,  2).     % 拆除
-define(RUNE_T_COMPOSE,  3).     % 合成


%% 状态类物品子类型
-define(STATUS_T_ATT,    1).     % 攻击
-define(STATUS_T_DEF,    2).     % 防御
-define(STATUS_T_EXP,    3).     % 经验
-define(STATUS_T_HP,     4).     % 气血


%% 药品子类型
-define(DRUG_T_HP,            1).     % 气血
-define(DRUG_T_VITALITY,      2).     % 体力
-define(DRUG_T_EXP,           3).     % 经验
-define(DRUG_T_CHANGE_APPE,   4).     % 变身
-define(DRUG_TYPE_SUB_HP, 01).   % 气血瓶子类
-define(DRUG_TYPE_SUB_EXP, 03).   % 经验丹子类


%% 书子类型
-define(BOOK_T_SKILL, 1).   % 技能书
-define(BOOK_T_TROOP, 2).   % 阵法书


%% 材料子类型
-define(MAT_T_STAR_EQUIP, 		1).  	% 星级装备
-define(MAT_T_ORANGE_SPIRIT, 	2).   	% 橙色灵器
-define(MAT_T_ZT_GOLDCHEST, 	3).   	% 战天宝箱
-define(MAT_T_ZT_MONEY, 		4).   	% 战天币
-define(MAT_T_EQUIP_GOLDCHEST, 	5).   	% 装备宝箱
-define(MAT_T_SUIT_GOLDCHEST, 	6).   	% 套装宝箱
-define(MAT_T_RUNESTONE, 		7).   	% 符文石头

 
%% 礼包子类型
-define(GIFT_T_NEWBIE, 1).   % 新手礼包
-define(GIFT_T_LV_STEP, 2).  % 等级礼包


%% 物品或武将的颜色
-define(COLOR_WHITE,    1).    % 白色
-define(COLOR_GREEN,    2).    % 绿色
-define(COLOR_BLUE,     3).    % 蓝色
-define(COLOR_PURPLE,   4).    % 紫色
-define(COLOR_ORANGE,   5).    % 橙色
-define(COLOR_MAX,      5).    % 颜色的最大有效编号（用于程序做判定）
-define(COLOR_INVALID, 99).    % 无效的颜色编号（用于程序做判定）



%% 绑定状态
-define(BIND_ANY,     0).      % 0不限制
-define(BIND_NOTYET,  1).      % 捡取绑定
-define(BIND_EQUIP,  2).       % 装备绑定
-define(BIND_ALREADY, 3).      % 已绑定
-define(BIND_NOT, 99).         % 未绑定

%% 交易状态
-define(TRADE_BAN, 0).   % 不可交易
-define(TRADE_CAN, 1).   % 可以交易
%% 出售状态
-define(SELL_BAN, 0).   % 不可出售
-define(SELL_CAN, 1).   % 可以出售
%% 丢弃状态
-define(DROP_BAN, 0).   % 不可丢弃
-define(DROP_CAN, 1).   % 可以丢弃


%% 物品附加属性状态
-define(MAKE_STREN,        1).   % 强化
-define(MAKE_STREN_LV_4, 2).   % 强化+4附加属性
-define(MAKE_STREN_LV_7, 3).   % 强化+7附加属性
-define(MAKE_WASH,         4).   % 洗炼
-define(MAKE_INLAY,         5).   % 镶嵌       应客户端显示tips要求，暂时修改顺序，2012-01-11
-define(MAKE_STREN_LV_11, 6).   % 强化+10附加属性
-define(MAKE_PARTNER,         7).   % 武将装备专精

%% 固定花费铜钱
-define(COST_EXTEND_BAG, 5).   % 扩展背包花费元宝
-define(COST_EXTEND_STORE, 60).   % 扩展仓库花费铜钱数

%% 掉落相关宏
-define(DROP_UNCERTAINLY, 0).   % 掉落概率不为100%的物品  
-define(DROP_CERTAINLY, 1).   % 掉落概率为100%的物品

%% 怪物掉落
-define(AWARD_MON, 0).        % 怪物死亡掉落
-define(AWARD_DUNGEON, 1).     % 副本通关奖励

% 装备格子位置
-define(EQUIP_POS_INVALID,  0).   % 无效位置（用于程序表示非法的情况）
-define(EQUIP_POS_SPIRIT,   1).   % 灵器位置
-define(EQUIP_POS_WEAPON, 	2).   % 武器位置
-define(EQUIP_POS_NECK, 	3).   % 项链位置  
-define(EQUIP_POS_RING, 	4).   % 戒指位置
-define(EQUIP_POS_CAP, 		5).   % 帽子位置
-define(EQUIP_POS_CLOTHES, 	6).   % 衣服位置
-define(EQUIP_POS_WRISTER, 	7).   % 手腕位置
-define(EQUIP_POS_SHOES, 	8).   % 鞋子位置
-define(EQUIP_POS_MOUNT, 	9).   % 坐骑位置
-define(EQUIP_POS_FASHION, 	10).  % 时装位置
-define(EQUIP_POS_KEEPSAKE, 11).  % 信物位置
-define(EQUIP_POS_WINGS,    12).  % 翅膀位置

-define(MAX_PLAYER_EQUIP_POS,  15).   % 玩家穿戴装备最大数量
-define(MAX_PARTNER_EQUIP_POS, 8).    % 武将穿戴装备最大数量


-define(CELL_NUM_MAX_BAG, 8 * 16).   % 玩家背包最大格子数（包括未开启的格子）128个
-define(CELL_NUM_MAX_STORE, 36 * 3).   % 玩家仓库最大格子数（包括未开启的格子）
-define(CELL_NUM_PER_BAG, 6).   % 玩家每次开启背包的格子数
-define(CELL_NUM_PER_STORE, 6).   % 玩家每次开启仓库的格子数

%% 洗炼相关宏
-define(POLISH_LOCK, 308004204).		% 装备洗炼锁  (数据库中错别字：装备洗练锁)

%% 药品类相关宏
-define(DRUG_HP_BAG_JUNIOR, 200100001).   % 低级气血包
-define(DRUG_HP_BAG_MEDIUM, 200100002).   % 中级气血包
-define(DRUG_HP_BAG_SENIOR, 200100003).   % 高级气血包
-define(BIND_DRUG_HP_BAG_JUNIOR, 200100501).   % 低级气血包
-define(BIND_DRUG_HP_BAG_MEDIUM, 200100502).   % 中级气血包
-define(BIND_DRUG_HP_BAG_SENIOR, 200100503).   % 高级气血包

%% vip卡相关宏
-define(VIP_TID_LV_1, 210100001).   % 一日游卡
-define(VIP_TID_LV_2, 210200001).   % 周卡
-define(VIP_TID_LV_3, 210300001).   % 月卡
-define(VIP_TID_LV_4, 210400001).   % 半年卡
-define(VIP_TID_LV_5, 210500001).   % 至尊卡
-define(VIP_TID_LIST, [?VIP_TID_LV_1, ?VIP_TID_LV_2, ?VIP_TID_LV_3, ?VIP_TID_LV_4, ?VIP_TID_LV_5]).   % vip卡ID列表

%% 状态符文相关宏
-define(RUNE_S_HP_LIM_JUNIOR, 130400001).   % 低级生命符
-define(RUNE_S_EXP_JUNIOR, 130300001).   % 低级经验符
-define(RUNE_S_ATT_PHY, 130100001).   % 低级物理攻击符
-define(RUNE_S_DEF_PHY, 130200001).   % 低级物理防御符
-define(RUNE_S_MONEY, 10000001).   % 低级金钱符

-define(BIND_GOLD_CARD, 1).   % 增加绑定金币的物品卡
-define(UNBIND_GOLD_CARD, 2).   % 增加非绑定金币的物品卡
-define(SOUL_POWER_CARD, 3).   % 增加战魂值的物品卡
-define(WING_CARD, 4).   % 翅膀卡
-define(MOUNT_CARD, 5).   % 坐骑卡
-define(POWER_CARD, 6).   % 体力
-define(BCOIN_CARD, 7).   % 战天币
-define(REPU_CARD, 8).   % 声望
-define(ACC_POINT_CARD, 9).   % 勇勋值
-define(EXP_CARD, 10).   % 经验卡
-define(SKILL_CARD, 11).   % 技能点
-define(GOLD_CARD, 12).   % 元宝卡
-define(PARTNER_SOUL_CARD, 13).   % 将魂值卡
-define(GONGXUN_CARD, 14).   % 功勋卡
-define(BATTLE_CONTRIB_CARD, 15).   % 战功卡

%% 货币金钱类型ID相关宏
-define(MONEY_GOLD_T_ID, 526004201).   		 % 元宝编号ID
-define(MONEY_BGOLD_T_ID, 527004201).   	 % 元宝（绑定）
-define(MONEY_COIN_T_ID, 530004201).   	 % 铜钱编号ID
-define(MONEY_BCOIN_T_ID, 531004201).   % 绑定铜钱编号ID

-define(MONEY_EXP_T_ID, 541004201).   % 经验编号ID
-define(MONEY_LILIAN_T_ID, 551004201). % 历练
-define(MONEY_GUILD_CONTRIBUTION_T_ID, 523004201). % 帮派贡献


%% 铸造相关宏
-define(STREN_FAIL, 15).   %% 强化失败
-define(EQUIP_MAX_HOLES, 4).   %% 装备的最大孔数
-define(EQUIP_MAX_STREN, 12).   %% 装备最大强化等级
-define(CASTING_DIVERT_MIN_STREN, 2).   %% 强化转移最低强化等级

-define(USE_RUNE_NO, 0).
-define(USE_RUNE_YES, 1).
-define(USE_RUNE_MAX, 1).

-define(BIND_FIRST_NO, 1). % 原为非绑定优先： 现在改为仅使用非绑定材料
-define(BIND_FIRST_YES, 0).
-define(BIND_FIRST_MAX, 1).

-define(BINDSTATE_BIND_ONLY, 	0).	%%只用绑定
-define(BINDSTATE_UNBIND_ONLY, 	1). %%只用非绑定
-define(BINDSTATE_BIND_FIRST,	2). %%绑定优先
-define(BINDSTATE_UNBIND_FIRST, 3). %%非绑定优先

-define(AUTO_BUY_NO, 0).
-define(AUTO_BUY_YES, 1).
-define(AUTO_BUY_MAX, 1).

%% 宝石镶嵌孔位置
-define(HOLE_1, 1). % 第一孔
-define(HOLE_2, 2). % 第二孔
-define(HOLE_3, 3). % 第三孔
-define(HOLE_4, 4). % 第四孔


%% 属性值类型相关宏
%% 0气血,1物理攻击,2法术攻击,3绝技攻击,4物理防御,5法术防御,6绝技防御,7追击,8格挡,9命中,10闪避,11暴击
%% 12坚韧,13先手值,15剑系精通,16弓系精通,17枪系精通,18法系精通,19剑系抗性,20弓系抗性,21枪系抗性,22法系抗性 
%% 23初始怒气,24抵挡
-define(ATTRI_T_HP_LIM, 0).
-define(ATTRI_T_PHY_ATT, 1).
-define(ATTRI_T_MAG_ATT, 2).
-define(ATTRI_T_SPR_ATT, 3).
-define(ATTRI_T_PHY_DEF, 4).
-define(ATTRI_T_MAG_DEF, 5).
-define(ATTRI_T_SPR_DEF, 6).
-define(ATTRI_T_PURSUIT, 7).
-define(ATTRI_T_BLOCK, 8).
-define(ATTRI_T_HIT, 9).
-define(ATTRI_T_DODGE, 10).
-define(ATTRI_T_CRIT, 11).
-define(ATTRI_T_TEN, 12).
-define(ATTRI_T_FIGHT_ORDER_FACTOR, 13).
-define(ATTRI_T_PRO_SWORD, 15).
-define(ATTRI_T_PRO_BOW, 16).
-define(ATTRI_T_PRO_SPEAR, 17).
-define(ATTRI_T_PRO_MAG, 18).
-define(ATTRI_T_RESIS_SWORD, 19).
-define(ATTRI_T_RESIS_BOW, 20).
-define(ATTRI_T_RESIS_SPEAR, 21).
-define(ATTRI_T_RESIS_MAG, 22).
-define(ATTRI_T_ANGER, 23).
-define(ATTRI_T_WITHS, 24).





-define(WING_CELL_NUM, 8).   % 衣柜固定空间格子数
-define(TREA_CELL_NUM, 175).   % 淘宝仓库固定空间格子数

%% 非身上的装备属性默认值列表
-define(ATTRI_DEF_LIST, lists:duplicate(13, 0) ).



-define(ETS_GOODS_INDEX, ets_goods_index).

-define(WING_STREN_LEVEL, 9). % 强化等级，显示飞行模式设置按钮


%% 物品状态表
-record(goods_status, {
        uid = 0,              % 用户ID
        null_cells = [],            % 背包空格子位置
        store_null_cells = [],
        trea_null_cells = [],
        mail_cells = [],            % 此字段仅起到格式统一作用，无具体意义
        equip_current = [],      % 当前玩家主角的装备类型ID - []
        equip_suit = [],            % 套装属性 [{EquipId, Location, EquipNum}...] 包括人物，武将等的套装都记录在内
        drop_pass = [],           % 掉落筛选出来的物品列表存放在这里，每次仅存一次战斗的掉落包物品列表 DropContentList
        drop_usual = [],           % 掉落筛选出来的物品列表存放在这里，每次仅存一次战斗的掉落包物品列表 DropContentList
        gchest_info = {},           % 开启的宝箱信息
        gchest_goods = [],         % 开启宝箱后物品暂存 [{GoodsTid, Num} , ...]
        ct_time = 0                % 使用药品的冷却时间
    }).

-endif.  %% __GOODS_H__

%% 装备套装基础属性表
-record(base_suit, {
        id = 0,               % 编号
        suit_id = 0,         % 套装ID
        suit_num = 0,       % 套装件数
		max_num = 0,       % 套装总件数
		attri_id = 0,         % 属性类型
        value_type = 0,     % 属性值类型，0为数值，1为百分比
        value = 0           % 属性值
    }).

%% 套装表
-record(ets_suit_attri, {
					    player_id = 0,
						owner_id = 0,   % 拥有者ID，若玩家自身穿着，则此处为0
						location = 0,     % 玩家-2，武将-3
						suit_id = 0,
						suit_num = 0,
						attri_id = 0,         % 属性类型
						value_type = 0,     % 属性值类型，0为数值，1为百分比
						value = 0            % 属性值
					   }).

%% 礼包
-record(ets_gift, {
                   player_id = 0,   % 玩家id    key
                   
                   daily_login_date = {},   % 玩家登录日期
                   daily_condays = 1,   % 连续领取天数
                   daily_isget = 0,   % 今日是否领取日常礼包，0-未领取，1-已领取
                   
                   online_get_times = 0,   % 在线礼包已领取次数
                   online_next_time = 0,   % 下次领取在线礼包的时间
                   online_interval = 0,   % 剩余领取时间
                   
                   login_reg_date = {},   % 账号注册日期
                   login_tid = 0,   % 下个登陆礼包类型ID
                   
                   lv_tid = 0,   % 下个等级礼包类型ID
                   vip_tid = 0,   % vip奖励礼包
                   
                   yb_state = [],   % 元宝领取状态，0-不可令，1-可令，2-已领取
                                       % 元宝领取编号：0-战天活动元宝，1~6 每日活动元宝
                                       % [{编号，是否领取}...]
                   mate_date = {0, 0, 0}   % 材料领取状态, 1~7 周1到周7材料
                   }).
				   
				   
%% 商店表
-record(ets_shop, {
        id = 0,      
        shop_type = 0,
        shop_subtype = 0,      
        tabno   = 0,         %% 属性页
        page = 0,             %% 页数
        location = 0,        %% 位置
        gtid = 0,        %% 物品类型ID
        o_price = 0,         %% 物品原价：此字段价格类型固定为金币 
        price_type = 0,      %% 价格类型：1-金币，2-元宝，3-战天币，4-声望
        price = 0,             %% 价格
		max = 0,
		flag = 0
        }).	

%% 商店物品销量表
-record(ets_d_shop, {
		gtid,             
        year,      
        month,   
        day,        
		sell_num
    }).	

%% 商店特价区表  
-record(ets_consume_bar, {
						  role_id,
						  gtid,
%% 						  bargain_type,     %% 特价商品类型：1-特价1物品，2-特价2物品
						  num,
						  price,
						  price_type
						  }).


%% 淘宝记录
-record(ets_trea, {
				        role_id,
						time = 0,
						role_name = [],
						type,
						gtid
				      }).



-define(DISPLAY_GOODS, 1).  %物品

%% desc: 强化完美度最大值
-define(MAX_STREN_DEGREE, 10).
-define(LEVEL_STREN_DEGREE, 11).
-define(MIN_STREN_DEGREE, 0).

%% 
%% %% desc: 装备至少2条基础属性
%% -define(MIN_EQUIP_ATTRI_NUM, 2).
%% 
%% %% desc: 强化基础系数
%% -define(STREN_ATTRI_BASE_FACTOR, 1000).
%% 
%% 使用非绑定材料
-define(UNBIND_FIRST, 0). % 非绑定材料优先使用
-define(BIND_FIRST, 1).   % 绑定材料优先使用



-define(MAX_STREN_RAND, 10000). % 强化随机基数
%% desc: 洗炼属性是否锁上
-define(WASH_LOCK, 1).
-define(WASH_UNLOCK, 0).
%% 最大洗练条数
-define(MAX_POLISH_NUM, 10000). % 强化随机基数

%% desc: 装备至少2条基础属性
-define(MIN_EQUIP_ATTRI_NUM, 2).

%% desc: 强化基础系数
-define(STREN_ATTRI_BASE_FACTOR, 1000).

%% 生命上限附加值
-define(HIT_POINT_MAX, 1).
%% 法力上限附加值
-define(MAGIC_MAX, 2).
%% 普攻附加值
-define(ATTACK, 3).
%% 仙攻附加值
-define(FATTACK, 4).
%% 魔攻附加值
-define(MATTACK, 5).
%% 妖攻附加值
-define(DATTACK, 6).
%% 普通防御附加值
-define(DEFENCE, 7).
%% 仙防附加值
-define(FDEFENCE, 8).
%% 魔防附加值
-define(MDEFENCE, 9).
%% 妖防附加值
-define(DDEFENCE, 10).
%% 妖防附加值
-define(DODGE, 11).
%% 妖防附加值
-define(HIT, 12).
%% 妖防附加值
-define(CRIT, 13).
%% 妖防附加值
-define(TOUGH, 14).

-define(POLISH_STAR_MIN, 1). % 洗炼最小星级
-define(POLISH_STAR_MAX, 10). % 洗炼最大星级

-define(ALL_STRENGTH_LENGTH, 11).						%% 全身强化装备个数
-define(ALL_STRENGTH_SUBTYPE_LIST, [?EQUIP_T_CAP, ?EQUIP_T_SHOULDER, ?EQUIP_T_WRISTER, ?EQUIP_T_ARMOR, ?EQUIP_T_BELT,
						   ?EQUIP_T_SHOES, ?EQUIP_T_NECK, ?EQUIP_T_FURNISHINGS, ?EQUIP_T_BRACELET, ?EQUIP_T_RING, ?EQUIP_T_WEAPON]).			%% 全身强化装备列表

-define(ALL_POILSH_LENGTH, 11).							%% 全身洗炼装备个数

-define(ALL_POLISH_MAX_INDEX, 10).			%% 全身洗炼最大字段（用于遍历）
-define(ALL_POLISH_MIN_INDEX, 2).			%% 全身洗炼最小字段（用于遍历）

%% 装备属性评分因子
-define(ATTR_FACTOR_ABS_DAMAGE, 		0.8).
-define(ATTR_FACTOR_ATTACK,				0.5).    
-define(ATTR_FACTOR_ATTR_ATTACK, 			0.6).  
-define(ATTR_FACTOR_FATTACK, 			0.6).  
-define(ATTR_FACTOR_MATTACK,			0.6).      
-define(ATTR_FACTOR_DATTACK, 			0.6).       
-define(ATTR_FACTOR_HIT_RATIO, 			0.25).       
-define(ATTR_FACTOR_CRIT_RATIO, 		0.25).       
-define(ATTR_FACTOR_DODGE_RATIO, 		0.25).       
-define(ATTR_FACTOR_TOUGH_RATIO, 		0.25).       
-define(ATTR_FACTOR_FDEFENSE, 			0.2).       
-define(ATTR_FACTOR_MDEFENSE, 			0.2).       
-define(ATTR_FACTOR_DDEFENSE, 			0.2).       
-define(ATTR_FACTOR_DEFENSE, 			0.25).       
-define(ATTR_FACTOR_HIT_POINT_MAX, 		0.05).       
-define(ATTR_FACTOR_MAGIC_MAX, 			0.1).       
