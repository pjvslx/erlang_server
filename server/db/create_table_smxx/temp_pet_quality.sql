-- ----------------------------
-- Table structure for `temp_pet_quality`
-- ----------------------------
DROP TABLE IF EXISTS `temp_pet_quality`;
CREATE TABLE `temp_pet_quality` (
`quality_lv`  int(10) NOT NULL DEFAULT 0 COMMENT '品阶级' ,
`color`  int(10) NOT NULL DEFAULT 0 COMMENT '宠物名称颜色编号' ,
`facade`  int(10) NOT NULL DEFAULT 0 COMMENT '宠物外观编号' ,
`cost_goods`  int(10) NOT NULL DEFAULT 0 COMMENT '进阶消耗进阶丹id' ,
`cost_coin`  int(10) NOT NULL DEFAULT 0 COMMENT '消耗铜钱数目' ,
`succ_rate`  int(10) NOT NULL DEFAULT 0 COMMENT '成功率' ,
`add_rate`  int(10) NOT NULL DEFAULT 0 COMMENT '进阶失败基础成功率增加值' ,
`growth_limit`  int(10) NOT NULL DEFAULT 0 COMMENT '成长值等级上限' ,
`aptitude_limit`  int(10) NOT NULL DEFAULT 0 COMMENT '资质值等级上限' ,
`add_attri`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '宠物属性加成[{attcak, 10}, {}]' ,
PRIMARY KEY (`quality_lv`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物品级模版表'

;