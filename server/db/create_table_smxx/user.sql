-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
`account_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号id' ,
`account_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账号' ,
`state`  smallint(5) NOT NULL DEFAULT 0 COMMENT '账号状态(0正常；1被封)' ,
`id_card_state`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '身份证验证状态，0表示没填身份证信息，1表示成年人，2表示未成年人，3表示暂时未填身份证信息' ,
PRIMARY KEY (`account_id`),
INDEX `account_name` USING BTREE (`account_name`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='平台账号'

;