-- ----------------------------
-- Table structure for `temp_suit_reward`
-- ----------------------------
DROP TABLE IF EXISTS `temp_suit_reward`;
CREATE TABLE `temp_suit_reward` (
`suit_id`  int(10) NOT NULL COMMENT '套装id' ,
`num`  int(10) NOT NULL COMMENT '套装件数' ,
`add_value`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '属性加成' ,
PRIMARY KEY (`suit_id`, `num`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='套装装备加成'

;