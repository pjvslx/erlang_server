-- ----------------------------
-- Table structure for `temp_mount_skill`
-- ----------------------------
DROP TABLE IF EXISTS `temp_mount_skill`;
CREATE TABLE `temp_mount_skill` (
`sid`  smallint(11) NOT NULL DEFAULT 0 COMMENT '技能ID' ,
`level`  int(11) NOT NULL DEFAULT 0 COMMENT '技能等级' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '技能名字' COMMENT '阶级名' ,
`data`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '属性列表[{Key, Value},...]' ,
`icon`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' ,
`player_level`  int(11) NOT NULL DEFAULT 0 ,
PRIMARY KEY (`sid`, `level`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;