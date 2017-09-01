-- ----------------------------
-- Table structure for `log_dungeon`
-- ----------------------------
DROP TABLE IF EXISTS `log_dungeon`;
CREATE TABLE `log_dungeon` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '用户ID' ,
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号ID' ,
`sid`  int(11) NOT NULL COMMENT '平台账号' ,
`enter_time`  int(11) NOT NULL COMMENT '进入副本时间' ,
`end_time`  int(11) NOT NULL COMMENT '进入副本时间' ,
`left_times`  int(5) NOT NULL DEFAULT 0 COMMENT '剩余次数' ,
`assess`  int(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '通关评价' ,
`rewards`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '获得奖品' ,
`reward_time`  int(11) NULL DEFAULT 0 COMMENT '领取奖励时间' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `idx_uidbg` USING BTREE (`uid`, `enter_time`) ,
INDEX `idx_uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家当前的副本信息'
AUTO_INCREMENT=75

;