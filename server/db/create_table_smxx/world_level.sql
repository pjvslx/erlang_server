-- ----------------------------
-- Table structure for `world_level`
-- ----------------------------
DROP TABLE IF EXISTS `world_level`;
CREATE TABLE `world_level` (
`sid`  int(11) NOT NULL DEFAULT 0 COMMENT '服务器编号' ,
`state`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '世界等级开放状态0未开放，1开放' ,
`world_level`  smallint(6) NOT NULL DEFAULT 0 COMMENT '实际的世界等级' ,
`timestamp`  int(11) NOT NULL DEFAULT 0 COMMENT '开启时间点' ,
PRIMARY KEY (`sid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;