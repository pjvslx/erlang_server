/*
Navicat MySQL Data Transfer

Source Server         : 开发服
Source Server Version : 50150
Source Host           : 192.168.44.51:3306
Source Database       : smxx_log

Target Server Type    : MYSQL
Target Server Version : 50150
File Encoding         : 65001

Date: 2013-05-31 14:58:30
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `audit_gold_cost`
-- ----------------------------
DROP TABLE IF EXISTS `audit_gold_cost`;
CREATE TABLE `audit_gold_cost` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_type`  int(11) NOT NULL COMMENT '消费类型' ,
`gold_count`  int(11) NOT NULL COMMENT '元宝数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='各消费类型元宝消耗统计'
AUTO_INCREMENT=1001

;

-- ----------------------------
-- Table structure for `audit_gold_stock`
-- ----------------------------
DROP TABLE IF EXISTS `audit_gold_stock`;
CREATE TABLE `audit_gold_stock` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`all_gold`  int(11) NOT NULL COMMENT '总充值元宝' ,
`send_gold`  int(11) NOT NULL DEFAULT 0 COMMENT '充值赠送元宝数' ,
`used_gold`  int(11) NOT NULL COMMENT '消耗元宝' ,
`remain_gold`  int(11) NOT NULL COMMENT '元宝库存总量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='元宝库存'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `audit_goods_cost`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_cost`;
CREATE TABLE `audit_goods_cost` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`used_count`  int(11) NOT NULL COMMENT '消耗的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品的消耗量（不区分是商城购买还是系统产出，只要有消耗，就加1，区分两套道具，只有在商城有销售的物品才统计消耗）'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `audit_goods_output`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_output`;
CREATE TABLE `audit_goods_output` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`get_count`  int(11) NOT NULL COMMENT '玩家获得的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品产出统计（统计除了商城购买外，其他任何方式取得的道具数据，包括开箱子、淘宝等方式，可以只统计商城有售的物品清单）'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `audit_goods_sell`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_sell`;
CREATE TABLE `audit_goods_sell` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`buy_count`  int(11) NOT NULL COMMENT '购买的物品数量' ,
`cost`  int(11) NOT NULL COMMENT '总价' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='商城物品销售统计'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `audit_goods_stock`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_stock`;
CREATE TABLE `audit_goods_stock` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`remain_count`  int(11) NOT NULL COMMENT '剩余的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品的库存量（仅统计商城有出售的物品）'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `config_cost_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_cost_type`;
CREATE TABLE `config_cost_type` (
`type_id`  int(10) NOT NULL DEFAULT 0 COMMENT '消费类型编码' ,
`type_name`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '消费类型名称' ,
PRIMARY KEY (`type_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='消费类型配置表'

;

-- ----------------------------
-- Table structure for `config_logout_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_logout_type`;
CREATE TABLE `config_logout_type` (
`id`  tinyint(4) NOT NULL ,
`reason`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='退出异常或者原因'

;

-- ----------------------------
-- Table structure for `config_money_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_money_type`;
CREATE TABLE `config_money_type` (
`id`  int(10) NOT NULL DEFAULT 0 ,
`money_type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='货币来源和消耗类型'

;

-- ----------------------------
-- Table structure for `config_pay_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_pay_type`;
CREATE TABLE `config_pay_type` (
`id`  int(10) NULL DEFAULT NULL ,
`pay_type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充入渠道'

;

-- ----------------------------
-- Table structure for `config_task_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_task_type`;
CREATE TABLE `config_task_type` (
`id`  int(10) NOT NULL DEFAULT 0 ,
`task_type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='任务类型配置表'

;

-- ----------------------------
-- Table structure for `log_activity`
-- ----------------------------
DROP TABLE IF EXISTS `log_activity`;
CREATE TABLE `log_activity` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账户' ,
`activity_id`  smallint(6) NOT NULL COMMENT '活动id' ,
`status`  tinyint(4) NOT NULL COMMENT '状态' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='功能参与度日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_add_coin`
-- ----------------------------
DROP TABLE IF EXISTS `log_add_coin`;
CREATE TABLE `log_add_coin` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`num`  int(11) NOT NULL DEFAULT 0 COMMENT '数量' ,
`type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '0绑定铜钱,1铜钱' ,
`source`  int(11) NOT NULL DEFAULT 0 COMMENT '来源' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='发放铜钱和绑定铜钱日志'
AUTO_INCREMENT=17762

;

-- ----------------------------
-- Table structure for `log_add_gold`
-- ----------------------------
DROP TABLE IF EXISTS `log_add_gold`;
CREATE TABLE `log_add_gold` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`num`  int(11) NOT NULL DEFAULT 0 COMMENT '数量' ,
`type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '0绑定元宝,1元宝' ,
`source`  int(11) NOT NULL DEFAULT 0 COMMENT '来源' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='发放元宝和绑定元宝日志'
AUTO_INCREMENT=342

;

-- ----------------------------
-- Table structure for `log_add_goods`
-- ----------------------------
DROP TABLE IF EXISTS `log_add_goods`;
CREATE TABLE `log_add_goods` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 ,
`gtid`  int(11) NOT NULL DEFAULT 0 ,
`num`  int(11) NOT NULL DEFAULT 0 ,
`bind`  tinyint(4) NOT NULL COMMENT '0不限制,2装备绑定,3已绑定' ,
`add_type`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品发放日志'
AUTO_INCREMENT=5406

;

-- ----------------------------
-- Table structure for `log_charge`
-- ----------------------------
DROP TABLE IF EXISTS `log_charge`;
CREATE TABLE `log_charge` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`order_id`  bigint(20) NOT NULL COMMENT '充值订单号' ,
`gold`  int(10) NOT NULL COMMENT '元宝数' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_cost_coin`
-- ----------------------------
DROP TABLE IF EXISTS `log_cost_coin`;
CREATE TABLE `log_cost_coin` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`coin`  int(11) NOT NULL DEFAULT 0 COMMENT '铜钱' ,
`bcoin`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定铜钱' ,
`cost_type`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗类型' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='铜钱消耗日志'
AUTO_INCREMENT=4697

;

-- ----------------------------
-- Table structure for `log_cost_gold`
-- ----------------------------
DROP TABLE IF EXISTS `log_cost_gold`;
CREATE TABLE `log_cost_gold` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`gold`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`bgold`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗绑定元宝' ,
`cost_type`  int(11) NOT NULL DEFAULT 0 COMMENT '消费类型' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='元宝消耗日志'
AUTO_INCREMENT=165

;

-- ----------------------------
-- Table structure for `log_cost_goods`
-- ----------------------------
DROP TABLE IF EXISTS `log_cost_goods`;
CREATE TABLE `log_cost_goods` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 ,
`gtid`  int(11) NOT NULL DEFAULT 0 ,
`num`  int(11) NOT NULL DEFAULT 0 ,
`bind`  tinyint(4) NOT NULL COMMENT '0不限制,2装备绑定,3已绑定' ,
`cost_type`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='消耗物品日志'
AUTO_INCREMENT=5043

;

-- ----------------------------
-- Table structure for `log_dungeon`
-- ----------------------------
DROP TABLE IF EXISTS `log_dungeon`;
CREATE TABLE `log_dungeon` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID' ,
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号ID' ,
`sid`  int(11) NOT NULL COMMENT '平台账号' ,
`enter_time`  int(11) NOT NULL COMMENT '进入副本时间' ,
`end_time`  int(11) NOT NULL COMMENT '进入副本时间' ,
`left_times`  int(5) NOT NULL DEFAULT 0 COMMENT '剩余次数' ,
`assess`  int(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '通关评价' ,
`rewards`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '获得奖品' ,
`reward_time`  int(11) NULL DEFAULT 0 COMMENT '领取奖励时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `idx_uidbg` USING BTREE (`uid`, `enter_time`) ,
INDEX `idx_uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家当前的副本信息'
AUTO_INCREMENT=75

;

-- ----------------------------
-- Table structure for `log_gem`
-- ----------------------------
DROP TABLE IF EXISTS `log_gem`;
CREATE TABLE `log_gem` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`type`  tinyint(4) NOT NULL COMMENT '0镶嵌,1拆除' ,
`old_gem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`new_gem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宝石镶嵌、拆除'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_gem_compose`
-- ----------------------------
DROP TABLE IF EXISTS `log_gem_compose`;
CREATE TABLE `log_gem_compose` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NULL DEFAULT NULL ,
`gid`  bigint(20) NULL DEFAULT NULL ,
`gtid`  int(11) NULL DEFAULT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`coin`  int(11) NULL DEFAULT NULL ,
`bcoin`  int(11) NULL DEFAULT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宝石合成'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_gilding`
-- ----------------------------
DROP TABLE IF EXISTS `log_gilding`;
CREATE TABLE `log_gilding` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='镀金'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_godtried`
-- ----------------------------
DROP TABLE IF EXISTS `log_godtried`;
CREATE TABLE `log_godtried` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宝石神炼'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_kick_off`
-- ----------------------------
DROP TABLE IF EXISTS `log_kick_off`;
CREATE TABLE `log_kick_off` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) UNSIGNED NOT NULL COMMENT '用户ID' ,
`nick`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '名称' ,
`k_type`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '踢出类型:1废号,2发包异常,3超时,7心跳包异常,8走路异常,9切换场景异常' ,
`time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '时间记录' ,
`scene`  int(11) NOT NULL ,
`x`  int(11) NOT NULL ,
`y`  int(11) NOT NULL ,
`other`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '其他' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='镇妖塔日志'
AUTO_INCREMENT=7721

;

-- ----------------------------
-- Table structure for `log_level`
-- ----------------------------
DROP TABLE IF EXISTS `log_level`;
CREATE TABLE `log_level` (
`log_time`  int(11) NOT NULL COMMENT '时间戳' ,
`level`  smallint(6) NOT NULL COMMENT '等级' ,
`num`  int(10) NOT NULL COMMENT '用户人数' ,
PRIMARY KEY (`log_time`, `level`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='等级日志'

;

-- ----------------------------
-- Table structure for `log_login`
-- ----------------------------
DROP TABLE IF EXISTS `log_login`;
CREATE TABLE `log_login` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台账户' ,
`level`  smallint(6) NOT NULL COMMENT '等级' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家登陆日志'
AUTO_INCREMENT=10983

;

-- ----------------------------
-- Table structure for `log_online`
-- ----------------------------
DROP TABLE IF EXISTS `log_online`;
CREATE TABLE `log_online` (
`log_time`  int(11) NOT NULL COMMENT '时间戳 ' ,
`num`  smallint(6) NOT NULL DEFAULT 0 COMMENT '当前在线玩家总人数' ,
PRIMARY KEY (`log_time`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='在线人数日志'

;

-- ----------------------------
-- Table structure for `log_pay`
-- ----------------------------
DROP TABLE IF EXISTS `log_pay`;
CREATE TABLE `log_pay` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增id' ,
`pay_num`  varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '充值订单号' ,
`pay_user`  varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '充值用户名' ,
`player_id`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家角色ID' ,
`nickname`  varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '角色名称' ,
`lv`  smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '角色等级' ,
`reg_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '注册时间' ,
`first_pay`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否第一次充值:1-是0-否' ,
`money`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '币货数' ,
`pay_gold`  int(11) NOT NULL DEFAULT 0 COMMENT '游戏币数量' ,
`pay_time`  int(11) NOT NULL DEFAULT 0 COMMENT '来自平台的时间 ' ,
`insert_time`  int(11) NOT NULL DEFAULT 0 COMMENT '插入数据库时间' ,
`pay_status`  smallint(6) NOT NULL DEFAULT 0 COMMENT '支付状态(1:成功;0失败;2:角色不存在)' ,
`state`  smallint(55) NOT NULL DEFAULT 0 COMMENT '奖励系统使用标志(0 未使用，1已使用)' ,
PRIMARY KEY (`id`),
INDEX `player_id` USING BTREE (`player_id`) ,
INDEX `nickname` USING BTREE (`nickname`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家充值记录表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_pet_evolve`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_evolve`;
CREATE TABLE `log_pet_evolve` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_growth_lv`  tinyint(4) NOT NULL COMMENT '原来成长值' ,
`new_growth_lv`  tinyint(4) NOT NULL COMMENT '新的成长值' ,
`old_growth_progress`  smallint(6) NOT NULL COMMENT '原来成长进度' ,
`new_growth_progress`  smallint(6) NOT NULL COMMENT '新的成长进度' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物进化'
AUTO_INCREMENT=3258

;

-- ----------------------------
-- Table structure for `log_pet_upgrade`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_upgrade`;
CREATE TABLE `log_pet_upgrade` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_aptitude_lv`  tinyint(4) NOT NULL COMMENT '原来资质' ,
`new_aptitude_lv`  tinyint(4) NOT NULL COMMENT '新的资质' ,
`old_aptitude_progress`  smallint(6) NOT NULL COMMENT '原来资质进度' ,
`new_aptitude_progress`  smallint(6) NOT NULL COMMENT '新的资质进度' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物提升'
AUTO_INCREMENT=992

;

-- ----------------------------
-- Table structure for `log_pet_upgrade_quality`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_upgrade_quality`;
CREATE TABLE `log_pet_upgrade_quality` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_quality_lv`  tinyint(4) NOT NULL COMMENT '原来品阶' ,
`new_quality_lv`  tinyint(4) NOT NULL COMMENT '新的品阶' ,
`succ_rate`  smallint(6) NOT NULL COMMENT '成功率' ,
`add_rate`  smallint(6) NOT NULL COMMENT '幸运值' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物进阶'
AUTO_INCREMENT=95

;

-- ----------------------------
-- Table structure for `log_player`
-- ----------------------------
DROP TABLE IF EXISTS `log_player`;
CREATE TABLE `log_player` (
`id`  bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT ,
`acid`  int(11) NOT NULL COMMENT '平台Id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '平台账户' ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '昵称' ,
`sex`  tinyint(4) NULL DEFAULT NULL COMMENT '性别' ,
`career`  tinyint(4) NULL DEFAULT NULL COMMENT '职业' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='创建角色'
AUTO_INCREMENT=6288

;

-- ----------------------------
-- Table structure for `log_quit`
-- ----------------------------
DROP TABLE IF EXISTS `log_quit`;
CREATE TABLE `log_quit` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台账户' ,
`time_duration`  int(10) NOT NULL COMMENT '玩家游戏时长' ,
`reason_id`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '退出异常或者原因' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家退出'
AUTO_INCREMENT=10686

;

-- ----------------------------
-- Table structure for `log_real_play`
-- ----------------------------
DROP TABLE IF EXISTS `log_real_play`;
CREATE TABLE `log_real_play` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`pt`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '真正开始游戏的时间' ,
`uid`  int(11) NOT NULL DEFAULT 0 COMMENT '角色ID' ,
PRIMARY KEY (`id`),
INDEX `cp_time` USING BTREE (`pt`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_recharge`
-- ----------------------------
DROP TABLE IF EXISTS `log_recharge`;
CREATE TABLE `log_recharge` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '平台账户' ,
`level`  smallint(6) NOT NULL COMMENT '等级' ,
`type`  tinyint(4) NOT NULL COMMENT '充入渠道' ,
`gold_num`  int(11) NOT NULL COMMENT '充入的金钱' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家充值记录'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_shop`
-- ----------------------------
DROP TABLE IF EXISTS `log_shop`;
CREATE TABLE `log_shop` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账户' ,
`level`  smallint(6) NOT NULL COMMENT '等级' ,
`career`  tinyint(4) NOT NULL COMMENT '职业id' ,
`guild_id`  int(11) NOT NULL DEFAULT 0 COMMENT '帮派id' ,
`money_type`  tinyint(4) NOT NULL COMMENT '货币类型' ,
`amount`  int(11) NOT NULL COMMENT '货币数量' ,
`type`  tinyint(4) NOT NULL COMMENT '物品类型' ,
`sub_type`  tinyint(4) NOT NULL COMMENT '物品子类型' ,
`gtid`  int(11) NOT NULL COMMENT '物品类型id' ,
`number`  int(11) NOT NULL COMMENT '物品数量' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='商城购买日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_stren`
-- ----------------------------
DROP TABLE IF EXISTS `log_stren`;
CREATE TABLE `log_stren` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`gtid`  int(11) NOT NULL COMMENT '装备类型id' ,
`old_stren`  tinyint(11) NOT NULL COMMENT '原强化等级' ,
`old_stren_percent`  tinyint(11) NOT NULL COMMENT '原强化完美度' ,
`new_stren`  tinyint(11) NOT NULL COMMENT '新强化等级' ,
`new_stren_percent`  tinyint(11) UNSIGNED NOT NULL COMMENT '新强化完美度' ,
`coin`  int(11) NOT NULL COMMENT '消耗铜钱' ,
`gold`  int(11) NOT NULL COMMENT '消耗元宝' ,
`cost_goods`  int(11) NOT NULL COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='强化日志表'
AUTO_INCREMENT=163499

;

-- ----------------------------
-- Table structure for `log_task`
-- ----------------------------
DROP TABLE IF EXISTS `log_task`;
CREATE TABLE `log_task` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账户' ,
`career`  tinyint(4) NOT NULL COMMENT '职业id' ,
`guild_id`  int(11) NOT NULL DEFAULT 0 COMMENT '帮派' ,
`task_type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`task_id`  int(11) NOT NULL COMMENT '任务id' ,
`action`  tinyint(4) NOT NULL COMMENT '任务状态' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='任务日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_upgrade`
-- ----------------------------
DROP TABLE IF EXISTS `log_upgrade`;
CREATE TABLE `log_upgrade` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`new_gtid`  int(11) NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='装备升级'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Table structure for `log_wash`
-- ----------------------------
DROP TABLE IF EXISTS `log_wash`;
CREATE TABLE `log_wash` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`old_attri`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`new_attri`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`gold`  int(11) NOT NULL ,
`bgold`  int(11) NOT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='洗练日志'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `audit_gold_cost`
-- ----------------------------
ALTER TABLE `audit_gold_cost` AUTO_INCREMENT=1001;

-- ----------------------------
-- Auto increment value for `audit_gold_stock`
-- ----------------------------
ALTER TABLE `audit_gold_stock` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `audit_goods_cost`
-- ----------------------------
ALTER TABLE `audit_goods_cost` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `audit_goods_output`
-- ----------------------------
ALTER TABLE `audit_goods_output` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `audit_goods_sell`
-- ----------------------------
ALTER TABLE `audit_goods_sell` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `audit_goods_stock`
-- ----------------------------
ALTER TABLE `audit_goods_stock` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_activity`
-- ----------------------------
ALTER TABLE `log_activity` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_add_coin`
-- ----------------------------
ALTER TABLE `log_add_coin` AUTO_INCREMENT=17762;

-- ----------------------------
-- Auto increment value for `log_add_gold`
-- ----------------------------
ALTER TABLE `log_add_gold` AUTO_INCREMENT=342;

-- ----------------------------
-- Auto increment value for `log_add_goods`
-- ----------------------------
ALTER TABLE `log_add_goods` AUTO_INCREMENT=5406;

-- ----------------------------
-- Auto increment value for `log_charge`
-- ----------------------------
ALTER TABLE `log_charge` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_cost_coin`
-- ----------------------------
ALTER TABLE `log_cost_coin` AUTO_INCREMENT=4697;

-- ----------------------------
-- Auto increment value for `log_cost_gold`
-- ----------------------------
ALTER TABLE `log_cost_gold` AUTO_INCREMENT=165;

-- ----------------------------
-- Auto increment value for `log_cost_goods`
-- ----------------------------
ALTER TABLE `log_cost_goods` AUTO_INCREMENT=5043;

-- ----------------------------
-- Auto increment value for `log_dungeon`
-- ----------------------------
ALTER TABLE `log_dungeon` AUTO_INCREMENT=75;

-- ----------------------------
-- Auto increment value for `log_gem`
-- ----------------------------
ALTER TABLE `log_gem` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_gem_compose`
-- ----------------------------
ALTER TABLE `log_gem_compose` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_gilding`
-- ----------------------------
ALTER TABLE `log_gilding` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_godtried`
-- ----------------------------
ALTER TABLE `log_godtried` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_kick_off`
-- ----------------------------
ALTER TABLE `log_kick_off` AUTO_INCREMENT=7721;

-- ----------------------------
-- Auto increment value for `log_login`
-- ----------------------------
ALTER TABLE `log_login` AUTO_INCREMENT=10983;

-- ----------------------------
-- Auto increment value for `log_pay`
-- ----------------------------
ALTER TABLE `log_pay` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_pet_evolve`
-- ----------------------------
ALTER TABLE `log_pet_evolve` AUTO_INCREMENT=3258;

-- ----------------------------
-- Auto increment value for `log_pet_upgrade`
-- ----------------------------
ALTER TABLE `log_pet_upgrade` AUTO_INCREMENT=992;

-- ----------------------------
-- Auto increment value for `log_pet_upgrade_quality`
-- ----------------------------
ALTER TABLE `log_pet_upgrade_quality` AUTO_INCREMENT=95;

-- ----------------------------
-- Auto increment value for `log_player`
-- ----------------------------
ALTER TABLE `log_player` AUTO_INCREMENT=6288;

-- ----------------------------
-- Auto increment value for `log_quit`
-- ----------------------------
ALTER TABLE `log_quit` AUTO_INCREMENT=10686;

-- ----------------------------
-- Auto increment value for `log_real_play`
-- ----------------------------
ALTER TABLE `log_real_play` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_recharge`
-- ----------------------------
ALTER TABLE `log_recharge` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_shop`
-- ----------------------------
ALTER TABLE `log_shop` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_stren`
-- ----------------------------
ALTER TABLE `log_stren` AUTO_INCREMENT=163499;

-- ----------------------------
-- Auto increment value for `log_task`
-- ----------------------------
ALTER TABLE `log_task` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_upgrade`
-- ----------------------------
ALTER TABLE `log_upgrade` AUTO_INCREMENT=1;

-- ----------------------------
-- Auto increment value for `log_wash`
-- ----------------------------
ALTER TABLE `log_wash` AUTO_INCREMENT=1;
