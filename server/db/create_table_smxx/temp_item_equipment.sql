-- ----------------------------
-- Table structure for `temp_item_equipment`
-- ----------------------------
DROP TABLE IF EXISTS `temp_item_equipment`;
CREATE TABLE `temp_item_equipment` (
`gtid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型编号' ,
`appearance`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '装备外观' ,
`set_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '套装编号' ,
`max_stren`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '最大强化等级' ,
`equip_attr`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '装备属性' ,
`stren_change`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '强化后换装' ,
`holes`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '默认孔数' ,
`max_holes`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '镶嵌孔上限' ,
`max_gilding`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '镀金上限' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='装备物品'

;