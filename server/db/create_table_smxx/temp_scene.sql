-- ----------------------------
-- Table structure for `temp_scene`
-- ----------------------------
DROP TABLE IF EXISTS `temp_scene`;
CREATE TABLE `temp_scene` (
`sid`  int(11) NOT NULL COMMENT '场景id' ,
`name`  char(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '场景名称' ,
`icon`  char(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '场景资源编号' ,
`mode`  smallint(1) NOT NULL DEFAULT 0 COMMENT '地图模式：\r\n默认为1 \r\n1-新手村 \r\n2-野外 \r\n3-主城 \r\n4-副本 \r\n5-跨服副本 ' ,
`type`  smallint(5) NOT NULL DEFAULT 1 COMMENT '地图类型：多种类型可以共存\r\n0-表示都不可以\r\n1-可以PK\r\n2-可以原地复活\r\n4-可以吃瞬加药\r\n8-可以使用小飞鞋传送' ,
`pk_mode`  tinyint(1) NOT NULL DEFAULT 1 COMMENT '0-不强制pk模式\r\n1-强制和平模式\r\n2-强制自由pk模式\r\n3-强制帮会pk模式' ,
`min_level`  smallint(5) NOT NULL DEFAULT 0 COMMENT '进入该地图的最下玩家等级' ,
`max_level`  smallint(5) NOT NULL DEFAULT 0 COMMENT '进入该地图的最大玩家等级' ,
`x`  int(11) NOT NULL DEFAULT 0 COMMENT '进入后默认x坐标' ,
`y`  int(11) NOT NULL DEFAULT 0 COMMENT '进入后默认y坐标' ,
`poem`  char(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '进入诗词' ,
`loading`  int(11) NOT NULL DEFAULT 0 COMMENT '调用Loading图' ,
`revive_sid`  int(11) NOT NULL DEFAULT 0 COMMENT '复活场景' ,
`revive_x`  int(11) NOT NULL DEFAULT 0 COMMENT '复活X坐标' ,
`revive_y`  int(11) NOT NULL DEFAULT 0 COMMENT '复活Y坐标' ,
`size`  smallint(5) NOT NULL DEFAULT 10000 COMMENT '万分比。填写10000则为不缩放。此处缩放比例只对场景中的玩家角色有效（包括宠物、站骑等）' ,
`npc`  char(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT 'NPC' ,
`scene_num`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '该基础场景的进程数' ,
`id`  int(11) NOT NULL DEFAULT 0 COMMENT '场景实例唯一标识' ,
PRIMARY KEY (`sid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='场景数据结构\r\n1、基础'

;