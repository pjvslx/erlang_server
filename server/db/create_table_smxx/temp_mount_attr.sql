-- ----------------------------
-- Table structure for `temp_mount_attr`
-- ----------------------------
DROP TABLE IF EXISTS `temp_mount_attr`;
CREATE TABLE `temp_mount_attr` (
`level`  int(11) NOT NULL DEFAULT 0 COMMENT '座骑阶级' ,
`star`  int(11) NOT NULL DEFAULT 0 COMMENT '星级' ,
`star_exp`  int(11) NOT NULL COMMENT '坐骑在该星级，升到下一星所需要的进度值总长' ,
`star_gid`  int(11) NOT NULL COMMENT '在该星级升级所需要的进星丹id' ,
`mount_model`  int(11) NULL DEFAULT NULL ,
`speed`  int(11) NOT NULL DEFAULT 0 COMMENT '坐骑给主人提供的速度增加值。为具体增加的值，不是万分比。' ,
`data`  varchar(10240) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '属性列表[{Key, Value},...]' ,
PRIMARY KEY (`level`, `star`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;