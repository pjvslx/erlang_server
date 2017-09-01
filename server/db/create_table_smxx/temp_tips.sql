-- ----------------------------
-- Table structure for `temp_tips`
-- ----------------------------
DROP TABLE IF EXISTS `temp_tips`;
CREATE TABLE `temp_tips` (
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '消息ID' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 - 提示语，发给单个人的。\r\n1 - 屏幕中央向上翻滚。\r\n2 - 聊天区\r\n3 - 1+2' ,
`color`  smallint(2) NULL DEFAULT 0 COMMENT '1 - 白\r\n2 - 绿\r\n3 - 蓝\r\n4 - 紫\r\n5 - 橙\r\n6 - 红' ,
`content`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '\"\"' COMMENT '消息内容' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;