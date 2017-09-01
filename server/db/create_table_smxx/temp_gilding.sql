-- ----------------------------
-- Table structure for `temp_gilding`
-- ----------------------------
DROP TABLE IF EXISTS `temp_gilding`;
CREATE TABLE `temp_gilding` (
`gilding_lv`  int(10) NOT NULL COMMENT '镀金等级' ,
`equip_subtype`  int(10) NOT NULL COMMENT '镀金等级' ,
`add_value`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '附加属性' ,
`goods`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '消耗物品' ,
`cost_coin`  int(10) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
PRIMARY KEY (`gilding_lv`, `equip_subtype`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='镀金配置表'

;