-- ----------------------------
-- Table structure for `temp_pet_aptitude`
-- ----------------------------
DROP TABLE IF EXISTS `temp_pet_aptitude`;
CREATE TABLE `temp_pet_aptitude` (
`aptitude_lv`  int(10) NOT NULL COMMENT '资质等级' ,
`cost_goods`  int(10) NOT NULL COMMENT '消耗丹药id' ,
`cost_coin`  int(10) NOT NULL COMMENT '消耗的铜钱' ,
`growth_total`  int(10) NOT NULL COMMENT '成长值进度条总长' ,
`add_attri`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '增加的属性' ,
`extra_attri`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '额外增加属性值' ,
`add_holes`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '增加技能槽' ,
PRIMARY KEY (`aptitude_lv`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物资质模版'

;