-- ----------------------------
-- Table structure for `dungeon_daily`
-- ----------------------------
DROP TABLE IF EXISTS `dungeon_daily`;
CREATE TABLE `dungeon_daily` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号ID' ,
`sid`  int(10) NULL DEFAULT 0 COMMENT '正在进行的副本ID' ,
`times`  int(10) NULL DEFAULT 0 COMMENT '当前副本组通关次数' ,
`begin_time`  int(11) NULL DEFAULT 0 COMMENT '副本开始的时间' ,
`last_time`  int(11) NULL DEFAULT 0 COMMENT '最后一次在副本里活动的时间' ,
`triggers`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '触发器[]' ,
`pre_sid`  int(11) NULL DEFAULT 0 COMMENT '进入副本前的场景ID' ,
`pre_sx`  int(11) NULL DEFAULT 0 COMMENT '场景中的X' ,
`pre_sy`  int(11) NULL DEFAULT 0 ,
`pass_assess`  int(4) NULL DEFAULT 0 COMMENT '通关评价' ,
`pass_type`  int(11) NULL DEFAULT 0 COMMENT 'pass_type' ,
`pass_value`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' ,
`rewards`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '副本奖励' ,
`monsters`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '副本怪物' ,
`dungeon_score`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '副本评分' ,
`dialogue`  varchar(3000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '副本剧情' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;