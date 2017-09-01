-- ----------------------------
-- Table structure for `temp_meridian`
-- ----------------------------
DROP TABLE IF EXISTS `temp_meridian`;
CREATE TABLE `temp_meridian` (
`mer_id`  int(10) NOT NULL COMMENT '经脉id' ,
`mer_type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '经脉类型(1-督脉，2-任脉，3-冲脉，4-带脉，5-阴维，6-阳维，7-阴跷，8-阳跷)' ,
`mer_lv`  int(7) NOT NULL COMMENT '经脉等级(1~100)' ,
`cd_type`  tinyint(2) NOT NULL COMMENT '是否有cd(1有 2无)' ,
`mer_name`  varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '经脉名称' ,
`mer_detail`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '经脉详细[{职业类别,属性类型,属性值}...]' ,
`next_mer_id`  int(10) NOT NULL COMMENT '下一级经脉(-1为无下一级)' ,
`cd`  int(16) NOT NULL DEFAULT 0 COMMENT '冷却时间' ,
`cost_money`  int(10) NOT NULL COMMENT '升级需要的金钱花费' ,
`cost_Empowerment`  int(10) NOT NULL COMMENT '升级需要的历练消费' ,
PRIMARY KEY (`mer_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;