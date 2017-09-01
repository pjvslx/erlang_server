-- ----------------------------
-- Table structure for `temp_gold_bag`
-- ----------------------------
DROP TABLE IF EXISTS `temp_gold_bag`;
CREATE TABLE `temp_gold_bag` (
`cell_num`  int(10) NOT NULL DEFAULT 0 ,
`gold_num`  int(10) NOT NULL DEFAULT 0 ,
PRIMARY KEY (`cell_num`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='元宝开启格子数'

;