-- ----------------------------
-- Table structure for `temp_goods_facade`
-- ----------------------------
DROP TABLE IF EXISTS `temp_goods_facade`;
CREATE TABLE `temp_goods_facade` (
`gtid`  int(11) NOT NULL COMMENT '物品类型id' ,
`facade`  int(11) NOT NULL COMMENT '外观id' ,
`facade_res`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '外观对应资源' ,
`frame`  int(11) NOT NULL COMMENT '帧数' ,
`frame_speed`  int(11) NOT NULL COMMENT '帧速' ,
`icon`  char(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '头像' ,
`expire_time`  int(11) NOT NULL COMMENT '0外观过期时间' ,
`name`  char(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '外观名称' ,
PRIMARY KEY (`gtid`, `facade`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='幻化卡和资源对应关系模版表'

;