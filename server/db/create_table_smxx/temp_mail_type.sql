-- ----------------------------
-- Table structure for `temp_mail_type`
-- ----------------------------
DROP TABLE IF EXISTS `temp_mail_type`;
CREATE TABLE `temp_mail_type` (
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '类型(0系统)' ,
`name`  char(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '\"这不是一个邮件\"' COMMENT '邮件类型名（发送名)' ,
PRIMARY KEY (`type`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='信件信息'

;