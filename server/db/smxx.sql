/*
MySQL Backup
Source Server Version: 5.1.50
Source Database: smxx
Date: 2013/9/29 15:57:51
*/


-- ----------------------------
--  Table structure for `ban_account_list`
-- ----------------------------
CREATE TABLE `ban_account_list` (
  `uid` bigint(20) NOT NULL COMMENT '角色ID',
  `nick` varchar(50) NOT NULL COMMENT '角色名',
  `account_name` varchar(50) NOT NULL COMMENT '账号',
  `end_time` int(10) NOT NULL COMMENT '封禁结束时间',
  `operator` varchar(50) DEFAULT '' COMMENT '操作员',
  `ban_reason` varchar(256) DEFAULT NULL COMMENT '封禁原因',
  `op_time` int(11) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='已封禁帐号列表';

-- ----------------------------
--  Table structure for `ban_ip_list`
-- ----------------------------
CREATE TABLE `ban_ip_list` (
  `ip` varchar(20) NOT NULL COMMENT 'IP',
  `end_time` int(11) NOT NULL COMMENT '封禁结束时间',
  `operator` varchar(50) DEFAULT '' COMMENT '操作员',
  `ban_reason` varchar(256) DEFAULT NULL COMMENT '封禁原因',
  `op_time` int(11) NOT NULL,
  PRIMARY KEY (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='已封禁IP列表';

-- ----------------------------
--  Table structure for `bones`
-- ----------------------------
CREATE TABLE `bones` (
  `uid` bigint(20) NOT NULL DEFAULT '0',
  `bones_info` varchar(128) DEFAULT '[]' COMMENT '根骨状况[{根骨类型,根骨等级,成功率}...]',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='根骨';

-- ----------------------------
--  Table structure for `buff`
-- ----------------------------
CREATE TABLE `buff` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `buff1` varchar(1024) COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, ExpireTime}]参考buff_util.erl',
  `buff2` varchar(1024) COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, Cd, RemTimes},...]参考buff_util.erl',
  `buff3` varchar(1024) COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, Cd, RemNumer},...]参考buff_util.erl',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='物品buff记录表\r\n';

-- ----------------------------
--  Table structure for `buy_npc_shop_log`
-- ----------------------------
CREATE TABLE `buy_npc_shop_log` (
  `uid` bigint(20) NOT NULL,
  `shopid` int(11) NOT NULL,
  `gtid` int(11) NOT NULL,
  `buy_num` int(11) NOT NULL,
  `buy_time` int(11) NOT NULL,
  PRIMARY KEY (`uid`,`shopid`,`gtid`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='购买npc商店日志';

-- ----------------------------
--  Table structure for `buy_shop_log`
-- ----------------------------
CREATE TABLE `buy_shop_log` (
  `uid` bigint(20) NOT NULL,
  `shoptabid` int(11) NOT NULL,
  `gtid` int(11) NOT NULL,
  `buy_num` int(11) NOT NULL,
  `buy_time` int(11) NOT NULL,
  PRIMARY KEY (`uid`,`shoptabid`,`gtid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='购买商城物品日志';

-- ----------------------------
--  Table structure for `casting_polish`
-- ----------------------------
CREATE TABLE `casting_polish` (
  `gid` bigint(11) unsigned NOT NULL DEFAULT '0' COMMENT '装备ID',
  `uid` bigint(11) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `cur_attri` varchar(150) NOT NULL DEFAULT '[]' COMMENT '当前洗炼属性 {唯一ID，属性ID，星级，加成属性，锁定状态}',
  `new_attri` varchar(150) NOT NULL DEFAULT '[]' COMMENT '新洗炼属性 {唯一ID，属性ID，星级，加成属性，锁定状态}',
  PRIMARY KEY (`gid`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='洗炼属性表';

-- ----------------------------
--  Table structure for `charge`
-- ----------------------------
CREATE TABLE `charge` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `order_id` varchar(30) NOT NULL COMMENT '充值订单号',
  `game_id` varchar(20) NOT NULL COMMENT '游戏编号',
  `server_id` int(10) NOT NULL COMMENT '服务器编号',
  `account_id` varchar(50) NOT NULL COMMENT '4399平台用户唯一标识',
  `pay_way` tinyint(4) NOT NULL COMMENT '1：手游币兑换2：神州行3：联通4：支付宝',
  `amount` int(10) NOT NULL COMMENT '支付金额',
  `gold` int(10) NOT NULL,
  `order_status` tinyint(3) NOT NULL COMMENT 'S-成功支付F-支付失败',
  `handle_status` tinyint(3) NOT NULL,
  `dim_lev` int(10) NOT NULL,
  `create_time` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COMMENT='充值表';

-- ----------------------------
--  Table structure for `config_server`
-- ----------------------------
CREATE TABLE `config_server` (
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '编号Id',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '服务器名字',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='服务器列表';

-- ----------------------------
--  Table structure for `cultivation`
-- ----------------------------
CREATE TABLE `cultivation` (
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `lv` tinyint(4) NOT NULL COMMENT '修为等级',
  `property` varchar(256) NOT NULL DEFAULT '[]' COMMENT '修为属性[{属性类型,属性值}..]',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `daily_task_finish`
-- ----------------------------
CREATE TABLE `daily_task_finish` (
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `type` tinyint(4) NOT NULL COMMENT '任务类型',
  `state` tinyint(2) NOT NULL COMMENT '任务状态',
  `count_detail` varchar(20) NOT NULL COMMENT '本日可用轮数{可用轮数，已用轮数}',
  `cycle_datil` varchar(20) NOT NULL COMMENT '每轮可用次数 {可触发次数,已触发次数}',
  `trigger_detail` varchar(32) NOT NULL COMMENT '每次触发任务数{每次可同时触发任务数,已触发任务数}',
  `reset_time` int(17) NOT NULL DEFAULT '0' COMMENT '上次重置时间',
  `total` int(20) NOT NULL COMMENT '总完成次数',
  `trigger_time` varchar(32) NOT NULL COMMENT '触发时间',
  PRIMARY KEY (`uid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `donttalk`
-- ----------------------------
CREATE TABLE `donttalk` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `start_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '开始禁言时间(秒)',
  `duration` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '持续时间(秒)',
  `reason` varchar(100) NOT NULL DEFAULT '无理' COMMENT '理由说明',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色禁言表';

-- ----------------------------
--  Table structure for `dungeon_daily`
-- ----------------------------
CREATE TABLE `dungeon_daily` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '平台账号ID',
  `sid` int(10) DEFAULT '0' COMMENT '正在进行的副本ID',
  `times` int(10) DEFAULT '0' COMMENT '当前副本组通关次数',
  `begin_time` int(11) DEFAULT '0' COMMENT '副本开始的时间',
  `last_time` int(11) DEFAULT '0' COMMENT '最后一次在副本里活动的时间',
  `triggers` varchar(250) DEFAULT '[]' COMMENT '触发器[]',
  `pre_sid` int(11) DEFAULT '0' COMMENT '进入副本前的场景ID',
  `pre_sx` int(11) DEFAULT '0' COMMENT '场景中的X',
  `pre_sy` int(11) DEFAULT '0',
  `pass_assess` int(4) DEFAULT '0' COMMENT '通关评价',
  `pass_type` int(11) DEFAULT '0' COMMENT 'pass_type',
  `pass_value` varchar(250) DEFAULT '[]',
  `rewards` varchar(250) DEFAULT '[]' COMMENT '副本奖励',
  `monsters` varchar(1024) DEFAULT '[]' COMMENT '副本怪物',
  `dungeon_score` varchar(250) DEFAULT '[]' COMMENT '副本评分',
  `dialogue` varchar(3000) DEFAULT '[]' COMMENT '副本剧情',
  `obj_state` varchar(1024) DEFAULT '[]' COMMENT '副本物件状态',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `dungeon_finish`
-- ----------------------------
CREATE TABLE `dungeon_finish` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '平台账号ID',
  `dlv` varchar(255) DEFAULT '[]',
  `dlv0` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv1` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv2` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv3` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv4` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv5` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv6` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv7` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv8` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv9` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv10` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv11` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv12` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv13` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv14` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv15` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv16` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv17` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv18` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  `dlv19` varchar(250) DEFAULT '[]' COMMENT '1-10级打过的副本',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `dungeon_master`
-- ----------------------------
CREATE TABLE `dungeon_master` (
  `sid` int(10) NOT NULL DEFAULT '0' COMMENT '副本ID',
  `gid` int(10) NOT NULL DEFAULT '0' COMMENT '副本组ID',
  `muid` bigint(20) NOT NULL DEFAULT '0' COMMENT '副本霸主UID',
  `score` int(10) NOT NULL DEFAULT '0' COMMENT '副本霸主积分',
  `update_time` int(10) DEFAULT '0' COMMENT '副本修改时间。',
  `nick` varchar(50) NOT NULL DEFAULT '' COMMENT '霸主名字',
  PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `feedback`
-- ----------------------------
CREATE TABLE `feedback` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '类型(1-Bug/2-投诉/3-建议/4-其它)',
  `state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '状态(已回复1/未回复0)',
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '玩家名',
  `content` mediumtext NOT NULL COMMENT '内容',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT 'Unix时间戳',
  `ip` varchar(100) DEFAULT '' COMMENT '玩家IP',
  `server` varchar(100) DEFAULT '' COMMENT '服务器',
  `gm` varchar(100) DEFAULT '' COMMENT '游戏管理员',
  `reply` text COMMENT '回复内容[{Nick,Content}....]',
  `reply_time` int(11) DEFAULT '0' COMMENT '回复时间',
  PRIMARY KEY (`id`),
  KEY `player_id` (`uid`) USING BTREE,
  KEY `player_name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家反馈';

-- ----------------------------
--  Table structure for `goods`
-- ----------------------------
CREATE TABLE `goods` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '玩家物品Id',
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `pet_id` tinyint(4) unsigned NOT NULL DEFAULT '0' COMMENT '宠物Id（装备穿在宠物身上时对应的武将唯一Id）',
  `gtid` int(11) NOT NULL DEFAULT '0' COMMENT '物品类型编号',
  `location` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '物品所在位置',
  `cell` smallint(5) NOT NULL DEFAULT '0' COMMENT '物品所在格子位置',
  `num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '物品数量',
  `score` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '装备评分：非装备用0表示',
  `hole` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '镶孔数',
  `hole_goods` varchar(200) NOT NULL DEFAULT '[]' COMMENT '孔所镶物品类型ID',
  `polish_num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '洗练次数',
  `stren_lv` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '强化等级',
  `stren_percent` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '强化完美度',
  `add_succ_rate` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '增加强化成功率',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型(参考宏定义)',
  `subtype` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '物品子类型(参考宏定义)',
  `quality` tinyint(1) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色',
  `sell_price` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品出售价格',
  `career` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '职业限制，0为不限',
  `gender` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '性别限制，0为女，1为男，2为男女不限',
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '等级限制，0为不限',
  `max_num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '可叠加数，0为不可叠加',
  `bind` tinyint(2) unsigned NOT NULL DEFAULT '0' COMMENT '绑定状态,0不限制,2装备绑定,3已绑定',
  `expire_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '有效期，0为不限，单位为秒',
  `suit_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '套装ID，0为不是套装',
  `gilding_lv` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '镀金等级',
  `goods_cd` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品使用cd',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=530000007135 DEFAULT CHARSET=utf8 COMMENT='玩家物品记录';

-- ----------------------------
--  Table structure for `goods_attribute`
-- ----------------------------
CREATE TABLE `goods_attribute` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '编号',
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '角色ID',
  `gid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '物品编号ID',
  `attribute_type` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '属性类型，1 强化，2 强化+4，3 强化+7，5 镶嵌',
  `stone_type_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '宝石编号ID，无宝石为0',
  `attribute_id` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '属性类型Id：0-气血，1-物理攻击。。。',
  `value` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '属性值',
  `value_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '属性值类型，0为数值，1为百分比',
  `hole_seq` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '镶嵌宝石孔位置',
  `status` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '是否生效，1为生效，0为不生效',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `gid_hole_seq` (`gid`,`hole_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='物品属性表';

-- ----------------------------
--  Table structure for `goods_cd`
-- ----------------------------
CREATE TABLE `goods_cd` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0',
  `gtid` int(11) NOT NULL DEFAULT '0' COMMENT '物品类型id',
  `expire_time` int(11) NOT NULL DEFAULT '0' COMMENT '过期时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='物品使用cd';

-- ----------------------------
--  Table structure for `goods_polish`
-- ----------------------------
CREATE TABLE `goods_polish` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '玩家物品ID',
  `uid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '玩家id',
  `gtid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型id',
  `type` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型',
  `stype` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '物品子类型',
  `quality` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '品质，决定颜色',
  `num` mediumint(8) NOT NULL COMMENT '当前数量',
  `cell` mediumint(8) NOT NULL COMMENT '所在格子',
  `polish_lv` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '洗练等级',
  `polish_attr` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '洗练所得属性类型',
  `use_times` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '使用次数',
  `expire_times` bigint(20) NOT NULL COMMENT '有效时间',
  `spec` text COMMENT '特殊字段',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `goods_strength`
-- ----------------------------
CREATE TABLE `goods_strength` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '玩家物品id',
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家id',
  `gtid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型id',
  `type` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型',
  `stype` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '物品子类型',
  `quality` mediumint(8) unsigned NOT NULL DEFAULT '0' COMMENT '品质，决定颜色',
  `num` mediumint(8) NOT NULL COMMENT '当前数量',
  `cell` mediumint(8) NOT NULL COMMENT '所在格子',
  `streng_lv` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '强化等级',
  `use_times` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '使用次数',
  `expire_times` bigint(20) NOT NULL COMMENT '有效时间',
  `spec` text COMMENT '特殊字段',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `guild`
-- ----------------------------
CREATE TABLE `guild` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '帮派编号',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '帮派名称',
  `chief_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '帮主角色',
  `chief_name` varchar(50) NOT NULL DEFAULT '' COMMENT '帮主名字',
  `announce` varchar(2000) DEFAULT '' COMMENT '帮派宣言',
  `level` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帮派等级',
  `current_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '当前人数',
  `elite_num` int(11) NOT NULL DEFAULT '0' COMMENT '当前长老数',
  `devo` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帮派贡献度',
  `fund` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帮派资金',
  `upgrade_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '最近升级时间',
  `create_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '创建时间',
  `maintain_time` int(11) NOT NULL DEFAULT '0' COMMENT '下次维护时间',
  `limit_members` int(11) NOT NULL DEFAULT '10' COMMENT '成员数量上限',
  `state` int(1) unsigned NOT NULL DEFAULT '0' COMMENT '弹劾盟主时为1',
  `accuse_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '发起弹劾的成员ID',
  `accuse_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '弹劾到期时间',
  `against` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '反对分数',
  `agree` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '赞成分数',
  `accuse_num` int(11) NOT NULL DEFAULT '0' COMMENT '劾弹次数',
  `friend_guild_id` int(11) DEFAULT '0' COMMENT '结盟帮派',
  `voice_channel` varchar(100) DEFAULT '',
  `qqNumber` varchar(100) DEFAULT NULL,
  `maintain_cost` int(11) NOT NULL DEFAULT '0' COMMENT '帮派维护费用',
  `debt_count` int(11) NOT NULL DEFAULT '0' COMMENT '欠费天数',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=360000057 DEFAULT CHARSET=utf8 COMMENT='帮派';

-- ----------------------------
--  Table structure for `guild_apply`
-- ----------------------------
CREATE TABLE `guild_apply` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '角色ID',
  `guild_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帮派ID',
  `nick` varchar(50) NOT NULL DEFAULT '' COMMENT '角色昵称',
  `gender` tinyint(3) NOT NULL DEFAULT '0' COMMENT '性别',
  `career` tinyint(3) NOT NULL DEFAULT '0' COMMENT '职业',
  `level` int(5) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `force` int(5) NOT NULL DEFAULT '0' COMMENT '玩家战斗力',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT '申请时间',
  PRIMARY KEY (`uid`,`guild_id`),
  KEY `uid` (`uid`),
  KEY `guild_id` (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='帮派申请';

-- ----------------------------
--  Table structure for `guild_member`
-- ----------------------------
CREATE TABLE `guild_member` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `guild_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '帮派ID',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '帮派名称',
  `nick` varchar(50) NOT NULL DEFAULT '' COMMENT '角色昵称',
  `gender` int(5) NOT NULL DEFAULT '0' COMMENT '性别',
  `career` int(5) NOT NULL DEFAULT '0' COMMENT '职业',
  `level` int(5) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `force` int(5) NOT NULL DEFAULT '0' COMMENT '玩家战斗力',
  `position` int(2) unsigned NOT NULL DEFAULT '10' COMMENT '1帮主 2副帮主 3长老 4 精英 中间预留 10-帮众(最低)',
  `devo` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '总贡献度',
  `coin` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '累计捐献铜钱',
  `gold` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '累计捐献元宝',
  `today_devo` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '今日贡献度',
  `devo_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次捐献时间',
  `remain_devo` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '剩余贡献度',
  `vote` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '1赞成票2反对票',
  `accuse_time` int(11) NOT NULL DEFAULT '0' COMMENT '投票过期时间',
  `title` smallint(5) NOT NULL DEFAULT '0' COMMENT '称号等级',
  `last_login_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登录时间',
  `sklist` varchar(255) DEFAULT '[]' COMMENT '技能列表[{Id, Level}]',
  PRIMARY KEY (`uid`),
  KEY `uid` (`uid`),
  KEY `guild_id` (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='帮派成员';

-- ----------------------------
--  Table structure for `heaven`
-- ----------------------------
CREATE TABLE `heaven` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `reset_time` int(17) NOT NULL DEFAULT '0',
  `heaven_count` int(10) NOT NULL DEFAULT '0' COMMENT '天道令数量',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COMMENT='天道令信息';

-- ----------------------------
--  Table structure for `infant_ctrl_byuser`
-- ----------------------------
CREATE TABLE `infant_ctrl_byuser` (
  `account_id` int(11) NOT NULL DEFAULT '0' COMMENT '平台ID',
  `total_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '防沉迷累计登陆时间(unix time)',
  `last_login_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '上次登陆时间(unix time)',
  PRIMARY KEY (`account_id`),
  KEY `accid` (`account_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `leader`
-- ----------------------------
CREATE TABLE `leader` (
  `uid` bigint(20) NOT NULL COMMENT '玩家UID',
  `navi_list` varchar(1024) NOT NULL COMMENT '系统面板已成功引导的列表',
  `open_list` varchar(1024) NOT NULL,
  `start_sk_list` varchar(128) NOT NULL,
  `end_sk_list` varchar(128) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `mail`
-- ----------------------------
CREATE TABLE `mail` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '信件id',
  `uid` bigint(11) NOT NULL COMMENT '收件人id',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '类型(0系统)',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT '发送时间戳(秒)',
  `content` int(11) NOT NULL DEFAULT '0' COMMENT '信件正文ID',
  `goods_list` varchar(255) NOT NULL DEFAULT '[]' COMMENT '物品列表[{GoodsId, GTypeId, Num},...]',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=375 DEFAULT CHARSET=utf8 COMMENT='信件信息';

-- ----------------------------
--  Table structure for `market_selling`
-- ----------------------------
CREATE TABLE `market_selling` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '挂售编号',
  `seller_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '挂售玩家id',
  `goods_uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '挂售物品实例id',
  `goods_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '挂售物品模板id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '挂售价格',
  `num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '数量',
  `start_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '挂售时间',
  `end_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '过期时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8 COMMENT='帮派';

-- ----------------------------
--  Table structure for `meridian`
-- ----------------------------
CREATE TABLE `meridian` (
  `player_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '玩家Id',
  `mer_detail_1` varchar(256) NOT NULL COMMENT '玩家经脉1详细数据[{MerType,Merlv}...]',
  `mer_detail_2` varchar(256) NOT NULL COMMENT '玩家经脉2详细数据[{MerType,Merlv}...]',
  `mer_state` varchar(16) NOT NULL COMMENT '玩家修炼经脉阶段{state1, state2}',
  `cool_down` varchar(64) NOT NULL DEFAULT '{0,0}' COMMENT '剩余的冷却时间 {玩家开始修炼时间戳,剩余冷却时间，状态}',
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB AUTO_INCREMENT=530000007823 DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `mount`
-- ----------------------------
CREATE TABLE `mount` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态1:骑 2休息',
  `exp` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '经验值',
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '等级(阶)',
  `star` smallint(5) NOT NULL DEFAULT '0' COMMENT '星级(最大10星)',
  `fashion` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '当前幻化',
  `force` int(11) NOT NULL DEFAULT '0' COMMENT '座骑战斗力',
  `skill_times` tinyint(3) NOT NULL DEFAULT '0' COMMENT '技能升级次数',
  `skill_list` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '技能列表[{SkillId, Lv, Exp},...]',
  `fashion_list` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '幻化列表[{Fid, Expired},...], Fid幻化ID, Expire过期时间',
  `old_fashion_list` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '过期幻化列表',
  PRIMARY KEY (`uid`),
  KEY `level` (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家座骑记录';

-- ----------------------------
--  Table structure for `notice`
-- ----------------------------
CREATE TABLE `notice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) DEFAULT NULL,
  `claz` tinyint(2) DEFAULT '0' COMMENT '通知类型：1-系统补偿；2-登陆奖励，3-世界BOSS，4-新手奖励，5-竞技场，6-天宫探宝，7-联盟战赛事奖励,8-首冲礼包,9-联盟战据点收益奖励'',',
  `type` tinyint(2) DEFAULT '0' COMMENT '消息类型(0-系统通知，1 => 竞技场；2 => 联盟; 3 => 活动; 4 => 好友  ;5=>世界BOSS; 6=>好友祝福 ; 7=>好友  ;8=>祝福; 9=> 联盟战,99 -系统发给个人的邮件',
  `cntt` varchar(4000) CHARACTER SET utf8 DEFAULT '""' COMMENT '消息内容',
  `tmsp` int(11) DEFAULT NULL COMMENT '消息生成时间戳',
  `exp` int(11) DEFAULT '0' COMMENT '附件：体力',
  `eng` int(11) DEFAULT '0' COMMENT '附件：经验',
  `coin` int(11) DEFAULT '0' COMMENT '附件：铜钱',
  `prstg` int(11) DEFAULT '0' COMMENT '战勋奖励',
  `sprt` int(11) DEFAULT '0' COMMENT '附件：灵力',
  `soul` int(11) DEFAULT '0' COMMENT '元魂',
  `gold` int(11) DEFAULT '0' COMMENT '附件：元宝',
  `goods` varchar(255) CHARACTER SET utf8 DEFAULT '[]' COMMENT '附件：物品[{goodtypeid,number},...]',
  `sts` tinyint(2) DEFAULT '1' COMMENT '状态：-1-审核不通过，0-未审核，1-未领取，2-已领取',
  `rtmsp` int(11) DEFAULT '0' COMMENT '消息读取时间戳',
  `otid` int(11) DEFAULT '0' COMMENT '其它ID，例如好友ID',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=cp850;

-- ----------------------------
--  Table structure for `opera`
-- ----------------------------
CREATE TABLE `opera` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `operaDialogue` varchar(8000) NOT NULL DEFAULT '[]' COMMENT '已播放过的剧情对话',
  `operaAnimation` varchar(8000) NOT NULL DEFAULT '[]' COMMENT '已播放过的剧情动画',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色禁言表';

-- ----------------------------
--  Table structure for `pet`
-- ----------------------------
CREATE TABLE `pet` (
  `uid` bigint(20) NOT NULL,
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '昵称',
  `attack` int(11) NOT NULL DEFAULT '0' COMMENT '普通攻击力',
  `attr_attack` int(11) NOT NULL DEFAULT '0' COMMENT '属攻',
  `attack_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '属攻类型:1仙攻,2魔攻,3妖攻',
  `hit` int(11) NOT NULL DEFAULT '0' COMMENT '命中',
  `crit` int(11) NOT NULL DEFAULT '0' COMMENT '暴击',
  `fighting` int(11) NOT NULL DEFAULT '0' COMMENT '战力',
  `quality_lv` tinyint(4) NOT NULL DEFAULT '0' COMMENT '品阶',
  `fail_times` int(11) NOT NULL DEFAULT '0' COMMENT '升级品级失败次数',
  `growth_lv` smallint(6) NOT NULL DEFAULT '0' COMMENT '成长值',
  `growth_progress` smallint(6) NOT NULL DEFAULT '0' COMMENT '成长进度',
  `aptitude_lv` smallint(6) NOT NULL DEFAULT '0' COMMENT '资质',
  `aptitude_progress` smallint(6) NOT NULL DEFAULT '0' COMMENT '资质进度',
  `status` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0休息,1参战',
  `skill_hole` tinyint(4) NOT NULL DEFAULT '0' COMMENT '开启技能槽总数',
  `skill_list` varchar(150) NOT NULL DEFAULT '[]' COMMENT '技能ID列表[{SkillId, Level}]',
  `current_facade` int(11) NOT NULL DEFAULT '0' COMMENT '当前外观id',
  `old_facade` int(11) NOT NULL DEFAULT '0' COMMENT '原来外观id',
  `facade_list` varchar(300) NOT NULL DEFAULT '[]' COMMENT '外观列表[]',
  `suit_list` varchar(100) NOT NULL DEFAULT '[]' COMMENT '套装列表',
  `create_time` int(11) NOT NULL COMMENT '创建时间',
  `battle_attr` tinyint(4) NOT NULL DEFAULT '0' COMMENT '战斗属性',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='宠物表';

-- ----------------------------
--  Table structure for `player`
-- ----------------------------
CREATE TABLE `player` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `account_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '平台账号ID',
  `account_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账号',
  `nick` varchar(50) NOT NULL DEFAULT '' COMMENT '玩家名',
  `type` smallint(5) NOT NULL DEFAULT '1' COMMENT '玩家身份 1- 普通玩家 2 - 指导员 3 - gm',
  `icon` int(11) NOT NULL DEFAULT '0' COMMENT '玩家头像ID',
  `reg_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册时间',
  `logout_time` int(11) NOT NULL DEFAULT '0' COMMENT '上次离线时间',
  `last_login_time` int(11) NOT NULL DEFAULT '0' COMMENT '最后登陆时间',
  `last_login_ip` varchar(20) NOT NULL DEFAULT '' COMMENT '最后登陆IP',
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '玩家状态（0正常、1禁止、2战斗中、3死亡、4挂机、5打坐）',
  `gender` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '性别 1男 2女',
  `career` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '职业(0:未定义，1: 神 2:魔 3:妖)',
  `gold` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '元宝',
  `bgold` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '绑定元宝',
  `coin` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '铜钱',
  `bcoin` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '绑定铜钱',
  `vip` int(11) NOT NULL DEFAULT '0' COMMENT 'VIP类型，0不是VIP，其他参考common.hrl',
  `vip_expire_time` int(11) NOT NULL DEFAULT '0' COMMENT 'VIP过期时间(秒)',
  `scene` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '场景ID',
  `cell_num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '背包格子数',
  `level` smallint(5) unsigned NOT NULL DEFAULT '1' COMMENT '等级',
  `exp` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '经验',
  `online_flag` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '在线标记，0不在线 1在线',
  `resolut_x` int(8) NOT NULL DEFAULT '0' COMMENT '分辨率 X',
  `resolut_y` int(8) NOT NULL DEFAULT '0' COMMENT '分辨率 Y',
  `liveness` int(11) NOT NULL DEFAULT '0' COMMENT '活跃度',
  `camp` tinyint(4) NOT NULL DEFAULT '-1' COMMENT '阵营(国籍)',
  `lilian` int(11) NOT NULL DEFAULT '0' COMMENT '历练值',
  `switch` int(11) NOT NULL DEFAULT '0' COMMENT '状态开关码1:功能开 0:功能关，位定义参考common.hrl',
  `guild_id` int(11) NOT NULL DEFAULT '0' COMMENT '派帮ID(无帮派:0)',
  `guild_name` varchar(50) NOT NULL DEFAULT '' COMMENT '帮派名称',
  `guild_post` tinyint(4) NOT NULL DEFAULT '0' COMMENT '帮派职位(0为小兵)',
  `force` int(11) NOT NULL DEFAULT '0' COMMENT '战斗力',
  `battle_attr` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '战斗结构体',
  `other` tinyint(4) NOT NULL DEFAULT '0' COMMENT '其他信息',
  `login_times` int(10) NOT NULL DEFAULT '0' COMMENT '登陆次数',
  `freefly` int(11) NOT NULL DEFAULT '0' COMMENT 'VIP玩家免费使用跟斗云次数',
  `max_force` int(11) NOT NULL DEFAULT '0' COMMENT '最高战力',
  `adore_count` int(11) NOT NULL DEFAULT '0' COMMENT '被崇拜次数',
  `adore_detail` varchar(128) NOT NULL DEFAULT '{0,0}' COMMENT '排行榜崇拜详细信息{上次崇拜时间，剩余次数}',
  `leader_flag` tinyint(11) NOT NULL DEFAULT '0' COMMENT '新手引导标识',
  `login_level` smallint(5) DEFAULT '0' COMMENT '登陆时等级',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick` (`nick`),
  KEY `level` (`level`) USING BTREE,
  KEY `account_name` (`account_name`) USING BTREE,
  KEY `last_login_time` (`last_login_time`) USING BTREE,
  KEY `reg_time` (`reg_time`) USING BTREE,
  KEY `account_id` (`account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=530000007824 DEFAULT CHARSET=utf8 COMMENT='角色基本信息';

-- ----------------------------
--  Table structure for `rand_shop`
-- ----------------------------
CREATE TABLE `rand_shop` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `level` smallint(5) NOT NULL DEFAULT '1' COMMENT '物品列表',
  `bless` int(11) NOT NULL DEFAULT '0' COMMENT '当前祝福值',
  `item_list` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '物品列表',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色禁言表';

-- ----------------------------
--  Table structure for `rela_friend_req`
-- ----------------------------
CREATE TABLE `rela_friend_req` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '好友请求记录ID',
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '被添加的玩家ID',
  `req_uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '发出请求的玩家ID',
  `req_nick` char(50) NOT NULL COMMENT '发出请求的玩家名',
  `req_career` tinyint(4) NOT NULL DEFAULT '0' COMMENT '发出请求的玩家ID',
  `req_gender` tinyint(4) NOT NULL DEFAULT '0' COMMENT '发出请求的玩家性别',
  `req_camp` tinyint(4) NOT NULL DEFAULT '0' COMMENT '发出请求的玩家阵营',
  `req_level` smallint(6) NOT NULL DEFAULT '0' COMMENT '发出请求的玩家ID(秒）',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT '发出请求时间（秒）',
  `response` tinyint(4) NOT NULL DEFAULT '0' COMMENT '未回应0, 同意好友添加1, 2:不同意好友添加',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `req_uid` (`req_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='好友请求表';

-- ----------------------------
--  Table structure for `relation`
-- ----------------------------
CREATE TABLE `relation` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家id',
  `bless_times` int(5) NOT NULL DEFAULT '0' COMMENT '今天祝福次数',
  `max_friend` int(5) NOT NULL DEFAULT '0' COMMENT '最大好友数目',
  `max_blacklist` int(5) NOT NULL COMMENT '最大黑名单数目',
  `max_foe` int(5) NOT NULL DEFAULT '0' COMMENT '最大仇人数目',
  `friend_list` varchar(2048) NOT NULL DEFAULT '[]' COMMENT '好友列表格式 [{玩家id,玩家姓名,玩家头像,好感度}, ...]',
  `foe_list` varchar(2048) NOT NULL DEFAULT '[]' COMMENT '仇人列表格式 [{玩家id,玩家姓名,玩家头像,好感度}...]',
  `black_list` varchar(2048) NOT NULL DEFAULT '[]' COMMENT '[{玩家id,玩家姓名,玩家头像}...]',
  `recent_list` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '最近联系人列表格式 [{Uid, Time, Name, Career, Gender}, ...], Time 最近一次发生关系时间(秒)',
  `flower` int(7) NOT NULL DEFAULT '0' COMMENT '玩家收到的鲜花',
  `flower_avail` varchar(32) NOT NULL DEFAULT '{3,0}' COMMENT '{玩家每天免费送花次数,已用次数}',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='关系列表';

-- ----------------------------
--  Table structure for `scene_gift`
-- ----------------------------
CREATE TABLE `scene_gift` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `scene_gift` varchar(3000) NOT NULL DEFAULT '[]' COMMENT '已领取过的场景下载礼包',
  `current_gift` varchar(3000) NOT NULL DEFAULT '[]' COMMENT '已领取过的场景下载礼包',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色禁言表';

-- ----------------------------
--  Table structure for `server`
-- ----------------------------
CREATE TABLE `server` (
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '编号Id',
  `domain` int(11) unsigned NOT NULL DEFAULT '1' COMMENT '分区号',
  `ip` varchar(50) NOT NULL DEFAULT '' COMMENT 'ip地址',
  `port` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '端口号',
  `node` varchar(50) NOT NULL DEFAULT '' COMMENT '节点',
  `num` int(11) DEFAULT '0' COMMENT '节点用户数',
  `stop_access` tinyint(5) NOT NULL DEFAULT '0' COMMENT '是否停止登陆该节点，0为可以登录，1为停止登陆',
  `start_time` int(11) NOT NULL DEFAULT '0' COMMENT '开服时间',
  `state` tinyint(11) NOT NULL DEFAULT '0' COMMENT '1-新开；2-火爆；3-良好；4-流畅；5-维护。',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='服务器列表';

-- ----------------------------
--  Table structure for `server_player`
-- ----------------------------
CREATE TABLE `server_player` (
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID，全平台唯一',
  `accid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '玩家Id',
  `serv_id` int(50) NOT NULL DEFAULT '0' COMMENT '服务器标识',
  `domain` smallint(4) NOT NULL DEFAULT '0' COMMENT '大区标识',
  `acc_name` varchar(50) NOT NULL DEFAULT '' COMMENT '账号名字',
  `nick` varchar(50) NOT NULL DEFAULT '' COMMENT '角色名字',
  `sex` smallint(2) NOT NULL DEFAULT '0' COMMENT '角色性别',
  `career` smallint(2) NOT NULL DEFAULT '0' COMMENT '角色职业',
  `lv` int(4) NOT NULL DEFAULT '0' COMMENT '角色等级',
  `icon` int(4) NOT NULL DEFAULT '0' COMMENT '图标',
  `last_login` int(11) NOT NULL DEFAULT '0' COMMENT '最后登录时间',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='服务器列表';

-- ----------------------------
--  Table structure for `skill`
-- ----------------------------
CREATE TABLE `skill` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '角色id',
  `skill_list` varchar(100) NOT NULL DEFAULT '[]' COMMENT '已学习的技能ID列表[{SkillId, Level}]',
  `cur_skill_list` varchar(100) NOT NULL DEFAULT '[]' COMMENT '当前正在使用的技能的ID[{SkillId, Level},...]',
  `skill_point` varchar(32) NOT NULL DEFAULT '{0,0}' COMMENT '技能点{已用点数,未用点数}',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='技能';

-- ----------------------------
--  Table structure for `sys_announce`
-- ----------------------------
CREATE TABLE `sys_announce` (
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '消息ID',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '公告类型：\r\n1 - 1级公告，会在跑马灯出现。\r\n2 - 2级公告，会在系统公告频道出现，红字。\r\n3 - 3级公告，会在系统频道出现，普通字。',
  `begin_time` int(11) NOT NULL DEFAULT '0' COMMENT '公告开始时间（unixtime格式、0为立即开始）',
  `end_time` int(11) NOT NULL DEFAULT '0' COMMENT '系统公告停止时间（unixtime格式、0则永不停止）',
  `interval` int(4) NOT NULL DEFAULT '0' COMMENT '公告发送时间间隔，单位分钟，0为不发送。',
  `next_time` int(11) NOT NULL DEFAULT '0' COMMENT '下次发送时间（untime格式、0为尚未发送）',
  `times` int(4) NOT NULL DEFAULT '0' COMMENT '发送次数（0为不限次数）',
  `content` int(11) NOT NULL DEFAULT '0' COMMENT '公告内容来自 temp_tips.id',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED;

-- ----------------------------
--  Table structure for `system_config`
-- ----------------------------
CREATE TABLE `system_config` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家Id',
  `shield_role` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '蔽屏附近玩家和宠物，0：不屏蔽；1：屏蔽',
  `shield_skill` tinyint(1) NOT NULL DEFAULT '0' COMMENT '屏蔽技能特效， 0：不屏蔽；1：屏蔽',
  `shield_rela` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '屏蔽好友请求，0：不屏蔽；1：屏蔽',
  `shield_team` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '屏蔽组队邀请，0：不屏蔽；1：屏蔽',
  `shield_chat` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '屏蔽聊天传闻，0：不屏蔽；1：屏蔽',
  `fasheffect` tinyint(1) NOT NULL DEFAULT '0' COMMENT '时装显示(0对别人显示，1对别人不显示)',
  `music` mediumint(8) unsigned NOT NULL DEFAULT '50' COMMENT '游戏音乐，默认值为50',
  `soundeffect` mediumint(8) NOT NULL DEFAULT '50' COMMENT '游戏音效，默认值为50',
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='玩家系统设置';

-- ----------------------------
--  Table structure for `task_daily`
-- ----------------------------
CREATE TABLE `task_daily` (
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '任务类型',
  `state` tinyint(4) NOT NULL DEFAULT '0' COMMENT '状态',
  `used_trigger_count` tinyint(4) NOT NULL DEFAULT '0' COMMENT '已使用轮数',
  `used_cycle_count` tinyint(4) NOT NULL DEFAULT '0' COMMENT '当前这一轮， 已使用的次数',
  `trigger_count` tinyint(4) NOT NULL DEFAULT '0' COMMENT '已接日常任务数量',
  `reset_time` int(17) NOT NULL DEFAULT '0' COMMENT '上次重置时间',
  `total` int(17) NOT NULL DEFAULT '0' COMMENT '总的完成次数',
  `trigger_time` varchar(32) DEFAULT '' COMMENT '触发时间'
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='日常任务统计表';

-- ----------------------------
--  Table structure for `task_finish`
-- ----------------------------
CREATE TABLE `task_finish` (
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `td1` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '1-10级任务ID',
  `td2` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '11-20级任务ID',
  `td3` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '21-30级任务ID',
  `td4` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '31-40级任务ID',
  `td5` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '41-50级任务ID',
  `td6` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '51-60级任务ID',
  `td7` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '61-70级任务ID',
  `td` varchar(10) DEFAULT '[]' COMMENT '任务ID',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `task_heaven`
-- ----------------------------
CREATE TABLE `task_heaven` (
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家id, 主键',
  `reset_time` int(11) NOT NULL DEFAULT '0' COMMENT '刷新事件',
  `publish_count` smallint(6) NOT NULL DEFAULT '0' COMMENT '当天发布数量',
  `publish_heavens` varchar(64) NOT NULL DEFAULT '{}' COMMENT '发布的天道令数量,依次是天,地,玄,黄,{1,1,1,1}',
  `receive_count` smallint(6) NOT NULL DEFAULT '0' COMMENT '当天领取的次数',
  `receive_heavens` varchar(64) NOT NULL DEFAULT '{}' COMMENT '领取的天道令数量,依次是天,地,玄,黄,{1,1,1,1}',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家天道令数据';

-- ----------------------------
--  Table structure for `task_master`
-- ----------------------------
CREATE TABLE `task_master` (
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `master_task` varchar(128) NOT NULL DEFAULT '[]' COMMENT '师门令任务, 格式[{tid, grade, state},{tid, grade, state},{tid, grade, state}]',
  `refresh_time` int(11) NOT NULL DEFAULT '0' COMMENT '刷新时间',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家师门令，刷新列表';

-- ----------------------------
--  Table structure for `task_process`
-- ----------------------------
CREATE TABLE `task_process` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `tid` int(11) NOT NULL COMMENT '任务模板id',
  `state` tinyint(2) NOT NULL COMMENT '任务状态,0:新任务， 1:完成未提交',
  `trigger_time` int(17) NOT NULL COMMENT '触发时间',
  `type` tinyint(4) NOT NULL COMMENT '任务类型',
  `mark` varchar(60) NOT NULL COMMENT '任务进度',
  `grade` tinyint(4) NOT NULL DEFAULT '0' COMMENT '任务品质',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31968 DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_all_gem_reward`
-- ----------------------------
CREATE TABLE `temp_all_gem_reward` (
  `gem_num` int(10) NOT NULL COMMENT '全身宝石个数',
  `add_value` varchar(150) NOT NULL DEFAULT '[]' COMMENT '属性加成',
  PRIMARY KEY (`gem_num`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='全身宝石镶嵌加成';

-- ----------------------------
--  Table structure for `temp_all_stren_reward`
-- ----------------------------
CREATE TABLE `temp_all_stren_reward` (
  `stren_lv` int(10) NOT NULL COMMENT '强化等级',
  `stren_reward` varchar(150) NOT NULL COMMENT '强化属性加成',
  PRIMARY KEY (`stren_lv`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='全身强化加成表';

-- ----------------------------
--  Table structure for `temp_bones`
-- ----------------------------
CREATE TABLE `temp_bones` (
  `lv` int(3) NOT NULL AUTO_INCREMENT COMMENT '根骨id',
  `bones_val` int(7) NOT NULL COMMENT '根骨提升值(万分比)',
  `probability` int(7) NOT NULL DEFAULT '0' COMMENT '成功率(万分比)',
  `extend_pro` int(7) NOT NULL DEFAULT '0' COMMENT '反馈成功率(万分比)',
  PRIMARY KEY (`lv`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `temp_buff`
-- ----------------------------
CREATE TABLE `temp_buff` (
  `buff_id` int(11) NOT NULL DEFAULT '0' COMMENT 'BuffID',
  `name` varchar(50) NOT NULL DEFAULT '杂技' COMMENT 'buff名称\r\n',
  `desc` varchar(50) NOT NULL COMMENT 'buff描述\r\nvarchar 50',
  `relation_type` tinyint(4) DEFAULT '1' COMMENT '关系类型 （1.对选中目标施放 2.对自己施放）',
  `trigger_type` smallint(4) NOT NULL DEFAULT '0' COMMENT '作者:\r\nsmallint作用类型\r\n是BUFF触发技能用的\r\n0 一次性触发buff\r\n1 间隔性触发类buff,每隔一段时间触发一次\r\n2 被击性触发类buff	\r\n3持续一段时间作用\r\n4.概率性触发',
  `type` smallint(4) NOT NULL COMMENT 'smallint\r\n1-改变属性\r\n2-改变状态（无敌 不能移动）\r\n3-加减血类能量值\r\n4-系统类（如经验，情缘）\r\n5.改变外观 \r\n6-击退类\r\n7-冲锋类',
  `data` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '模板属性',
  `trigger_info` varchar(50) NOT NULL DEFAULT '[]' COMMENT '列表形式\r\n[1,2,3]\r\n1-死亡后是否消失\r\n2-进入副本后是否消失\r\n3-下线之后是否计算时间\r\n没有就不填',
  `group` int(11) NOT NULL DEFAULT '0' COMMENT 'buff组',
  `priority` tinyint(5) DEFAULT '0' COMMENT 'buff优先级,数值越高,优先级越高',
  `last_time` int(11) NOT NULL DEFAULT '1000' COMMENT '持续时间',
  `times` int(11) NOT NULL DEFAULT '1' COMMENT '作用次数',
  `link_skill` varchar(50) NOT NULL DEFAULT '[]' COMMENT 'buff挂接技能',
  `link_effect` varchar(50) NOT NULL DEFAULT '[]' COMMENT '挂接特效',
  `effect_level` int(11) NOT NULL DEFAULT '0' COMMENT '特效前端表现层级',
  PRIMARY KEY (`buff_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_charge`
-- ----------------------------
CREATE TABLE `temp_charge` (
  `rmb_value` int(20) NOT NULL,
  `gold` int(20) NOT NULL,
  `desc` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`rmb_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_combat_attr`
-- ----------------------------
CREATE TABLE `temp_combat_attr` (
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '等级',
  `career` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '对人是职业，对怪物是类型。',
  `exp` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '对人是升级所需经验，对怪是产出经验。',
  `hit_point_max` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '生命上限',
  `magic_max` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '法力上限',
  `combopoint_max` int(11) NOT NULL DEFAULT '0' COMMENT '最大连击点数',
  `anger_max` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '怒气值上限',
  `attack` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '普通攻击力',
  `abs_damage` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '绝对伤害值',
  `defense` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '普通防御力',
  `fattack` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '仙攻值',
  `mattack` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '魔攻值',
  `dattack` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '妖攻值',
  `fdefense` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '仙防值',
  `mdefense` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '魔防值',
  `ddefense` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '妖防值',
  `speed` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '移动速度',
  `attack_speed` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '攻击速度',
  `hit_ratio` smallint(11) unsigned NOT NULL DEFAULT '0' COMMENT '命中率(万分比)',
  `dodge_ratio` smallint(11) unsigned NOT NULL DEFAULT '0' COMMENT '闪避率(万分比)',
  `crit_ratio` smallint(11) unsigned NOT NULL DEFAULT '0' COMMENT '暴击率(万分比)',
  `tough_ratio` smallint(11) unsigned NOT NULL DEFAULT '0' COMMENT '坚韧率(万分比)',
  `frozen_resis_ratio` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '冰冻抗性率(万分比)',
  `weak_resis_ratio` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '虚弱抗性率(万分比)',
  `flaw_resis_ratio` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '破绽抗性率(万分比)',
  `poison_resis_ratio` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '中毒抗性率(万分比)',
  `fundamental_energy` int(11) NOT NULL DEFAULT '0' COMMENT '能量值上限',
  PRIMARY KEY (`level`,`career`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='战斗属性表';

-- ----------------------------
--  Table structure for `temp_compose`
-- ----------------------------
CREATE TABLE `temp_compose` (
  `target_gtid` int(10) NOT NULL COMMENT '目标物品id',
  `tab_page` int(10) NOT NULL COMMENT '1-装备页；2-宝石页；3-骑宠页；4-其他',
  `level_limit` int(10) NOT NULL COMMENT '玩家的等级限制。不达到该等级则无法合成该物品',
  `coin_num` int(10) NOT NULL COMMENT '消耗铜钱数量',
  `goods_need` varchar(1024) NOT NULL COMMENT '合成需要消耗的物品',
  `desc1` varchar(50) NOT NULL COMMENT '说明1，用于前端展示',
  `desc2` varchar(50) NOT NULL COMMENT '说明2，用于前端展示',
  `desc3` varchar(50) NOT NULL COMMENT '说明3，用于前端展示',
  PRIMARY KEY (`target_gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_cultivation`
-- ----------------------------
CREATE TABLE `temp_cultivation` (
  `lv` int(7) NOT NULL AUTO_INCREMENT COMMENT '修为等级',
  `meridian_1` int(7) NOT NULL COMMENT '经脉一等级',
  `meridian_2` int(7) NOT NULL COMMENT '经脉二等级',
  `steps` int(7) NOT NULL COMMENT '所需的星阶数',
  `name` varchar(32) NOT NULL COMMENT '修为称号',
  `property` varchar(64) NOT NULL COMMENT '修为属性[{职业类别,属性类型,属性值}]',
  `cost` int(7) NOT NULL COMMENT '花费的修为点',
  PRIMARY KEY (`lv`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `temp_download_gift`
-- ----------------------------
CREATE TABLE `temp_download_gift` (
  `scene_id` int(11) NOT NULL COMMENT 'keyid,填写内容为场景id,即玩家下载完某场景会得到该礼包',
  `gift_id` int(11) DEFAULT NULL COMMENT '礼包id，对应temp_goods数据表内物品id',
  PRIMARY KEY (`scene_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_drop_main`
-- ----------------------------
CREATE TABLE `temp_drop_main` (
  `did` int(10) NOT NULL,
  `dropitem` varchar(200) NOT NULL DEFAULT '[]' COMMENT '随机掉落实例ID',
  PRIMARY KEY (`did`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='配置掉落实例';

-- ----------------------------
--  Table structure for `temp_drop_sub`
-- ----------------------------
CREATE TABLE `temp_drop_sub` (
  `sid` int(10) NOT NULL,
  `dropitem` varchar(100) NOT NULL DEFAULT '[]',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='掉落实例明细';

-- ----------------------------
--  Table structure for `temp_dungeon`
-- ----------------------------
CREATE TABLE `temp_dungeon` (
  `sid` int(11) NOT NULL DEFAULT '0' COMMENT '地图ID，temp_scene.sid',
  `name` varchar(250) DEFAULT NULL COMMENT '""',
  `grp` int(10) DEFAULT '0' COMMENT '副本组ID',
  `duration` int(11) NOT NULL DEFAULT '0' COMMENT '进入副本后持续时间（从进入副本之时开始算，时间到后自动传出）\r\n\r\n单位 秒',
  `next_sid` int(11) NOT NULL DEFAULT '0' COMMENT '地图ID，temp_scene.sid',
  `pass_type` int(2) DEFAULT '0' COMMENT '通关条件类型：\r\n1 - 杀死固定的怪物和数量\r\n2 - 杀死总共的怪物数量',
  `pass_cond` varchar(250) DEFAULT '[]' COMMENT '通关条件内容：\r\n1、杀死指定的怪物和数量的时候\r\n   配置为[{MonId,Number}]\r\n2、杀死总共怪物数量的时候，则为[totalNumber]',
  `rewards` varchar(250) DEFAULT '[]' COMMENT '副本通关奖励',
  `king_rewards` varchar(250) DEFAULT '[]' COMMENT '霸主奖励',
  `hard_desc` varchar(15) DEFAULT NULL COMMENT '前端用于显示副本难度的内容',
  `boss_coordinate` varchar(50) DEFAULT NULL COMMENT '副本BOSS怪的坐标点',
  `time_bonus` varchar(50) DEFAULT NULL COMMENT '控制玩家在副本中驻留时间影响评分的参数',
  `drug_take_off` int(11) DEFAULT NULL COMMENT '玩家在副本中吃药扣除的分数',
  `monster_bonus` int(11) DEFAULT NULL COMMENT '玩家在副本中杀怪获得的奖励分数',
  `begin_dialog` int(11) DEFAULT NULL,
  `end_dialog` int(11) DEFAULT NULL,
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='场景数据结构\r\n1、基础';

-- ----------------------------
--  Table structure for `temp_dungeon_group`
-- ----------------------------
CREATE TABLE `temp_dungeon_group` (
  `grp_id` int(11) NOT NULL DEFAULT '0' COMMENT '副本组ID',
  `grp_name` varchar(250) DEFAULT '[]' COMMENT '副本组名',
  `times` int(11) NOT NULL DEFAULT '0' COMMENT '挑战次数',
  `icon` varchar(250) DEFAULT '""' COMMENT '副本组UI资源',
  `npcid` int(11) NOT NULL,
  PRIMARY KEY (`grp_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `temp_dungeon_obj`
-- ----------------------------
CREATE TABLE `temp_dungeon_obj` (
  `dun_id` int(11) NOT NULL COMMENT '物件所在副本id',
  `obj_id` int(11) NOT NULL COMMENT '物件id',
  `action` int(11) NOT NULL COMMENT '1个物件被触发后的行为顺序',
  `condition` int(11) NOT NULL COMMENT '行为被触发的条件\r\n1.无条件\r\n2.上一个行为结束\r\n3.指定怪物死亡',
  `condition_param` varchar(1024) NOT NULL DEFAULT '[]' COMMENT 'condition是3的情况下填写[{mosterId,number}]，其余不填',
  `event` int(11) NOT NULL COMMENT 'event1触发剧情:[dialogueID]\r\nevent2创建怪物:[{monsterID,x,y}]\r\nevent3播放动画\r\nevent4播放死亡动作:[obj_id]\r\nevebt5触发通行:[obj_id]',
  `event_param` varchar(1024) NOT NULL DEFAULT '[]' COMMENT 'event1触发剧情:[dialogueID]\r\nevent2创建怪物:[{monsterID,x,y}]\r\nevent3播放动画\r\nevent4播放死亡动作:[obj_id]\r\nevebt5触发通行:[obj_id]',
  `create` int(11) NOT NULL DEFAULT '0' COMMENT '是否初始化可见',
  PRIMARY KEY (`dun_id`,`obj_id`,`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_dungeon_trigger`
-- ----------------------------
CREATE TABLE `temp_dungeon_trigger` (
  `sid` int(11) NOT NULL DEFAULT '0' COMMENT '触发器标识',
  `action` int(11) NOT NULL DEFAULT '0' COMMENT '该副本的触发器标识\r\n\r\n1、玩家进入地图\r\n2、玩家死亡\r\n11 - 99 、玩家移动(位置同步)\r\n101 - 199、触发机关',
  `area` varchar(1024) NOT NULL DEFAULT '{}' COMMENT '{X1,Y1,...,Xn,Yn}在校验的时候，玩家的位置X，Y满足这样的关系: X1<= X <= X2 && Y1<= Y <= Y2',
  `event` int(11) NOT NULL DEFAULT '0' COMMENT '响应时间类型:\r\n1 - 刷怪\r\n2 - 播放剧情\r\n3 - 播放动画',
  `param` varchar(500) NOT NULL DEFAULT '[]' COMMENT '事件参数\r\n根据event的取值进行，配置数据格式不一样：\r\n1、刷怪，填刷怪的区域，建议是给一个中心点，然后给一个范围随机出现。如[{X,Y,MonId}] ;\r\n2、播放剧情，填剧情ID 如 [FilmId] ;\r\n3、播放动画，填动画ID和动作ID[{AnimId,ActionId}]',
  PRIMARY KEY (`sid`,`action`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='场景数据结构\r\n1、基础';

-- ----------------------------
--  Table structure for `temp_energy`
-- ----------------------------
CREATE TABLE `temp_energy` (
  `career` tinyint(5) NOT NULL DEFAULT '0' COMMENT '玩家角色(0:未定义，1: 神 2:魔 3:妖)',
  `level` int(3) NOT NULL DEFAULT '0' COMMENT '角色等级',
  `attack` varchar(64) NOT NULL DEFAULT '{a1,b1}' COMMENT '攻击时回复的能量系数',
  `injured` varchar(64) NOT NULL DEFAULT '{a2,c2}' COMMENT '被攻击时回复的能量,具体参考字段attack',
  `crit` int(5) NOT NULL DEFAULT '0' COMMENT '暴击回复的能量百分比,具体参考字段attack',
  `combat_recover` varchar(64) NOT NULL DEFAULT '{a3,c3,a4,c4,C5}' COMMENT '战斗时回复每秒的能量系数',
  `normal_recover` int(5) NOT NULL DEFAULT '0' COMMENT '离开战斗时回复每秒的能量系数百分比',
  PRIMARY KEY (`career`,`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `temp_gift_bag`
-- ----------------------------
CREATE TABLE `temp_gift_bag` (
  `gift_bag_id` int(11) NOT NULL COMMENT '礼包id',
  `goods_list` varchar(250) DEFAULT NULL COMMENT '礼包内包含物品数量',
  PRIMARY KEY (`gift_bag_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_gilding`
-- ----------------------------
CREATE TABLE `temp_gilding` (
  `gilding_lv` int(10) NOT NULL COMMENT '镀金等级',
  `equip_subtype` int(10) NOT NULL COMMENT '镀金等级',
  `add_value` varchar(150) NOT NULL DEFAULT '[]' COMMENT '附加属性',
  `goods` varchar(150) DEFAULT '[]' COMMENT '消耗物品',
  `cost_coin` int(10) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  PRIMARY KEY (`gilding_lv`,`equip_subtype`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='镀金配置表';

-- ----------------------------
--  Table structure for `temp_god_tried`
-- ----------------------------
CREATE TABLE `temp_god_tried` (
  `target_tid` int(10) NOT NULL DEFAULT '0' COMMENT '神炼宝石',
  `stone_tid` int(10) DEFAULT NULL COMMENT '宝石',
  `god_stone_tid` int(10) DEFAULT NULL COMMENT '神炼石',
  `cost_coin` int(10) DEFAULT NULL COMMENT '消耗铜钱',
  PRIMARY KEY (`target_tid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='神炼模版表';

-- ----------------------------
--  Table structure for `temp_gold_bag`
-- ----------------------------
CREATE TABLE `temp_gold_bag` (
  `cell_num` int(10) NOT NULL DEFAULT '0',
  `gold_num` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`cell_num`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='元宝开启格子数';

-- ----------------------------
--  Table structure for `temp_goods`
-- ----------------------------
CREATE TABLE `temp_goods` (
  `gtid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型编号',
  `name` varchar(100) NOT NULL DEFAULT '' COMMENT '物品名称',
  `icon` varchar(50) NOT NULL DEFAULT '0' COMMENT '物品图标资源ID',
  `fall` varchar(50) NOT NULL DEFAULT '' COMMENT '物品掉落在地图标ID',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型(参考宏定义)',
  `subtype` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '物品子类型(参考宏定义)',
  `quality` tinyint(1) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色',
  `sell_price` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品出售价格',
  `career` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '职业限制，1，战士。2-法师，3-射手4为不限,5宠物，6战骑',
  `gender` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '性别限制，0为女，1为男，2为男女不限',
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '等级限制，0为不限',
  `max_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '可叠加数',
  `limit` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '限制条件，0不限制 1捡取绑定 2装备绑定 4不能出售',
  `expire_time` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '有效期，0为不限，单位为秒',
  `suit_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '套装ID，0为不是套装',
  `cd` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'cd',
  `desc` varchar(256) NOT NULL DEFAULT '' COMMENT '物品描述信息',
  `type_desc` varchar(64) NOT NULL COMMENT '对物品类型的描述      如弓手护肩',
  `point_of_origin` varchar(64) NOT NULL DEFAULT '0' COMMENT '该物品的产出途径',
  `navigation_goal` char(64) NOT NULL DEFAULT '[]' COMMENT '点击tips中右下角的“装备”或者“使用”按钮，跳转到的对应页面,用列表形式填写，形如',
  `search_type` int(11) DEFAULT '0',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='物品基础表';

-- ----------------------------
--  Table structure for `temp_goods_buff`
-- ----------------------------
CREATE TABLE `temp_goods_buff` (
  `gtid` int(10) NOT NULL COMMENT '物品类型id',
  `buff_tid` int(10) NOT NULL COMMENT 'buff类型id',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='物品buff对应关系模版表';

-- ----------------------------
--  Table structure for `temp_goods_contain`
-- ----------------------------
CREATE TABLE `temp_goods_contain` (
  `gid` int(11) NOT NULL COMMENT '对应物品表的id.这类物品的type = 9',
  `contain` varchar(100) NOT NULL COMMENT '使用之后包含的物品内容。填写格式是物品id以及物品数量',
  PRIMARY KEY (`gid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_goods_equipment`
-- ----------------------------
CREATE TABLE `temp_goods_equipment` (
  `gtid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品类型编号',
  `appearance` varchar(20) NOT NULL DEFAULT '' COMMENT '装备外观',
  `set_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '套装编号',
  `max_stren` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '最大强化等级',
  `equip_attr` varchar(150) NOT NULL DEFAULT '[]' COMMENT '装备属性',
  `stren_change` varchar(100) NOT NULL DEFAULT '[]' COMMENT '强化后换装',
  `holes` tinyint(4) NOT NULL DEFAULT '0' COMMENT '默认孔数',
  `max_holes` tinyint(4) NOT NULL DEFAULT '0' COMMENT '镶嵌孔上限',
  `max_gilding` tinyint(4) NOT NULL DEFAULT '0' COMMENT '镀金上限',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='装备物品';

-- ----------------------------
--  Table structure for `temp_goods_facade`
-- ----------------------------
CREATE TABLE `temp_goods_facade` (
  `gtid` int(11) NOT NULL COMMENT '物品类型id',
  `facade` int(11) NOT NULL COMMENT '外观id',
  `facade_res` varchar(100) NOT NULL COMMENT '外观对应资源',
  `frame` int(11) NOT NULL COMMENT '帧数',
  `frame_speed` int(11) NOT NULL COMMENT '帧速',
  `icon` char(50) NOT NULL COMMENT '头像',
  `expire_time` int(11) NOT NULL COMMENT '0外观过期时间',
  `name` char(150) NOT NULL COMMENT '外观名称',
  `description` varchar(128) NOT NULL COMMENT '1、宠物幻化界面，宠物列表中的文字描述',
  `character` varchar(128) NOT NULL COMMENT '1、宠物幻化界面，“宠物说明”后的文字内容',
  `color` int(11) NOT NULL COMMENT '宠物坐骑的名字颜色\r\n1，白\r\n2，绿\r\n3，蓝\r\n4，紫\r\n5，橙',
  `character_deviation` varchar(64) NOT NULL,
  `mount_deviation` varchar(64) NOT NULL,
  PRIMARY KEY (`gtid`,`facade`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='幻化卡和资源对应关系模版表';

-- ----------------------------
--  Table structure for `temp_goods_gem`
-- ----------------------------
CREATE TABLE `temp_goods_gem` (
  `gtid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '物品ID',
  `coin_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `attri_add` varchar(150) NOT NULL DEFAULT '{}' COMMENT '属性加成',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宝石属性';

-- ----------------------------
--  Table structure for `temp_goods_suit`
-- ----------------------------
CREATE TABLE `temp_goods_suit` (
  `suit_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '套装编号',
  `suit_num` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '套装件数',
  `name` varchar(20) NOT NULL DEFAULT '' COMMENT '套装名',
  `goods_list` varchar(255) NOT NULL DEFAULT '[]' COMMENT '套装物品ID列表[gdid1,gtid2]',
  `effect_list` varchar(255) NOT NULL DEFAULT '[]' COMMENT '套装效果列表[{hit_ponit_max,numbner},]',
  PRIMARY KEY (`suit_id`,`suit_num`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='套装物品表';

-- ----------------------------
--  Table structure for `temp_guild_contribution`
-- ----------------------------
CREATE TABLE `temp_guild_contribution` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '此列配置不同货币',
  `contribution` int(11) NOT NULL COMMENT '1元宝/1铜钱所能增加的贡献值（贡献是帮派成员的个人属性）',
  `fund` int(11) NOT NULL COMMENT '1元宝/1铜钱所能增加的帮派资金（帮派资金数值是帮派属性）',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_guild_level`
-- ----------------------------
CREATE TABLE `temp_guild_level` (
  `guild_level` int(11) NOT NULL COMMENT '帮派等级',
  `guild_members_limit` int(11) NOT NULL COMMENT '成员数量上限',
  `guild_contribution_cost` int(11) NOT NULL COMMENT '1、每日消耗的资金数量2、消耗内容为帮派资金',
  PRIMARY KEY (`guild_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_label`
-- ----------------------------
CREATE TABLE `temp_label` (
  `leader_id` int(11) NOT NULL,
  `name` varchar(64) NOT NULL,
  `type` int(11) NOT NULL,
  `condition_id` int(11) NOT NULL,
  `second_label` int(11) NOT NULL,
  `third_label` int(11) NOT NULL,
  PRIMARY KEY (`leader_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_level_bag`
-- ----------------------------
CREATE TABLE `temp_level_bag` (
  `level` int(10) NOT NULL DEFAULT '0',
  `cell_num` int(10) DEFAULT NULL,
  PRIMARY KEY (`level`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='等级扩展背包';

-- ----------------------------
--  Table structure for `temp_mail_content`
-- ----------------------------
CREATE TABLE `temp_mail_content` (
  `cid` int(11) NOT NULL AUTO_INCREMENT COMMENT '内容ID',
  `content` varchar(1024) NOT NULL DEFAULT '"你是SB"' COMMENT '信件正文',
  PRIMARY KEY (`cid`),
  KEY `id` (`cid`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=17 DEFAULT CHARSET=utf8 COMMENT='信件信息';

-- ----------------------------
--  Table structure for `temp_mail_type`
-- ----------------------------
CREATE TABLE `temp_mail_type` (
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '类型(0系统)',
  `name` char(255) NOT NULL DEFAULT '"这不是一个邮件"' COMMENT '邮件类型名（发送名)',
  PRIMARY KEY (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='信件信息';

-- ----------------------------
--  Table structure for `temp_meridian`
-- ----------------------------
CREATE TABLE `temp_meridian` (
  `mer_id` int(10) NOT NULL COMMENT '经脉id',
  `mer_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '经脉类型(1-督脉，2-任脉，3-冲脉，4-带脉，5-阴维，6-阳维，7-阴跷，8-阳跷)',
  `mer_lv` int(7) NOT NULL COMMENT '经脉等级(1~100)',
  `cd_type` tinyint(2) NOT NULL COMMENT '是否有cd(1有 2无)',
  `mer_name` varchar(10) NOT NULL COMMENT '经脉名称',
  `mer_detail` varchar(128) NOT NULL COMMENT '经脉详细[{职业类别,属性类型,属性值}...]',
  `next_mer_id` int(10) NOT NULL COMMENT '下一级经脉(-1为无下一级)',
  `cd` int(16) NOT NULL DEFAULT '0' COMMENT '冷却时间',
  `cost_money` int(10) NOT NULL COMMENT '升级需要的金钱花费',
  `cost_Empowerment` int(10) NOT NULL COMMENT '升级需要的历练消费',
  PRIMARY KEY (`mer_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `temp_mon_ai`
-- ----------------------------
CREATE TABLE `temp_mon_ai` (
  `id` int(10) NOT NULL COMMENT 'AI编号',
  `ai_trigger` varchar(150) NOT NULL DEFAULT '{}' COMMENT '触发条件',
  `chat` varchar(150) NOT NULL DEFAULT '' COMMENT '怪物喊话',
  `skill` varchar(150) NOT NULL DEFAULT '{}' COMMENT '使用技能',
  `target` varchar(150) NOT NULL DEFAULT '{}' COMMENT '动作目标,触发AI后引发的行为',
  `trigger_flag` tinyint(4) NOT NULL DEFAULT '0' COMMENT '整场战斗触发次数,0:不限次数,1:只触发1次',
  `ai_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'AI类型:1怪物喊话,2怪物释放某技能,3选取仇恨列表第n位为目标,4怪物召唤同伴,5角色召唤同伴',
  `next_ai` varchar(200) NOT NULL DEFAULT '' COMMENT '跳转到ai',
  `content` varchar(150) NOT NULL DEFAULT '' COMMENT '备注',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='怪物AI模版表';

-- ----------------------------
--  Table structure for `temp_mon_layout`
-- ----------------------------
CREATE TABLE `temp_mon_layout` (
  `key_id` bigint(15) NOT NULL COMMENT 'LUA用联合主键的效率非常低下，我加了个联合主键',
  `scene_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '场景ID',
  `monid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '怪物ID',
  `x` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '出生X坐标',
  `y` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '出生Y坐标',
  `towards` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1.北；2.东北；3.东；4.东南；5.南；6.西南；7.西；8.西北',
  `revive_time` int(5) unsigned NOT NULL DEFAULT '0' COMMENT '怪物死亡后的复活时长',
  `state` tinyint(2) NOT NULL DEFAULT '0' COMMENT '怪物状态：1-正常，2-战斗中，3-追击，4-死亡。',
  `pos_x` smallint(2) NOT NULL DEFAULT '0' COMMENT '当前位置的X左边',
  `pos_y` smallint(2) NOT NULL DEFAULT '0' COMMENT '当前位置的Y左边',
  `attack_skill` int(10) NOT NULL DEFAULT '0' COMMENT '攻击技能',
  `skill_lv` int(10) NOT NULL DEFAULT '0' COMMENT '技能等级',
  `refresh_time` int(10) NOT NULL DEFAULT '0' COMMENT '下次需要刷新的时间',
  `last_move_time` int(11) NOT NULL DEFAULT '0' COMMENT '上次移动的时间',
  `move_path` int(11) unsigned zerofill NOT NULL DEFAULT '00000000000' COMMENT '上次移动的路径',
  `hate_list` varchar(11) NOT NULL DEFAULT '' COMMENT '怪物的仇恨列表[{UID,DAMAGE,ADDTIME}]',
  `buff_list` varchar(11) NOT NULL DEFAULT '' COMMENT '怪物的BUFF列表[{BUFFID,ExpireTime}]',
  `sing_expire` int(11) DEFAULT NULL COMMENT '开始吟唱时间',
  `monrcd` varchar(11) NOT NULL DEFAULT '{}' COMMENT '怪物配置结构，配置的时候不用填',
  `battle_attr` varchar(11) NOT NULL DEFAULT '{}' COMMENT '战斗属性战斗属性，玩家不用填',
  `target_uid` int(11) NOT NULL DEFAULT '0' COMMENT '主动怪物，被动怪物的攻击 目标玩家ID',
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '怪物唯一标识(场景ID+怪物ID+**).配置的时候不用填',
  `round_times` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '怪物第攻击次数',
  `ai_skill_id` tinyint(4) NOT NULL DEFAULT '0' COMMENT '怪物AI产生的技能,0为无AI技能',
  `ai_skill_lv` tinyint(4) NOT NULL DEFAULT '0' COMMENT '怪物AI产生的技能等级',
  `start_fight_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '怪物进入战斗时间,单位秒',
  `ai_handle_list` varchar(150) NOT NULL DEFAULT '[]' COMMENT '整场战斗触发AI产生的行为列表,整场战斗只触发1次',
  `hate_seq` tinyint(4) NOT NULL DEFAULT '1' COMMENT '选取仇恨列表第n位为目标,0为最后1位',
  `pid` varchar(50) DEFAULT NULL COMMENT '怪物进程的Id',
  PRIMARY KEY (`key_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='怪物刷新';

-- ----------------------------
--  Table structure for `temp_mount_attr`
-- ----------------------------
CREATE TABLE `temp_mount_attr` (
  `key_id` int(11) NOT NULL,
  `level` int(11) NOT NULL DEFAULT '0' COMMENT '座骑阶级',
  `star` int(11) NOT NULL DEFAULT '0' COMMENT '星级',
  `star_exp` int(11) NOT NULL COMMENT '坐骑在该星级，升到下一星所需要的进度值总长',
  `mount_model` int(11) DEFAULT NULL,
  `speed` int(11) NOT NULL DEFAULT '0' COMMENT '坐骑给主人提供的速度增加值。为具体增加的值，不是万分比。',
  `data` varchar(10240) NOT NULL DEFAULT '[]' COMMENT '属性列表[{Key, Value},...]',
  `coin_id` tinyint(4) NOT NULL,
  `coin_num` int(11) NOT NULL,
  `star_gid` int(11) NOT NULL DEFAULT '0' COMMENT '在此等级（星，阶）所使用的丹药id',
  PRIMARY KEY (`level`,`star`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_mount_medicine`
-- ----------------------------
CREATE TABLE `temp_mount_medicine` (
  `gtid` int(11) NOT NULL COMMENT '坐骑进星丹的id,坐骑进星丹分为初级、中级、高级、特级、顶级',
  `add_mount_exp` int(11) NOT NULL COMMENT '服用进星丹，可以使对应星级的进度条增加具体的数值',
  `gold_id` int(11) NOT NULL COMMENT '元宝的物品id',
  `gold_num` int(11) NOT NULL COMMENT '该丹药的元宝定价',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_mount_quality`
-- ----------------------------
CREATE TABLE `temp_mount_quality` (
  `target_quality` int(11) NOT NULL COMMENT '目标品阶',
  `medicine_id` int(11) NOT NULL COMMENT '所使用进阶丹id',
  `gold_id` int(11) NOT NULL COMMENT '元宝id',
  `gold_num` int(11) NOT NULL COMMENT '该丹药的元宝定价',
  `coin_id` int(11) NOT NULL COMMENT '花费的货币类型',
  `coin_num` int(11) NOT NULL COMMENT '花费铜钱的数量',
  PRIMARY KEY (`target_quality`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_mount_skill`
-- ----------------------------
CREATE TABLE `temp_mount_skill` (
  `index` int(11) NOT NULL,
  `sid` smallint(11) NOT NULL DEFAULT '0' COMMENT '技能ID',
  `level` int(11) NOT NULL DEFAULT '0' COMMENT '技能等级',
  `name` varchar(50) NOT NULL DEFAULT '技能名字' COMMENT '阶级名',
  `exp` int(11) NOT NULL,
  `data` varchar(1024) NOT NULL DEFAULT '[]' COMMENT '属性列表[{Key, Value},...]',
  `icon` varchar(50) NOT NULL DEFAULT '',
  `mount_level` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sid`,`level`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_notice`
-- ----------------------------
CREATE TABLE `temp_notice` (
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '消息ID',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '0 - 提示语，发给单个人的。\r\n1 - 1级公告，会在跑马灯出现。\r\n2 - 2级公告，会在系统公告频道出现，红字。\r\n3 - 3级公告，会在系统频道出现，普通字。',
  `content` varchar(500) NOT NULL DEFAULT '""' COMMENT '消息内容',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='通知消息';

-- ----------------------------
--  Table structure for `temp_npc`
-- ----------------------------
CREATE TABLE `temp_npc` (
  `nid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'NPC编号',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '字名',
  `title` varchar(50) NOT NULL DEFAULT '' COMMENT '称号',
  `icon` varchar(11) NOT NULL DEFAULT '0' COMMENT '怪物或者NPC形象',
  `head` varchar(11) NOT NULL DEFAULT '0' COMMENT '怪物或者NPC头像',
  `model` varchar(11) NOT NULL DEFAULT '' COMMENT 'NPC头顶图片资源',
  `half_length` varchar(11) NOT NULL DEFAULT '0' COMMENT 'NPC半身原画(在玩家点击打开NPC对话时显示的资源)',
  `npc_type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '类型：10-NPC;11-采集怪;20-普通小怪;21-精英怪物;22-副本小怪;25-副本精英怪;30-野外BOS;31-世界BOSS;32-副本BOSS;33-帮派BOSS;40-宠物;50-坐骑',
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '怪物等级',
  `fire_range` int(11) NOT NULL DEFAULT '0' COMMENT '追击范围(格子距离)',
  `warn_range` int(11) NOT NULL DEFAULT '0' COMMENT '警介范围(格子距离)为0 的时候是被动怪物，大于0是主动怪物',
  `hit_point` int(11) NOT NULL DEFAULT '0' COMMENT '生命值',
  `magic` int(11) NOT NULL DEFAULT '0' COMMENT '法力值上限',
  `greeting` varchar(1000) NOT NULL DEFAULT '[]' COMMENT '怪物招呼语(怪物自说自话)',
  `dialog` varchar(1000) NOT NULL DEFAULT '[]' COMMENT 'NPC无任务的时候点击显示',
  `func` varchar(50) NOT NULL DEFAULT '{}',
  `drop_id` int(11) NOT NULL DEFAULT '0' COMMENT '掉落ID(temp_drop_main.did) 需要广播到场景中掉落物品',
  `output_id` int(11) NOT NULL DEFAULT '0' COMMENT '产出的掉落(temp_drop_main.did) 根据不同的怪物类型决定发给具体的角色',
  `act_skilllist` varchar(50) NOT NULL DEFAULT '[]' COMMENT '主动技能列表[ID]',
  `pas_skilllist` varchar(50) NOT NULL DEFAULT '[]' COMMENT '被动技能列表 [ID]',
  `ai_id` int(11) NOT NULL DEFAULT '0' COMMENT '怪物AI id',
  `size` int(8) DEFAULT '0' COMMENT 'NPC缩放比例',
  `fight_ai_id` int(11) DEFAULT '0' COMMENT '怪物的初始战斗AI',
  `dead_ai_id` int(11) DEFAULT '0',
  `dead_delay_time` int(11) DEFAULT '0',
  `is_hitback_when_die` int(4) DEFAULT '0' COMMENT '怪物死亡时，是否播放击退效果.1表示播放击退效果，0表示不播放击退效果',
  PRIMARY KEY (`nid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='NPC基础表';

-- ----------------------------
--  Table structure for `temp_npc_layout`
-- ----------------------------
CREATE TABLE `temp_npc_layout` (
  `key_id` bigint(15) NOT NULL COMMENT 'LUA不支持联合主键，将之前scene_id，npc_id连起来做了该列，做主键',
  `scene_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '场景ID',
  `npcid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'NPCID',
  `x` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'X坐标',
  `y` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'Y坐标',
  `towards` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1.北；2.东北；3.东；4.东南；5.南；6.西南；7.西；8.西北',
  `npcrcd` varchar(250) NOT NULL DEFAULT '{}' COMMENT 'NPC实例，配置的时候不用填',
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'NPC唯一ID 配置的时候不用填',
  PRIMARY KEY (`key_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='NPC刷新';

-- ----------------------------
--  Table structure for `temp_npc_shop`
-- ----------------------------
CREATE TABLE `temp_npc_shop` (
  `shop_id` int(10) NOT NULL COMMENT '商店编号',
  `shop_page` int(10) NOT NULL COMMENT '商店页码',
  `shop_type` int(10) NOT NULL COMMENT '商店类型(0不限购,1限购)',
  `shop_goods` varchar(500) NOT NULL DEFAULT '[]' COMMENT '[{购买兑换物品, 消耗物品,数量, 限购数量}]',
  PRIMARY KEY (`shop_id`,`shop_page`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='商店模板表';

-- ----------------------------
--  Table structure for `temp_pet`
-- ----------------------------
CREATE TABLE `temp_pet` (
  `level` smallint(6) NOT NULL COMMENT '等级',
  `attack` int(11) NOT NULL COMMENT '普通攻击',
  `crit` int(11) NOT NULL COMMENT '暴击',
  `hit` int(11) NOT NULL COMMENT '命中',
  `attr_attack` int(11) NOT NULL COMMENT '属攻',
  `skill_holes` tinyint(4) NOT NULL COMMENT '技能槽数',
  `atk_speed` int(10) NOT NULL COMMENT '攻击速度',
  PRIMARY KEY (`level`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物模版';

-- ----------------------------
--  Table structure for `temp_pet_aptitude`
-- ----------------------------
CREATE TABLE `temp_pet_aptitude` (
  `aptitude_lv` int(10) NOT NULL COMMENT '资质等级',
  `cost_goods` int(10) NOT NULL COMMENT '消耗丹药id',
  `cost_coin` int(10) NOT NULL COMMENT '消耗的铜钱',
  `growth_total` int(10) NOT NULL COMMENT '成长值进度条总长',
  `add_attri` varchar(300) NOT NULL DEFAULT '[]' COMMENT '增加的属性',
  `extra_attri` varchar(300) NOT NULL DEFAULT '[]' COMMENT '额外增加属性值',
  `add_holes` tinyint(4) NOT NULL DEFAULT '0' COMMENT '增加技能槽',
  PRIMARY KEY (`aptitude_lv`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物资质模版';

-- ----------------------------
--  Table structure for `temp_pet_growth`
-- ----------------------------
CREATE TABLE `temp_pet_growth` (
  `growth_lv` int(10) NOT NULL COMMENT '成长等级',
  `cost_goods` int(10) NOT NULL COMMENT '消耗成长丹id',
  `cost_coin` int(10) NOT NULL COMMENT '消耗的铜钱',
  `growth_total` int(10) NOT NULL COMMENT '成长值进度条总长',
  `add_attri` varchar(300) NOT NULL DEFAULT '[]' COMMENT '增加的属性',
  `extra_attri` varchar(300) NOT NULL DEFAULT '[]' COMMENT '额外增加属性值',
  `add_holes` int(10) NOT NULL COMMENT '技能槽增加数',
  PRIMARY KEY (`growth_lv`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物成长模版';

-- ----------------------------
--  Table structure for `temp_pet_medicine`
-- ----------------------------
CREATE TABLE `temp_pet_medicine` (
  `gtid` int(11) NOT NULL DEFAULT '0' COMMENT '丹药类型id',
  `growth` int(11) DEFAULT '0' COMMENT '增加成长值',
  `aptitude` int(11) DEFAULT '0' COMMENT '增加资质值',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物丹药增加进度模版';

-- ----------------------------
--  Table structure for `temp_pet_quality`
-- ----------------------------
CREATE TABLE `temp_pet_quality` (
  `quality_lv` int(10) NOT NULL DEFAULT '0' COMMENT '品阶级',
  `color` int(10) NOT NULL DEFAULT '0' COMMENT '宠物名称颜色编号',
  `facade` int(10) NOT NULL DEFAULT '0' COMMENT '宠物外观编号',
  `cost_goods` int(10) NOT NULL DEFAULT '0' COMMENT '进阶消耗进阶丹id',
  `cost_coin` int(10) NOT NULL DEFAULT '0' COMMENT '消耗铜钱数目',
  `succ_rate` int(10) NOT NULL DEFAULT '0' COMMENT '成功率',
  `add_rate` int(10) NOT NULL DEFAULT '0' COMMENT '进阶失败基础成功率增加值',
  `growth_limit` int(10) NOT NULL DEFAULT '0' COMMENT '成长值等级上限',
  `aptitude_limit` int(10) NOT NULL DEFAULT '0' COMMENT '资质值等级上限',
  `add_attri` varchar(300) NOT NULL DEFAULT '[]' COMMENT '宠物属性加成[{attcak, 10}, {}]',
  PRIMARY KEY (`quality_lv`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物品级模版表';

-- ----------------------------
--  Table structure for `temp_pet_skill_book`
-- ----------------------------
CREATE TABLE `temp_pet_skill_book` (
  `gtid` int(10) NOT NULL COMMENT '物品类型id',
  `skill_level` int(10) NOT NULL COMMENT '物品类型id',
  `skill_id` int(10) NOT NULL COMMENT '技能id',
  `pre_level` int(11) NOT NULL DEFAULT '0' COMMENT '前置学习技能id',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宠物技能书模版';

-- ----------------------------
--  Table structure for `temp_polish`
-- ----------------------------
CREATE TABLE `temp_polish` (
  `gtid` int(10) NOT NULL COMMENT '装备ID',
  `polish_value` varchar(255) NOT NULL DEFAULT '[]' COMMENT '洗炼属性列表',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='洗练模版表';

-- ----------------------------
--  Table structure for `temp_polish_goods`
-- ----------------------------
CREATE TABLE `temp_polish_goods` (
  `quality` int(10) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色',
  `max_polish` int(10) NOT NULL COMMENT '最大洗练条数',
  `goods` varchar(150) NOT NULL DEFAULT '[]' COMMENT '消耗品',
  `cost_coin` int(11) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  PRIMARY KEY (`quality`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='洗练消耗模版表';

-- ----------------------------
--  Table structure for `temp_rand_shop`
-- ----------------------------
CREATE TABLE `temp_rand_shop` (
  `shop_lv` int(11) NOT NULL COMMENT '商城等级',
  `bless` int(11) NOT NULL COMMENT '祝福值上限',
  `shop_goods_lv` varchar(64) NOT NULL DEFAULT '[]' COMMENT '物品等级',
  `times_limit` varchar(64) NOT NULL DEFAULT '[]' COMMENT '不同物品等级刷新出次数限制',
  `odds_goods_lv` varchar(64) NOT NULL DEFAULT '[]' COMMENT '物品等级几率参数：举个栗子，三个物品等级对应参数为（a,b,c)，出现几率分别为a/(a+b+c),b/(a+b+c),c/(a+b+c)',
  `bless_up` varchar(64) NOT NULL DEFAULT '[]' COMMENT '刷新提升祝福值',
  `odds_bless_up` varchar(64) NOT NULL DEFAULT '[]' COMMENT '提升祝福值概率参数',
  `lock_cost` varchar(64) NOT NULL DEFAULT '[]' COMMENT '锁定单价',
  `fundamental_cost` int(11) NOT NULL COMMENT '刷新基础费用',
  PRIMARY KEY (`shop_lv`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_rand_shop_goods`
-- ----------------------------
CREATE TABLE `temp_rand_shop_goods` (
  `goods_id` int(11) NOT NULL COMMENT '物品id，与temp_goods表对应',
  `goods_lv` int(11) NOT NULL COMMENT '商城物品等级',
  `odds_goods` int(11) NOT NULL COMMENT '出现物品的几率参数',
  `cost_gold` int(11) NOT NULL COMMENT '元宝价值',
  PRIMARY KEY (`goods_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_scene`
-- ----------------------------
CREATE TABLE `temp_scene` (
  `sid` int(11) NOT NULL COMMENT '场景id',
  `name` char(20) NOT NULL DEFAULT '' COMMENT '场景名称',
  `icon` char(11) NOT NULL DEFAULT '0' COMMENT '场景资源编号',
  `mode` smallint(1) NOT NULL DEFAULT '0' COMMENT '地图模式：\r\n默认为1 \r\n1-新手村 \r\n2-野外 \r\n3-主城 \r\n4-副本 \r\n5-跨服副本 ',
  `type` smallint(5) NOT NULL DEFAULT '1' COMMENT '地图类型：多种类型可以共存\r\n0-表示都不可以\r\n1-可以PK\r\n2-可以原地复活\r\n4-可以吃瞬加药\r\n8-可以使用小飞鞋传送',
  `pk_mode` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0-不强制pk模式\r\n1-强制和平模式\r\n2-强制自由pk模式\r\n3-强制帮会pk模式',
  `min_level` smallint(5) NOT NULL DEFAULT '0' COMMENT '进入该地图的最下玩家等级',
  `max_level` smallint(5) NOT NULL DEFAULT '0' COMMENT '进入该地图的最大玩家等级',
  `x` int(11) NOT NULL DEFAULT '0' COMMENT '进入后默认x坐标',
  `y` int(11) NOT NULL DEFAULT '0' COMMENT '进入后默认y坐标',
  `poem` char(30) NOT NULL DEFAULT '0' COMMENT '进入诗词',
  `loading` int(11) NOT NULL DEFAULT '0' COMMENT '调用Loading图',
  `revive_sid` int(11) NOT NULL DEFAULT '0' COMMENT '复活场景',
  `revive_x` int(11) NOT NULL DEFAULT '0' COMMENT '复活X坐标',
  `revive_y` int(11) NOT NULL DEFAULT '0' COMMENT '复活Y坐标',
  `size` smallint(5) NOT NULL DEFAULT '10000' COMMENT '万分比。填写10000则为不缩放。此处缩放比例只对场景中的玩家角色有效（包括宠物、站骑等）',
  `npc` char(255) DEFAULT '[]' COMMENT 'NPC',
  `scene_num` int(11) unsigned DEFAULT '0' COMMENT '该基础场景的进程数',
  `id` int(11) NOT NULL DEFAULT '0' COMMENT '场景实例唯一标识',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='场景数据结构\r\n1、基础';

-- ----------------------------
--  Table structure for `temp_shop`
-- ----------------------------
CREATE TABLE `temp_shop` (
  `shop_tab_page` int(11) NOT NULL,
  `gtid` int(11) NOT NULL,
  `page` int(10) NOT NULL,
  `location` int(10) NOT NULL,
  `original_price` int(10) NOT NULL,
  `real_price` int(10) NOT NULL,
  `gold_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '0非绑定元宝,1绑定元宝',
  `level_limit` int(10) NOT NULL COMMENT '开放等级限制',
  PRIMARY KEY (`shop_tab_page`,`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='商城配置表';

-- ----------------------------
--  Table structure for `temp_skill`
-- ----------------------------
CREATE TABLE `temp_skill` (
  `sid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '技能编号',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '技能名称',
  `icon` varchar(50) NOT NULL DEFAULT '0' COMMENT '技能资源编号,填写方式[技能升级面板突变id,主界面图标id]',
  `type` tinyint(5) NOT NULL DEFAULT '1' COMMENT '技能类别 1.主动技能 2.被动技能（职业分流）',
  `stype` tinyint(4) NOT NULL DEFAULT '0' COMMENT '子类型0：没要求， 1 玩家技能 2 怪的技能3宠物的技能,10-被动技能',
  `is_stone_effect` smallint(5) NOT NULL COMMENT '标识玩家被石化之后，能否放出技能\r\n0-不能\r\n1-能',
  `career` tinyint(4) NOT NULL DEFAULT '0' COMMENT '职业要求，0为不要求。1战士，2法师， 3射手,6-宠物，20-普通小怪;21-精英怪物;22-副本小怪;30-野外BOS;31-世界BOSS;32-副本BOSS;33-帮派BOSS;\r\n',
  `distance` int(11) NOT NULL DEFAULT '0' COMMENT '技能释放距离,0时表示单体技能',
  `is_damage` smallint(5) NOT NULL DEFAULT '0' COMMENT '技能是否造成伤害 0.不造成伤害 1.造成伤害',
  `is_normal_attr` smallint(5) NOT NULL DEFAULT '0' COMMENT '是否普攻 0.否 1.是',
  `is_hit` smallint(5) NOT NULL DEFAULT '0' COMMENT '是否必定命中 0.否 1.是',
  `aoe_tnum` int(11) NOT NULL DEFAULT '0' COMMENT '技能AOE目标数量',
  `cd` int(5) NOT NULL DEFAULT '0' COMMENT '技能cd',
  `is_cd_all` smallint(5) NOT NULL DEFAULT '0' COMMENT '是否受公共cd影响 0.否1.是',
  `cd_all` int(5) NOT NULL COMMENT '影响公共cd的数值',
  `target_type` tinyint(4) NOT NULL DEFAULT '1' COMMENT '1-以自身为中心；2-以目标为中心；3-以地面某点为中心',
  `aoe_type` tinyint(5) NOT NULL DEFAULT '0' COMMENT 'aoe范围类型 1.直线 2.九宫格 3.扇形',
  `aoe_dist` int(11) NOT NULL DEFAULT '0' COMMENT '技能AOE作用的距离',
  `relation_type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '技能释放目标关系类型  2.友军 3.敌军',
  `is_crit` smallint(5) NOT NULL DEFAULT '0' COMMENT '是否必定暴击 0.否 1.是',
  `sing_time` int(11) NOT NULL DEFAULT '0' COMMENT '吟唱时间(毫秒)',
  `sing_break` tinyint(4) NOT NULL DEFAULT '0' COMMENT '吟唱状态可否中断(1可，0木)',
  `description` varchar(200) NOT NULL DEFAULT '' COMMENT '技能描述',
  `attack_choose` int(10) DEFAULT '0' COMMENT '不知道嘛东西，据说客户端使用',
  `start_effect_id` varchar(255) DEFAULT '0' COMMENT '起手特效ID',
  `start_effect_relative_time` int(10) DEFAULT '0' COMMENT '起手动作播放到第X毫秒时，开始播放起手特效',
  `start_frame_speed` int(10) DEFAULT '0' COMMENT '起始帧速',
  `end_effect_id` varchar(255) DEFAULT '0' COMMENT '终止特效ID',
  `end_effect_relative_time` int(10) DEFAULT '0' COMMENT '起手动作播放到第Y毫秒时，开始播放伤害飘字',
  `end_frame_speed` int(10) DEFAULT '0' COMMENT '被击特效帧速',
  `is_caused_by_buff` tinyint(10) DEFAULT '0' COMMENT '是否buff触发的子技能 0.否 1.是',
  `immediate_bullet_effect_id` varchar(64) DEFAULT NULL COMMENT '目标施放特效美术特效ID',
  `immediate_bullet_relative_time` int(11) DEFAULT NULL COMMENT '施法动作第几贞施放目标特效',
  `immediate_bullet_frame_speed` int(11) DEFAULT NULL COMMENT '目标特效释放每贞数率',
  `atk_total_time` int(11) DEFAULT NULL COMMENT '攻击动作总时间用以表现对不同的攻击动作',
  `is_play_wave_effect` int(11) DEFAULT NULL COMMENT '是否攻击时播放刀光',
  `is_monster_skill` tinyint(4) DEFAULT '0' COMMENT '是否只对怪物有效0.对玩家与怪都有效 1.只对怪物有效',
  `is_share_damage` tinyint(4) DEFAULT '0' COMMENT '是否分摊伤害0.否 1.是',
  PRIMARY KEY (`sid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `temp_skill_attr`
-- ----------------------------
CREATE TABLE `temp_skill_attr` (
  `attr_id` int(5) NOT NULL DEFAULT '0' COMMENT '前端用的id',
  `sid` smallint(6) NOT NULL DEFAULT '0' COMMENT '技能ID',
  `level` smallint(6) NOT NULL DEFAULT '0' COMMENT '等级',
  `buff` varchar(10240) NOT NULL DEFAULT '[]' COMMENT '技能BUFF[BuffId,...]',
  `require_list` varchar(200) NOT NULL DEFAULT '[]' COMMENT '学习技能需要技能列表[{SkilId, Level},...]',
  `learn_level` int(11) NOT NULL DEFAULT '0' COMMENT '学习技能需要玩家等级',
  `cost_lilian` int(11) NOT NULL DEFAULT '0' COMMENT '升级需要历练值',
  `cost_coin` int(11) NOT NULL DEFAULT '0' COMMENT '升级需要铜钱值',
  `cost_energy` varchar(32) NOT NULL DEFAULT '{0,0}' COMMENT '消耗能量值 {消耗能量值,消耗能量值百分比}',
  `desc` varchar(100) DEFAULT NULL COMMENT '描述，用于前端显示',
  `pvp_param` varchar(256) NOT NULL DEFAULT '[0,0,0,0,0,0,0,0]' COMMENT '技能pvp属性',
  `pve_param` varchar(256) NOT NULL DEFAULT '[0,0,0,0,0,0,0,0]' COMMENT '技能pve属性',
  PRIMARY KEY (`sid`,`level`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `temp_stren`
-- ----------------------------
CREATE TABLE `temp_stren` (
  `stren_lv` int(10) unsigned NOT NULL COMMENT '强化等级',
  `add_percent` int(10) unsigned NOT NULL COMMENT '附加属性比例',
  `goods` int(11) NOT NULL DEFAULT '0' COMMENT '强化石id',
  `cost_coin` int(11) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `stren_rate` int(10) unsigned NOT NULL COMMENT '强化基础成功率',
  `stren_succ` varchar(50) NOT NULL DEFAULT '[]' COMMENT '强化成功等级增加区间',
  `stren_fail` varchar(50) NOT NULL DEFAULT '[]' COMMENT '强化失败等级掉落区间',
  `add_succ_rate` int(10) NOT NULL COMMENT '强化失败后，下次强化成功率增加值',
  `add_holes` smallint(6) NOT NULL DEFAULT '0' COMMENT '新增插槽',
  `desc` varchar(50) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`stren_lv`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='强化模版表';

-- ----------------------------
--  Table structure for `temp_suit_reward`
-- ----------------------------
CREATE TABLE `temp_suit_reward` (
  `suit_id` int(10) NOT NULL COMMENT '套装id',
  `num` int(10) NOT NULL COMMENT '套装件数',
  `add_value` varchar(150) NOT NULL DEFAULT '[]' COMMENT '属性加成',
  PRIMARY KEY (`suit_id`,`num`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='套装装备加成';

-- ----------------------------
--  Table structure for `temp_task`
-- ----------------------------
CREATE TABLE `temp_task` (
  `tid` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '任务编号',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '任务类型(见task.hrl)',
  `start_npc` int(11) NOT NULL DEFAULT '0' COMMENT '开始NPC',
  `start_scene` int(11) NOT NULL DEFAULT '0' COMMENT '开始场景',
  `end_npc` int(11) NOT NULL DEFAULT '0' COMMENT '结束NPC',
  `end_scene` int(11) NOT NULL DEFAULT '0' COMMENT '结束场景',
  `target_type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '任务目标类型',
  `target_property` varchar(60) NOT NULL DEFAULT '0' COMMENT '任务目标数量[[id,fin_num,begin_num]]',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '任务名称',
  `desc` varchar(50) NOT NULL DEFAULT '' COMMENT '任务描述',
  `ongoing_dialog` varchar(512) NOT NULL DEFAULT '""' COMMENT '未完成任务对白',
  `finish_dialog` varchar(512) NOT NULL COMMENT '完成任务对白，格式为：[{NPC对白},{角色对白}]，若角色不说话，则格式为：[{NPC对白}]',
  `pre_tid` int(11) NOT NULL DEFAULT '0' COMMENT '要求前置任务编号',
  `level` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '等级限制',
  `career` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '职业限定(0:不限，其他为对应职业)',
  `gender` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '性别限定(2:不限，其他为对应性别)',
  `guild` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '家族限定(0:不限，1:有家族才能接)',
  `team` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '组队限定(0：不限，1：组队才能做)',
  `goods_list` varchar(256) NOT NULL DEFAULT '[]' COMMENT '任务可选奖励物品列表[{标识类型(0:无标识 1:以职业为标识),类型编号,奖品id,奖品数量}..]',
  `guild_goods_list` varchar(50) NOT NULL DEFAULT '[]' COMMENT '任务奖励帮派资源列表',
  `func_num` int(11) NOT NULL DEFAULT '0' COMMENT '任务目标类型(前段用)',
  `next_tid` int(11) NOT NULL COMMENT '下一级任务id',
  `end_opera` int(11) NOT NULL DEFAULT '0' COMMENT '任务结束后对话',
  PRIMARY KEY (`tid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='任务表';

-- ----------------------------
--  Table structure for `temp_task_daily_dungeon`
-- ----------------------------
CREATE TABLE `temp_task_daily_dungeon` (
  `id` int(11) NOT NULL,
  `layout_id` bigint(20) DEFAULT NULL,
  `dungeon_name` varchar(100) DEFAULT NULL,
  `level_limit` int(10) DEFAULT NULL,
  `trigger_accept` int(10) DEFAULT NULL,
  `task_description` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_task_detail`
-- ----------------------------
CREATE TABLE `temp_task_detail` (
  `task_type` tinyint(4) NOT NULL COMMENT '任务类型',
  `can_cyc` tinyint(1) NOT NULL COMMENT '是否支持循环 0:不支持 1:支持',
  `trigger_time` tinyint(4) NOT NULL COMMENT '可触发轮数',
  `cycle_time` tinyint(4) NOT NULL COMMENT '每轮可触发次数',
  `meanw_trigger` tinyint(4) NOT NULL COMMENT '每次可同时触发任务数',
  `time_limit` varchar(256) NOT NULL COMMENT '时间段限制[{开始时间，结束时间}...]',
  `reset_time` varchar(30) NOT NULL COMMENT '重置时间',
  `coin` int(7) NOT NULL DEFAULT '0' COMMENT '自动完成任务所需的元宝',
  PRIMARY KEY (`task_type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
--  Table structure for `temp_task_factor`
-- ----------------------------
CREATE TABLE `temp_task_factor` (
  `task_type` tinyint(4) NOT NULL COMMENT '任务类型',
  `grade` tinyint(4) NOT NULL DEFAULT '0' COMMENT '任务品质',
  `fact1` float NOT NULL DEFAULT '0' COMMENT '影响因子1',
  `fact2` float NOT NULL DEFAULT '0' COMMENT '影响因子2',
  `fact3` float NOT NULL DEFAULT '0' COMMENT '影响因子3',
  `fact4` float NOT NULL DEFAULT '0' COMMENT '影响因子3',
  `task_id_span` varchar(50) NOT NULL COMMENT '任务id区间 {minId, maxId}',
  `level_span` tinyint(5) NOT NULL DEFAULT '0' COMMENT 'level区间',
  PRIMARY KEY (`task_type`,`grade`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='日常任务等级影响因子';

-- ----------------------------
--  Table structure for `temp_tips`
-- ----------------------------
CREATE TABLE `temp_tips` (
  `id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '消息ID',
  `type` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '0 - 提示语，发给单个人的。\r\n1 - 屏幕中央向上翻滚。\r\n2 - 聊天区\r\n3 - 1+2',
  `color` smallint(2) DEFAULT '0' COMMENT '1 - 白\r\n2 - 绿\r\n3 - 蓝\r\n4 - 紫\r\n5 - 橙\r\n6 - 红',
  `content` varchar(500) NOT NULL DEFAULT '""' COMMENT '消息内容',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
--  Table structure for `temp_upgrade`
-- ----------------------------
CREATE TABLE `temp_upgrade` (
  `gtid` int(10) NOT NULL COMMENT '当前物品id',
  `goods` varchar(100) NOT NULL COMMENT '配方',
  `cost_coin` int(11) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `target_gtid` varchar(50) NOT NULL COMMENT '目标物品id',
  PRIMARY KEY (`gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='装备升级模版';

-- ----------------------------
--  Table structure for `temp_vip`
-- ----------------------------
CREATE TABLE `temp_vip` (
  `level` int(11) NOT NULL COMMENT '1-体验VIP；\r\n2-一天VIP；\r\n3-白银VIP；\r\n4-黄金VIP；\r\n5-钻石VIP；\r\n6-至尊VIP；',
  `name` varchar(64) NOT NULL COMMENT 'VIP名字',
  `condition` int(11) NOT NULL COMMENT '与level对应\r\n1-任务id\r\n2-物品id\r\n3-物品id\r\n4-物品id\r\n5-物品id\r\n6-充值额度，RMB',
  `cost` int(11) NOT NULL DEFAULT '0' COMMENT 'VIP售价',
  `vip_map_id` int(11) NOT NULL COMMENT '与场景模板表temp_scene相对应',
  `description` varchar(256) NOT NULL COMMENT 'VIP描述信息，用于前端展示',
  `vip_time` int(11) NOT NULL COMMENT '以分钟为单位 ',
  `vip_goods_bag` int(11) NOT NULL COMMENT 'VIP礼包id，与temp_goods表相对应',
  `vip_buff_id` int(11) NOT NULL COMMENT '在temp_buff表中配置',
  `freefly` int(11) NOT NULL COMMENT '每天免费传送的次数',
  `freebag` int(11) NOT NULL COMMENT '背包赠送格子数',
  `title` varchar(64) NOT NULL DEFAULT '0' COMMENT '角色头顶图片资源',
  `desc` varchar(64) NOT NULL DEFAULT '' COMMENT 'VIP说明字段',
  PRIMARY KEY (`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Table structure for `temp_vip_bag`
-- ----------------------------
CREATE TABLE `temp_vip_bag` (
  `vip_gtid` int(10) NOT NULL DEFAULT '0',
  `cell_num` int(10) DEFAULT NULL,
  PRIMARY KEY (`vip_gtid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='vip背包模版表';

-- ----------------------------
--  Table structure for `user`
-- ----------------------------
CREATE TABLE `user` (
  `account_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '平台账号id',
  `account_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账号',
  `state` smallint(5) NOT NULL DEFAULT '0' COMMENT '账号状态(0正常；1被封)',
  `id_card_state` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '身份证验证状态，0表示没填身份证信息，1表示成年人，2表示未成年人，3表示暂时未填身份证信息',
  PRIMARY KEY (`account_id`),
  KEY `account_name` (`account_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='平台账号';

-- ----------------------------
--  Table structure for `world_level`
-- ----------------------------
CREATE TABLE `world_level` (
  `sid` int(11) NOT NULL DEFAULT '0' COMMENT '服务器编号',
  `state` tinyint(1) NOT NULL DEFAULT '0' COMMENT '世界等级开放状态0未开放，1开放',
  `world_level` smallint(6) NOT NULL DEFAULT '0' COMMENT '实际的世界等级',
  `timestamp` int(11) NOT NULL DEFAULT '0' COMMENT '开启时间点',
  PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records 
-- ----------------------------
