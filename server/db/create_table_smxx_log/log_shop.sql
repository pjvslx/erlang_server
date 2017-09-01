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