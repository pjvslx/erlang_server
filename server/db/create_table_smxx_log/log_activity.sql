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