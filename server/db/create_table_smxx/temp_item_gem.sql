-- ----------------------------
-- Table structure for `temp_item_gem`
-- ----------------------------
DROP TABLE IF EXISTS `temp_item_gem`;
CREATE TABLE `temp_item_gem` (
`gtid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品ID' ,
`coin_num`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`attri_add`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '属性加成' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宝石属性'

;