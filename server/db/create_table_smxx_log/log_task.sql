-- ----------------------------
-- Table structure for `log_task`
-- ----------------------------
DROP TABLE IF EXISTS `log_task`;
CREATE TABLE `log_task` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '角色id' ,
`acnm`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '平台账户' ,
`career`  tinyint(4) NOT NULL COMMENT '职业id' ,
`guild_id`  int(11) NOT NULL DEFAULT 0 COMMENT '帮派' ,
`task_type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`task_id`  int(11) NOT NULL COMMENT '任务id' ,
`action`  tinyint(4) NOT NULL COMMENT '任务状态' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '时间戳' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='任务日志'
AUTO_INCREMENT=1

;