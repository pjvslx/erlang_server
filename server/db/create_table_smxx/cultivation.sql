-- ----------------------------
-- Table structure for `cultivation`
-- ----------------------------
DROP TABLE IF EXISTS `cultivation`;
CREATE TABLE `cultivation` (
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`lv`  tinyint(4) NOT NULL COMMENT '修为等级' ,
`property`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '修为属性[{属性类型,属性值}..]' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;