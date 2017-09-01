-- ----------------------------
-- Table structure for `temp_pet_growth`
-- ----------------------------
DROP TABLE IF EXISTS `temp_pet_growth`;
CREATE TABLE `temp_pet_growth` (
`growth_lv`  int(10) NOT NULL COMMENT '成长等级' ,
`cost_goods`  int(10) NOT NULL COMMENT '消耗成长丹id' ,
`cost_coin`  int(10) NOT NULL COMMENT '消耗的铜钱' ,
`growth_total`  int(10) NOT NULL COMMENT '成长值进度条总长' ,
`add_attri`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '增加的属性' ,
`extra_attri`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '额外增加属性值' ,
`add_holes`  int(10) NOT NULL COMMENT '技能槽增加数' ,
PRIMARY KEY (`growth_lv`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物成长模版'

;