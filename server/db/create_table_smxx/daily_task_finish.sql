-- ----------------------------
-- Table structure for `daily_task_finish`
-- ----------------------------
DROP TABLE IF EXISTS `daily_task_finish`;
CREATE TABLE `daily_task_finish` (
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`state`  tinyint(2) NOT NULL COMMENT '任务状态' ,
`count_detail`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '本日可用轮数{可用轮数，已用轮数}' ,
`cycle_datil`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '每轮可用次数 {可触发次数,已触发次数}' ,
`trigger_detail`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '每次触发任务数{每次可同时触发任务数,已触发任务数}' ,
`reset_time`  int(17) NOT NULL DEFAULT 0 COMMENT '上次重置时间' ,
`total`  int(20) NOT NULL COMMENT '总完成次数' ,
`trigger_time`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '触发时间' ,
PRIMARY KEY (`uid`, `type`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;