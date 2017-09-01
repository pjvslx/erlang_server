/*
MySQL Backup
Source Server Version: 5.1.50
Source Database: smxx_log
Date: 2013/9/29 16:02:52
*/


-- ----------------------------
--  Table structure for `audit_gold_cost`
-- ----------------------------
CREATE TABLE `audit_gold_cost` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_type` int(11) NOT NULL COMMENT '消费类型',
  `gold_count` int(11) NOT NULL COMMENT '元宝数量',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='各消费类型元宝消耗统计';

-- ----------------------------
--  Table structure for `audit_gold_stock`
-- ----------------------------
CREATE TABLE `audit_gold_stock` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `all_gold` int(11) NOT NULL COMMENT '总充值元宝',
  `send_gold` int(11) NOT NULL DEFAULT '0' COMMENT '充值赠送元宝数',
  `used_gold` int(11) NOT NULL COMMENT '消耗元宝',
  `remain_gold` int(11) NOT NULL COMMENT '元宝库存总量',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='元宝库存';

-- ----------------------------
--  Table structure for `audit_goods_cost`
-- ----------------------------
CREATE TABLE `audit_goods_cost` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) NOT NULL COMMENT '物品id',
  `used_count` int(11) NOT NULL COMMENT '消耗的物品数量',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='物品的消耗量（不区分是商城购买还是系统产出，只要有消耗，就加1，区分两套道具，只有在商城有销售的物品才统计消耗）';

-- ----------------------------
--  Table structure for `audit_goods_output`
-- ----------------------------
CREATE TABLE `audit_goods_output` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) NOT NULL COMMENT '物品id',
  `get_count` int(11) NOT NULL COMMENT '玩家获得的物品数量',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='物品产出统计（统计除了商城购买外，其他任何方式取得的道具数据，包括开箱子、淘宝等方式，可以只统计商城有售的物品清单）';

-- ----------------------------
--  Table structure for `audit_goods_sell`
-- ----------------------------
CREATE TABLE `audit_goods_sell` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) NOT NULL COMMENT '物品id',
  `buy_count` int(11) NOT NULL COMMENT '购买的物品数量',
  `cost` int(11) NOT NULL COMMENT '总价',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='商城物品销售统计';

-- ----------------------------
--  Table structure for `audit_goods_stock`
-- ----------------------------
CREATE TABLE `audit_goods_stock` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_id` int(11) NOT NULL COMMENT '物品id',
  `remain_count` int(11) NOT NULL COMMENT '剩余的物品数量',
  `recdate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `recdate` (`recdate`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='物品的库存量（仅统计商城有出售的物品）';

-- ----------------------------
--  Table structure for `config_cost_type`
-- ----------------------------
CREATE TABLE `config_cost_type` (
  `type_id` int(10) NOT NULL DEFAULT '0' COMMENT '消费类型编码',
  `type_name` varchar(100) NOT NULL DEFAULT '0' COMMENT '消费类型名称',
  PRIMARY KEY (`type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='消费类型配置表';

-- ----------------------------
--  Table structure for `config_logout_type`
-- ----------------------------
CREATE TABLE `config_logout_type` (
  `id` tinyint(4) NOT NULL,
  `reason` varchar(100) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='退出异常或者原因';

-- ----------------------------
--  Table structure for `config_money_type`
-- ----------------------------
CREATE TABLE `config_money_type` (
  `id` int(10) NOT NULL DEFAULT '0',
  `money_type` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='货币来源和消耗类型';

-- ----------------------------
--  Table structure for `config_pay_type`
-- ----------------------------
CREATE TABLE `config_pay_type` (
  `id` int(10) DEFAULT NULL,
  `pay_type` varchar(100) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='充入渠道';

-- ----------------------------
--  Table structure for `config_task_type`
-- ----------------------------
CREATE TABLE `config_task_type` (
  `id` int(10) NOT NULL DEFAULT '0',
  `task_type` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='任务类型配置表';

-- ----------------------------
--  Table structure for `log_activity`
-- ----------------------------
CREATE TABLE `log_activity` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '角色id',
  `acnm` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账户',
  `activity_id` smallint(6) NOT NULL COMMENT '活动id',
  `status` tinyint(4) NOT NULL COMMENT '状态',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳',
  PRIMARY KEY (`id`),
  KEY `create_time` (`create_time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='功能参与度日志';

-- ----------------------------
--  Table structure for `log_add_coin`
-- ----------------------------
CREATE TABLE `log_add_coin` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色id',
  `num` int(11) NOT NULL DEFAULT '0' COMMENT '数量',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0绑定铜钱,1铜钱',
  `source` int(11) NOT NULL DEFAULT '0' COMMENT '来源',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=3329 DEFAULT CHARSET=utf8 COMMENT='发放铜钱和绑定铜钱日志';

-- ----------------------------
--  Table structure for `log_add_exp`
-- ----------------------------
CREATE TABLE `log_add_exp` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色id',
  `num` int(11) NOT NULL DEFAULT '0' COMMENT '数量',
  `source` int(11) NOT NULL DEFAULT '0' COMMENT '来源',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `obj_id` int(11) NOT NULL DEFAULT '0' COMMENT '挂了对象id',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=51061 DEFAULT CHARSET=utf8 COMMENT='添加经验log';

-- ----------------------------
--  Table structure for `log_add_gold`
-- ----------------------------
CREATE TABLE `log_add_gold` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色id',
  `num` int(11) NOT NULL DEFAULT '0' COMMENT '数量',
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0绑定元宝,1元宝',
  `source` int(11) NOT NULL DEFAULT '0' COMMENT '来源',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=109 DEFAULT CHARSET=utf8 COMMENT='发放元宝和绑定元宝日志';

-- ----------------------------
--  Table structure for `log_add_goods`
-- ----------------------------
CREATE TABLE `log_add_goods` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0',
  `gtid` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `bind` tinyint(4) NOT NULL COMMENT '0不限制,2装备绑定,3已绑定',
  `add_type` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=4064 DEFAULT CHARSET=utf8 COMMENT='物品发放日志';

-- ----------------------------
--  Table structure for `log_cost_coin`
-- ----------------------------
CREATE TABLE `log_cost_coin` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色id',
  `coin` int(11) NOT NULL DEFAULT '0' COMMENT '铜钱',
  `bcoin` int(11) NOT NULL DEFAULT '0' COMMENT '绑定铜钱',
  `cost_type` int(11) NOT NULL DEFAULT '0' COMMENT '消耗类型',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `create_time` (`create_time`)
) ENGINE=MyISAM AUTO_INCREMENT=1439 DEFAULT CHARSET=utf8 COMMENT='铜钱消耗日志';

-- ----------------------------
--  Table structure for `log_cost_gold`
-- ----------------------------
CREATE TABLE `log_cost_gold` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色id',
  `gold` int(11) NOT NULL DEFAULT '0' COMMENT '消耗元宝',
  `bgold` int(11) NOT NULL DEFAULT '0' COMMENT '消耗绑定元宝',
  `cost_type` int(11) NOT NULL DEFAULT '0' COMMENT '消费类型',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `create_time` (`create_time`)
) ENGINE=MyISAM AUTO_INCREMENT=1116 DEFAULT CHARSET=utf8 COMMENT='元宝消耗日志';

-- ----------------------------
--  Table structure for `log_cost_goods`
-- ----------------------------
CREATE TABLE `log_cost_goods` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL DEFAULT '0',
  `gtid` int(11) NOT NULL DEFAULT '0',
  `num` int(11) NOT NULL DEFAULT '0',
  `bind` tinyint(4) NOT NULL COMMENT '0不限制,2装备绑定,3已绑定',
  `cost_type` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `create_time` (`create_time`)
) ENGINE=MyISAM AUTO_INCREMENT=1858 DEFAULT CHARSET=utf8 COMMENT='消耗物品日志';

-- ----------------------------
--  Table structure for `log_gem`
-- ----------------------------
CREATE TABLE `log_gem` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `gid` bigint(20) NOT NULL,
  `gtid` int(11) NOT NULL,
  `type` tinyint(4) NOT NULL COMMENT '0镶嵌,1拆除',
  `old_gem` varchar(100) NOT NULL,
  `new_gem` varchar(100) NOT NULL,
  `coin` int(11) NOT NULL,
  `bcoin` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宝石镶嵌、拆除';

-- ----------------------------
--  Table structure for `log_gem_compose`
-- ----------------------------
CREATE TABLE `log_gem_compose` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) DEFAULT NULL,
  `gid` bigint(20) DEFAULT NULL,
  `gtid` int(11) DEFAULT NULL,
  `cost_goods` varchar(100) DEFAULT NULL,
  `coin` int(11) DEFAULT NULL,
  `bcoin` int(11) DEFAULT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宝石合成';

-- ----------------------------
--  Table structure for `log_gilding`
-- ----------------------------
CREATE TABLE `log_gilding` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `gid` bigint(20) NOT NULL,
  `gtid` int(11) NOT NULL,
  `coin` int(11) NOT NULL,
  `bcoin` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='镀金';

-- ----------------------------
--  Table structure for `log_godtried`
-- ----------------------------
CREATE TABLE `log_godtried` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `gid` bigint(20) NOT NULL,
  `gtid` int(11) NOT NULL,
  `cost_goods` varchar(100) NOT NULL,
  `coin` int(11) NOT NULL,
  `bcoin` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='宝石神炼';

-- ----------------------------
--  Table structure for `log_kick_off`
-- ----------------------------
CREATE TABLE `log_kick_off` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) unsigned NOT NULL COMMENT '用户ID',
  `nick` varchar(200) CHARACTER SET utf8 NOT NULL COMMENT '名称',
  `k_type` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '踢出类型:1废号,2发包异常,3超时,7心跳包异常,8走路异常,9切换场景异常',
  `time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '时间记录',
  `scene` int(11) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `other` varchar(255) CHARACTER SET utf8 NOT NULL DEFAULT '[]' COMMENT '其他',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=650 DEFAULT CHARSET=latin1 COMMENT='镇妖塔日志';

-- ----------------------------
--  Table structure for `log_pay`
-- ----------------------------
CREATE TABLE `log_pay` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `pay_num` varchar(20) CHARACTER SET latin1 NOT NULL DEFAULT '' COMMENT '充值订单号',
  `pay_user` varchar(20) CHARACTER SET latin1 NOT NULL DEFAULT '' COMMENT '充值用户名',
  `player_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '玩家角色ID',
  `nickname` varchar(50) CHARACTER SET latin1 NOT NULL DEFAULT '' COMMENT '角色名称',
  `lv` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT '角色等级',
  `reg_time` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '注册时间',
  `first_pay` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '是否第一次充值:1-是0-否',
  `money` int(11) unsigned DEFAULT '0' COMMENT '币货数',
  `pay_gold` int(11) NOT NULL DEFAULT '0' COMMENT '游戏币数量',
  `pay_time` int(11) NOT NULL DEFAULT '0' COMMENT '来自平台的时间 ',
  `insert_time` int(11) NOT NULL DEFAULT '0' COMMENT '插入数据库时间',
  `pay_status` smallint(6) NOT NULL DEFAULT '0' COMMENT '支付状态(1:成功;0失败;2:角色不存在)',
  `state` smallint(55) NOT NULL DEFAULT '0' COMMENT '奖励系统使用标志(0 未使用，1已使用)',
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`) USING BTREE,
  KEY `nickname` (`nickname`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='玩家充值记录表';

-- ----------------------------
--  Table structure for `log_pet_evolve`
-- ----------------------------
CREATE TABLE `log_pet_evolve` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `old_growth_lv` int(10) NOT NULL COMMENT '原来成长值',
  `new_growth_lv` int(10) NOT NULL COMMENT '新的成长值',
  `old_growth_progress` int(10) NOT NULL COMMENT '原来成长进度',
  `new_growth_progress` int(10) NOT NULL COMMENT '新的成长进度',
  `gold` int(10) NOT NULL DEFAULT '0' COMMENT '消耗元宝',
  `coin` int(10) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `cost_goods` int(10) NOT NULL DEFAULT '0' COMMENT '消耗物品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=124 DEFAULT CHARSET=utf8 COMMENT='宠物进化';

-- ----------------------------
--  Table structure for `log_pet_upgrade`
-- ----------------------------
CREATE TABLE `log_pet_upgrade` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `old_aptitude_lv` int(10) NOT NULL COMMENT '原来资质',
  `new_aptitude_lv` int(10) NOT NULL COMMENT '新的资质',
  `old_aptitude_progress` int(10) NOT NULL COMMENT '原来资质进度',
  `new_aptitude_progress` int(10) NOT NULL COMMENT '新的资质进度',
  `gold` int(10) NOT NULL DEFAULT '0' COMMENT '消耗元宝',
  `coin` int(10) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `cost_goods` int(11) NOT NULL DEFAULT '0' COMMENT '消耗物品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=339 DEFAULT CHARSET=utf8 COMMENT='宠物提升';

-- ----------------------------
--  Table structure for `log_pet_upgrade_quality`
-- ----------------------------
CREATE TABLE `log_pet_upgrade_quality` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `old_quality_lv` int(10) NOT NULL COMMENT '原来品阶',
  `new_quality_lv` int(10) NOT NULL COMMENT '新的品阶',
  `succ_rate` int(10) NOT NULL COMMENT '成功率',
  `add_rate` int(10) NOT NULL COMMENT '幸运值',
  `gold` int(10) NOT NULL DEFAULT '0' COMMENT '消耗元宝',
  `coin` int(10) NOT NULL DEFAULT '0' COMMENT '消耗铜钱',
  `cost_goods` int(11) NOT NULL DEFAULT '0' COMMENT '消耗物品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='宠物进阶';

-- ----------------------------
--  Table structure for `log_player`
-- ----------------------------
CREATE TABLE `log_player` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `acid` int(11) NOT NULL COMMENT '平台Id',
  `acnm` varchar(50) NOT NULL COMMENT '平台账户',
  `uid` bigint(20) NOT NULL COMMENT '角色id',
  `nick` varchar(50) NOT NULL COMMENT '昵称',
  `sex` tinyint(4) DEFAULT NULL COMMENT '性别',
  `career` tinyint(4) DEFAULT NULL COMMENT '职业',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='创建角色';

-- ----------------------------
--  Table structure for `log_quit`
-- ----------------------------
CREATE TABLE `log_quit` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '角色id',
  `acnm` varchar(50) DEFAULT '' COMMENT '平台账户',
  `time_duration` int(10) NOT NULL COMMENT '玩家游戏时长',
  `reason_id` tinyint(4) NOT NULL DEFAULT '1' COMMENT '退出异常或者原因',
  `login_lv` int(7) NOT NULL COMMENT '登陆时等级',
  `logout_lv` int(7) NOT NULL COMMENT '退出时等级',
  `login_ip` varchar(64) NOT NULL COMMENT '登陆ip',
  `login_time` int(11) NOT NULL COMMENT '登陆时间',
  `logout_time` int(11) NOT NULL COMMENT '退出时间',
  `logout_scene_id` int(11) NOT NULL COMMENT '退出场景id',
  `msg` varchar(256) NOT NULL DEFAULT '无' COMMENT '异常信息',
  `os` varchar(32) NOT NULL DEFAULT '未知' COMMENT '操作系统',
  `os_version` varchar(32) NOT NULL DEFAULT '未知' COMMENT '操作系统版本',
  `device` varchar(32) NOT NULL DEFAULT '未知' COMMENT '设备名称',
  `device_type` varchar(32) NOT NULL DEFAULT '未知' COMMENT '设备类型',
  `screen` varchar(32) NOT NULL DEFAULT '未知' COMMENT '屏幕分辨率',
  `mno` varchar(32) NOT NULL DEFAULT '未知' COMMENT '移动网络运营商',
  `nm` varchar(32) NOT NULL DEFAULT '未知' COMMENT '联网方式',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='玩家退出';

-- ----------------------------
--  Table structure for `log_real_play`
-- ----------------------------
CREATE TABLE `log_real_play` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `pt` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '真正开始游戏的时间',
  `uid` int(11) NOT NULL DEFAULT '0' COMMENT '角色ID',
  PRIMARY KEY (`id`),
  KEY `cp_time` (`pt`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='玩家真正开始游戏时间表';

-- ----------------------------
--  Table structure for `log_recharge`
-- ----------------------------
CREATE TABLE `log_recharge` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '角色id',
  `acnm` varchar(50) DEFAULT '' COMMENT '平台账户',
  `level` smallint(6) NOT NULL COMMENT '等级',
  `type` tinyint(4) NOT NULL COMMENT '充入渠道',
  `gold_num` int(11) NOT NULL COMMENT '充入的金钱',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='玩家充值记录';

-- ----------------------------
--  Table structure for `log_stren`
-- ----------------------------
CREATE TABLE `log_stren` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL COMMENT '玩家id',
  `gtid` int(11) NOT NULL COMMENT '装备类型id',
  `old_stren` tinyint(11) NOT NULL COMMENT '原强化等级',
  `old_stren_percent` tinyint(11) NOT NULL COMMENT '原强化完美度',
  `new_stren` tinyint(11) NOT NULL COMMENT '新强化等级',
  `new_stren_percent` tinyint(11) unsigned NOT NULL COMMENT '新强化完美度',
  `coin` int(11) NOT NULL COMMENT '消耗铜钱',
  `gold` int(11) NOT NULL COMMENT '消耗元宝',
  `cost_goods` int(11) NOT NULL COMMENT '消耗物品',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM AUTO_INCREMENT=428 DEFAULT CHARSET=utf8 COMMENT='强化日志表';

-- ----------------------------
--  Table structure for `log_upgrade`
-- ----------------------------
CREATE TABLE `log_upgrade` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `gid` bigint(20) NOT NULL,
  `gtid` int(11) NOT NULL,
  `new_gtid` int(11) NOT NULL,
  `coin` int(11) NOT NULL,
  `bcoin` int(11) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='装备升级';

-- ----------------------------
--  Table structure for `log_wash`
-- ----------------------------
CREATE TABLE `log_wash` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uid` bigint(20) NOT NULL,
  `gid` bigint(20) NOT NULL,
  `gtid` int(11) NOT NULL,
  `old_attri` varchar(100) NOT NULL,
  `new_attri` varchar(100) NOT NULL,
  `coin` int(11) NOT NULL,
  `bcoin` int(11) NOT NULL,
  `gold` int(11) NOT NULL,
  `bgold` int(11) NOT NULL,
  `cost_goods` varchar(100) NOT NULL,
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='洗练日志';

-- ----------------------------
--  Table structure for `tbllog_auction`
-- ----------------------------
CREATE TABLE `tbllog_auction` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '寄售流水号',
  `auction_id` int(11) NOT NULL COMMENT '拍卖交易ID',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL COMMENT '平台账号',
  `opt_type_id` tinyint(4) NOT NULL COMMENT '拍卖操作类型',
  `item_id` int(11) NOT NULL COMMENT '拍卖物品id',
  `item_number` int(11) NOT NULL COMMENT '拍卖物品数量',
  `bid_price_list` varchar(50) NOT NULL COMMENT '拍卖价格',
  `a_price_list` varchar(50) NOT NULL DEFAULT '' COMMENT '一口价',
  `happened_time` int(11) NOT NULL COMMENT '拍卖事件发生时间',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '写日志时间',
  PRIMARY KEY (`id`),
  KEY `log_time` (`happened_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COMMENT='商城购买日志';

-- ----------------------------
--  Table structure for `tbllog_equipment`
-- ----------------------------
CREATE TABLE `tbllog_equipment` (
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL COMMENT '平台账户',
  `dim_level` int(11) NOT NULL COMMENT '玩家等级',
  `item_id` bigint(20) NOT NULL COMMENT '装备ID',
  `value_before` int(11) NOT NULL COMMENT '装备变化前数值',
  `value_after` int(11) NOT NULL COMMENT '装备变化后数值',
  `change_type` int(11) NOT NULL COMMENT '装备经过锻造或合成后，装备状态变化的类型。',
  `material` varchar(1000) NOT NULL COMMENT '所需的材料，可能是道具或货币',
  `happend_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` int(11) NOT NULL COMMENT '写日志时间，索引字段'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='装备锻造、洗练、合成日志';

-- ----------------------------
--  Table structure for `tbllog_fb`
-- ----------------------------
CREATE TABLE `tbllog_fb` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '寄售流水号',
  `fb_id` int(11) NOT NULL COMMENT '副本id',
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL COMMENT '平台账号',
  `dim_level` int(11) NOT NULL COMMENT '玩家等级',
  `fb_level` int(11) NOT NULL COMMENT '副本层数/关卡数',
  `status` int(11) NOT NULL COMMENT '参与状态(1=参与，2=完成)',
  `happened_time` int(11) NOT NULL COMMENT '副本参与时间',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '写日志时间',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=414 DEFAULT CHARSET=utf8 COMMENT='商城购买日志';

-- ----------------------------
--  Table structure for `tbllog_gold`
-- ----------------------------
CREATE TABLE `tbllog_gold` (
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL COMMENT '平台账户',
  `dim_level` int(11) NOT NULL COMMENT '等级',
  `dim_prof` int(11) NOT NULL COMMENT '职业id',
  `money_type` int(11) NOT NULL COMMENT '货币类型（1=金币，2=绑定金币，3=铜币，4=绑定铜币，5=礼券，6=积分/荣誉, 7=兑换）',
  `amount` int(11) NOT NULL COMMENT '货币数量',
  `money_remain` int(11) NOT NULL COMMENT '剩余货币数量',
  `opt` int(11) NOT NULL COMMENT '货币加减 （1=增加，2=减少）',
  `action_1` int(11) NOT NULL COMMENT '行为分类1 （一级消费点）',
  `action_2` int(11) NOT NULL COMMENT '若存在一级消费点,不存在二级消费点,则二级消费点设为一级消费点的值',
  `item_number` int(11) NOT NULL COMMENT '物品数量',
  `happend_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` int(11) NOT NULL COMMENT '写日志时间，索引字段'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='货币变动日志';

-- ----------------------------
--  Table structure for `tbllog_items`
-- ----------------------------
CREATE TABLE `tbllog_items` (
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL COMMENT '平台账户',
  `dim_level` int(11) NOT NULL COMMENT '玩家等级',
  `opt` int(11) NOT NULL COMMENT '操作类型 ( 1 是获得，0 是使用)',
  `action_id` int(11) NOT NULL COMMENT '对应各自工作室的道具消耗项目字典,行为类型（dict_action.action_id）',
  `item_id` bigint(20) NOT NULL COMMENT '道具id',
  `item_number` int(11) NOT NULL COMMENT '道具获得/消耗数量',
  `map_id` int(11) NOT NULL COMMENT '物品产出所在地图id(dict_action.action_id)',
  `happend_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` int(11) NOT NULL COMMENT '写日志时间，索引字段'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='3.1.9 道具产出/消耗日志';

-- ----------------------------
--  Table structure for `tbllog_level_up`
-- ----------------------------
CREATE TABLE `tbllog_level_up` (
  `role_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '角色ID',
  `account_name` varchar(32) NOT NULL DEFAULT '""' COMMENT '角色昵称',
  `last_lv` int(11) NOT NULL DEFAULT '0' COMMENT '上一等级',
  `current_level` int(11) NOT NULL DEFAULT '0' COMMENT '当前等级',
  `last_exp` int(11) NOT NULL DEFAULT '0' COMMENT '上一经验值',
  `current_exp` int(11) NOT NULL DEFAULT '0' COMMENT '当前经验值',
  `happend_time` int(11) NOT NULL DEFAULT '0' COMMENT '变动时间',
  KEY `role_id_index` (`role_id`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='等级日志';

-- ----------------------------
--  Table structure for `tbllog_login`
-- ----------------------------
CREATE TABLE `tbllog_login` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账户',
  `dim_level` smallint(6) NOT NULL COMMENT '等级',
  `user_ip` varchar(20) NOT NULL,
  `login_scene_id` int(10) NOT NULL,
  `os` varchar(10) NOT NULL,
  `os_version` varchar(10) NOT NULL,
  `device` varchar(10) NOT NULL,
  `device_type` varchar(10) NOT NULL,
  `screen` varchar(10) NOT NULL,
  `mno` varchar(20) NOT NULL,
  `nm` varchar(20) NOT NULL,
  `happend_time` int(10) NOT NULL,
  `log_time` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`role_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3151 DEFAULT CHARSET=utf8 COMMENT='玩家登陆日志';

-- ----------------------------
--  Table structure for `tbllog_mail`
-- ----------------------------
CREATE TABLE `tbllog_mail` (
  `mail_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `mail_sender_id` bigint(10) NOT NULL,
  `mail_sender_name` varchar(32) CHARACTER SET utf8 NOT NULL,
  `mail_receiver_id` bigint(20) NOT NULL,
  `mail_receiver_name` varchar(32) CHARACTER SET utf8 NOT NULL,
  `mail_title` varchar(128) CHARACTER SET utf8 NOT NULL,
  `mail_content` varchar(128) CHARACTER SET utf8 NOT NULL,
  `mail_type` int(4) NOT NULL,
  `mail_money_list` varchar(64) DEFAULT NULL,
  `mail_item_list` varchar(64) DEFAULT NULL,
  `mail_status` int(4) NOT NULL,
  `happend_time` int(10) NOT NULL,
  `log_time` int(10) NOT NULL,
  PRIMARY KEY (`mail_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
--  Table structure for `tbllog_online`
-- ----------------------------
CREATE TABLE `tbllog_online` (
  `log_time` int(11) NOT NULL COMMENT '写库时间',
  `num` smallint(6) NOT NULL DEFAULT '0' COMMENT '当前在线玩家总人数',
  PRIMARY KEY (`log_time`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='在线人数日志';

-- ----------------------------
--  Table structure for `tbllog_pay`
-- ----------------------------
CREATE TABLE `tbllog_pay` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL COMMENT '角色ID',
  `account_name` varchar(50) NOT NULL DEFAULT '0' COMMENT '平台账号',
  `dim_level` int(10) NOT NULL COMMENT '等级',
  `gold` int(10) NOT NULL COMMENT '元宝数',
  `pay_type` int(10) NOT NULL COMMENT '充值渠道',
  `order_id` varchar(30) NOT NULL COMMENT '充值订单号',
  `pay_money` int(10) NOT NULL COMMENT '充值数',
  `happend_time` int(10) NOT NULL DEFAULT '0' COMMENT '充值时刻',
  `log_time` int(10) NOT NULL COMMENT '记录时刻',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=51 DEFAULT CHARSET=utf8 COMMENT='充值表';

-- ----------------------------
--  Table structure for `tbllog_role`
-- ----------------------------
CREATE TABLE `tbllog_role` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL,
  `account_name` varchar(50) CHARACTER SET utf8 NOT NULL,
  `dim_prof` tinyint(3) NOT NULL,
  `os` varchar(10) CHARACTER SET utf8 NOT NULL,
  `os_version` varchar(10) CHARACTER SET utf8 NOT NULL,
  `device` varchar(10) CHARACTER SET utf8 NOT NULL,
  `device_type` varchar(10) CHARACTER SET utf8 NOT NULL,
  `screen` varchar(10) CHARACTER SET utf8 NOT NULL,
  `mno` varchar(10) CHARACTER SET utf8 NOT NULL,
  `nm` varchar(10) CHARACTER SET utf8 NOT NULL,
  `happend_time` int(10) NOT NULL,
  `log_time` int(10) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- ----------------------------
--  Table structure for `tbllog_sales`
-- ----------------------------
CREATE TABLE `tbllog_sales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sales_id` int(11) NOT NULL COMMENT '寄卖流水号',
  `role_id` bigint(20) NOT NULL COMMENT '寄卖品角色ID',
  `item_id` int(11) NOT NULL COMMENT '寄卖品ID',
  `price_type` tinyint(4) NOT NULL COMMENT '寄卖品价格货币类型',
  `price_unit` int(11) NOT NULL COMMENT '寄卖品价格',
  `item_number` int(11) NOT NULL COMMENT '寄卖品物品数量',
  `action_id` int(4) NOT NULL COMMENT '寄卖操作行为ID',
  `happened_time` int(11) NOT NULL COMMENT '寄卖行为记录时间',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '写日志时间',
  PRIMARY KEY (`id`),
  KEY `log_time` (`log_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=23 DEFAULT CHARSET=utf8 COMMENT='商城购买日志';

-- ----------------------------
--  Table structure for `tbllog_scene_online`
-- ----------------------------
CREATE TABLE `tbllog_scene_online` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '流水号',
  `scene_id` int(11) NOT NULL COMMENT '场景ID',
  `player_num` int(11) NOT NULL COMMENT '场景人数',
  `happened_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP COMMENT '写日志时间，索引字段 ',
  PRIMARY KEY (`id`),
  KEY `log_time` (`log_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=44589 DEFAULT CHARSET=utf8 COMMENT='商城购买日志';

-- ----------------------------
--  Table structure for `tbllog_shop`
-- ----------------------------
CREATE TABLE `tbllog_shop` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账户',
  `dim_level` smallint(6) NOT NULL COMMENT '玩家等级',
  `dim_prof` tinyint(4) NOT NULL COMMENT '职业id',
  `money_type` tinyint(4) NOT NULL COMMENT '货币类型',
  `amount` int(11) NOT NULL DEFAULT '0' COMMENT '货币数量',
  `item_type_1` tinyint(4) NOT NULL COMMENT '物品分类1',
  `item_type_2` int(11) NOT NULL COMMENT '物品分类2',
  `item_id` int(11) NOT NULL COMMENT '物品id',
  `item_number` int(11) NOT NULL COMMENT '物品数量',
  `happend_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '写日志时间，索引字段',
  PRIMARY KEY (`id`),
  KEY `log_time` (`log_time`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=513 DEFAULT CHARSET=utf8 COMMENT='商城购买日志';

-- ----------------------------
--  Table structure for `tbllog_task`
-- ----------------------------
CREATE TABLE `tbllog_task` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(20) NOT NULL COMMENT '角色id',
  `account_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账户',
  `dim_prof` tinyint(4) NOT NULL COMMENT '职业id',
  `dim_level` int(11) NOT NULL DEFAULT '0' COMMENT '角色等级',
  `task_id` int(11) NOT NULL COMMENT '任务id',
  `status` tinyint(4) NOT NULL COMMENT '任务状态(1=接任务；2=完成任务；3=取消任务；4=提交任务)',
  `happend_time` int(11) NOT NULL COMMENT '事件发生时间',
  `log_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '写日志时间，索引字段',
  PRIMARY KEY (`id`),
  KEY `uid` (`role_id`),
  KEY `log_time` (`log_time`)
) ENGINE=MyISAM AUTO_INCREMENT=2251 DEFAULT CHARSET=utf8 COMMENT='任务日志';

-- ----------------------------
--  Table structure for `vip_award_log`
-- ----------------------------
CREATE TABLE `vip_award_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) DEFAULT NULL COMMENT '玩家账号id',
  `vip_level` int(11) DEFAULT NULL COMMENT 'vip等级',
  `create_time` int(11) DEFAULT NULL COMMENT '玩家初次成为vip时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COMMENT='玩家vip信息表 ';

-- ----------------------------
--  View definition for `tbllog_player`
-- ----------------------------
CREATE ALGORITHM=UNDEFINED DEFINER=``@`` SQL SECURITY DEFINER VIEW `tbllog_player` AS select `smxx`.`player`.`id` AS `id`,`smxx`.`player`.`account_id` AS `account_id`,`smxx`.`player`.`account_name` AS `account_name`,`smxx`.`player`.`nick` AS `nick`,`smxx`.`player`.`career` AS `career`,`smxx`.`player`.`gender` AS `gender`,`smxx`.`player`.`camp` AS `camp`,`smxx`.`player`.`level` AS `level`,`smxx`.`player`.`exp` AS `exp`,`smxx`.`player`.`guild_name` AS `guild_name`,`smxx`.`player`.`vip` AS `vip`,`smxx`.`player`.`force` AS `force`,`smxx`.`player`.`last_login_ip` AS `last_login_ip` from `smxx`.`player`;

-- ----------------------------
--  Records 
-- ----------------------------
