-- ----------------------------
-- Table structure for `infant_ctrl_byuser`
-- ----------------------------
DROP TABLE IF EXISTS `infant_ctrl_byuser`;
CREATE TABLE `infant_ctrl_byuser` (
`account_id`  int(11) NOT NULL DEFAULT 0 COMMENT '平台ID' ,
`total_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '防沉迷累计登陆时间(unix time)' ,
`last_login_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '上次登陆时间(unix time)' ,
PRIMARY KEY (`account_id`),
INDEX `accid` USING BTREE (`account_id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;