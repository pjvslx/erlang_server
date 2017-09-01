-- ----------------------------
-- Table structure for `player`
-- ----------------------------
DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
`id`  bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID' ,
`account_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号ID' ,
`account_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账号' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '玩家名' ,
`type`  smallint(5) NOT NULL DEFAULT 1 COMMENT '玩家身份 1- 普通玩家 2 - 指导员 3 - gm' ,
`icon`  int(11) NOT NULL DEFAULT 0 COMMENT '玩家头像ID' ,
`reg_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '注册时间' ,
`logout_time`  int(11) NOT NULL DEFAULT 0 COMMENT '上次离线时间' ,
`last_login_time`  int(11) NOT NULL DEFAULT 0 COMMENT '最后登陆时间' ,
`last_login_ip`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '最后登陆IP' ,
`status`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家状态（0正常、1禁止、2战斗中、3死亡、4挂机、5打坐）' ,
`gender`  tinyint(1) UNSIGNED NOT NULL DEFAULT 1 COMMENT '性别 1男 2女' ,
`career`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '职业(0:未定义，1: 神 2:魔 3:妖)' ,
`gold`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '元宝' ,
`bgold`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定元宝' ,
`coin`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '铜钱' ,
`bcoin`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定铜钱' ,
`vip`  int(11) NOT NULL DEFAULT 0 COMMENT 'VIP类型，0不是VIP，其他参考common.hrl' ,
`vip_expire_time`  int(11) NOT NULL DEFAULT 0 COMMENT 'VIP过期时间(秒)' ,
`scene`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '场景ID' ,
`cell_num`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '背包格子数' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 1 COMMENT '等级' ,
`exp`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '经验' ,
`online_flag`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '在线标记，0不在线 1在线' ,
`resolut_x`  int(8) NOT NULL DEFAULT 0 COMMENT '分辨率 X' ,
`resolut_y`  int(8) NOT NULL DEFAULT 0 COMMENT '分辨率 Y' ,
`liveness`  int(11) NOT NULL DEFAULT 0 COMMENT '活跃度' ,
`camp`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '阵营(国籍)' ,
`lilian`  int(11) NOT NULL DEFAULT 0 COMMENT '历练值' ,
`switch`  int(11) NOT NULL DEFAULT 0 COMMENT '状态开关码1:功能开 0:功能关，位定义参考common.hrl' ,
`guild_id`  int(11) NOT NULL DEFAULT 0 COMMENT '派帮ID(无帮派:0)' ,
`guild_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '帮派名称' ,
`guild_post`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '帮派职位(0为小兵)' ,
`force`  int(11) NOT NULL DEFAULT 0 COMMENT '战斗力' ,
`battle_attr`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '战斗结构体' ,
`other`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '其他信息' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `nick` USING BTREE (`nick`) ,
INDEX `level` USING BTREE (`level`) ,
INDEX `account_name` USING BTREE (`account_name`) ,
INDEX `last_login_time` USING BTREE (`last_login_time`) ,
INDEX `reg_time` USING BTREE (`reg_time`) ,
INDEX `account_id` USING BTREE (`account_id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='角色基本信息'
AUTO_INCREMENT=530000000326

;

-- ----------------------------
-- Auto increment value for `player`
-- ----------------------------
ALTER TABLE `player` AUTO_INCREMENT=1719022918;