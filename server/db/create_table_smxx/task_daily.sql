-- ----------------------------
-- Table structure for `task_daily`
-- ----------------------------
DROP TABLE IF EXISTS `task_daily`;
CREATE TABLE `task_daily` (
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家id' ,
`type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '任务类型' ,
`state`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态' ,
`used_trigger_count`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '已使用轮数' ,
`used_cycle_count`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '当前这一轮， 已使用的次数' ,
`trigger_count`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '已接日常任务数量' ,
`reset_time`  int(17) NOT NULL DEFAULT 0 COMMENT '上次重置时间' ,
`total`  int(17) NOT NULL DEFAULT 0 COMMENT '总的完成次数' ,
`trigger_time`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '触发时间' 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='日常任务统计表'

;