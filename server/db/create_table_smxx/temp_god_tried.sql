-- ----------------------------
-- Table structure for `temp_god_tried`
-- ----------------------------
DROP TABLE IF EXISTS `temp_god_tried`;
CREATE TABLE `temp_god_tried` (
`target_tid`  int(10) NOT NULL DEFAULT 0 COMMENT '神炼宝石' ,
`stone_tid`  int(10) NULL DEFAULT NULL COMMENT '宝石' ,
`god_stone_tid`  int(10) NULL DEFAULT NULL COMMENT '神炼石' ,
`cost_coin`  int(10) NULL DEFAULT NULL COMMENT '消耗铜钱' ,
PRIMARY KEY (`target_tid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='神炼模版表'

;