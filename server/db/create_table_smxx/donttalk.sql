-- ----------------------------
-- Table structure for `donttalk`
-- ----------------------------
DROP TABLE IF EXISTS `donttalk`;
CREATE TABLE `donttalk` (
`uid`  bigint(20) UNSIGNED NOT NULL COMMENT '角色ID' ,
`start_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '开始禁言时间(秒)' ,
`duration`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '持续时间(秒)' ,
`reason`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '无理' COMMENT '理由说明' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='角色禁言表'

;