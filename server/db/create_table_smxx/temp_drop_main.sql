-- ----------------------------
-- Table structure for `temp_drop_main`
-- ----------------------------
DROP TABLE IF EXISTS `temp_drop_main`;
CREATE TABLE `temp_drop_main` (
`did`  int(10) NOT NULL ,
`dropitem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT 'Ëæ»úµôÂäÊµÀýID' ,
PRIMARY KEY (`did`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='ÅäÖÃµôÂäÊµÀý'

;