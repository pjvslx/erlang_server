-- ----------------------------
-- Table structure for `temp_drop_sub`
-- ----------------------------
DROP TABLE IF EXISTS `temp_drop_sub`;
CREATE TABLE `temp_drop_sub` (
`sid`  int(10) NOT NULL ,
`dropitem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' ,
PRIMARY KEY (`sid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='µôÂäÊµÀýÃ÷Ï¸'

;