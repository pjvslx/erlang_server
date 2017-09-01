-- ----------------------------
-- Table structure for `temp_compose`
-- ----------------------------
DROP TABLE IF EXISTS `temp_compose`;
CREATE TABLE `temp_compose` (
`target_gtid`  int(10) NOT NULL COMMENT '目标物品类型id' ,
`gtid`  int(10) NOT NULL COMMENT '源材料物品类型id' ,
`goods_num`  int(10) NOT NULL COMMENT '消耗材料数量' ,
`cost_coin`  int(10) NOT NULL COMMENT '消耗铜钱数量' ,
PRIMARY KEY (`target_gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;