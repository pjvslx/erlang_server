-- ----------------------------
-- Table structure for `ban_account_list`
-- ----------------------------
DROP TABLE IF EXISTS `ban_account_list`;
CREATE TABLE `ban_account_list` (
`uid`  bigint(20) NOT NULL COMMENT '角色ID' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '角色名' ,
`account_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '账号' ,
`end_time`  int(10) NOT NULL COMMENT '封禁结束时间' ,
`operator`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '操作员' ,
`ban_reason`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '封禁原因' ,
`op_time`  int(11) NOT NULL ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='已封禁帐号列表'

;