-- ----------------------------
-- Table structure for `config_logout_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_logout_type`;
CREATE TABLE `config_logout_type` (
`id`  tinyint(4) NOT NULL ,
`reason`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='退出异常或者原因'

;