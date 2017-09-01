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