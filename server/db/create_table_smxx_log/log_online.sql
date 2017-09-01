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