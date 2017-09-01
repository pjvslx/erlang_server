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