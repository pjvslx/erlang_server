-- ----------------------------
-- Table structure for `sys_announce`
-- ----------------------------
DROP TABLE IF EXISTS `sys_announce`;
CREATE TABLE `sys_announce` (
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '消息ID' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '公告类型：\r\n1 - 1级公告，会在跑马灯出现。\r\n2 - 2级公告，会在系统公告频道出现，红字。\r\n3 - 3级公告，会在系统频道出现，普通字。' ,
`begin_time`  int(11) NOT NULL DEFAULT 0 COMMENT '公告开始时间（unixtime格式、0为立即开始）' ,
`end_time`  int(11) NOT NULL DEFAULT 0 COMMENT '系统公告停止时间（unixtime格式、0则永不停止）' ,
`interval`  int(4) NOT NULL DEFAULT 0 COMMENT '公告发送时间间隔，单位分钟，0为不发送。' ,
`next_time`  int(11) NOT NULL DEFAULT 0 COMMENT '下次发送时间（untime格式、0为尚未发送）' ,
`times`  int(4) NOT NULL DEFAULT 0 COMMENT '发送次数（0为不限次数）' ,
`content`  int(11) NOT NULL DEFAULT 0 COMMENT '公告内容来自 temp_tips.id' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;