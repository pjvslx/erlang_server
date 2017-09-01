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