-- ----------------------------
-- Table structure for `task_process`
-- ----------------------------
DROP TABLE IF EXISTS `task_process`;
CREATE TABLE `task_process` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`tid`  int(11) NOT NULL COMMENT '任务模板id' ,
`state`  tinyint(2) NOT NULL COMMENT '任务状态,0:新任务， 1:完成未提交' ,
`trigger_time`  int(17) NOT NULL COMMENT '触发时间' ,
`type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`mark`  varchar(60) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '任务进度' ,
`grade`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '任务品质' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=2935

;

-- ----------------------------
-- Auto increment value for `task_process`
-- ----------------------------
ALTER TABLE `task_process` AUTO_INCREMENT=2935;