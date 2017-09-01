-- ----------------------------
-- Table structure for `config_money_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_money_type`;
CREATE TABLE `config_money_type` (
`id`  int(10) NOT NULL DEFAULT 0 ,
`money_type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='货币来源和消耗类型'

;