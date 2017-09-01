-- ----------------------------
-- Table structure for `dungeon_master`
-- ----------------------------
DROP TABLE IF EXISTS `dungeon_master`;
CREATE TABLE `dungeon_master` (
`sid`  int(10) NOT NULL DEFAULT 0 COMMENT '副本ID' ,
`gid`  int(10) NOT NULL DEFAULT 0 COMMENT '副本组ID' ,
`muid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '副本霸主UID' ,
`score`  int(10) NOT NULL DEFAULT 0 COMMENT '副本霸主积分' ,
`update_time`  int(10) NULL DEFAULT 0 COMMENT '副本修改时间。' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '霸主名字' ,
PRIMARY KEY (`sid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;