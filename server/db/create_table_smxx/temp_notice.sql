-- ----------------------------
-- Table structure for `temp_notice`
-- ----------------------------
DROP TABLE IF EXISTS `temp_notice`;
CREATE TABLE `temp_notice` (
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '消息ID' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 - 提示语，发给单个人的。\r\n1 - 1级公告，会在跑马灯出现。\r\n2 - 2级公告，会在系统公告频道出现，红字。\r\n3 - 3级公告，会在系统频道出现，普通字。' ,
`content`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '\"\"' COMMENT '消息内容' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='通知消息'

;