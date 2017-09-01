-- ----------------------------
-- Table structure for `temp_level_bag`
-- ----------------------------
DROP TABLE IF EXISTS `temp_level_bag`;
CREATE TABLE `temp_level_bag` (
`level`  int(10) NOT NULL DEFAULT 0 ,
`cell_num`  int(10) NULL DEFAULT NULL ,
PRIMARY KEY (`level`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='等级扩展背包'

;