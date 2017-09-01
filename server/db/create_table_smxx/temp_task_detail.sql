-- ----------------------------
-- Table structure for `temp_task_detail`
-- ----------------------------
DROP TABLE IF EXISTS `temp_task_detail`;
CREATE TABLE `temp_task_detail` (
`task_type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`can_cyc`  tinyint(1) NOT NULL COMMENT '是否支持循环 0:不支持 1:支持' ,
`trigger_time`  tinyint(4) NOT NULL COMMENT '可触发轮数' ,
`cycle_time`  tinyint(4) NOT NULL COMMENT '每轮可触发次数' ,
`meanw_trigger`  tinyint(4) NOT NULL COMMENT '每次可同时触发任务数' ,
`time_limit`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '时间段限制[{开始时间，结束时间}...]' ,
`reset_time`  varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '重置时间' ,
`coin`  int(7) NOT NULL DEFAULT 0 COMMENT '自动完成任务所需的元宝' ,
PRIMARY KEY (`task_type`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;