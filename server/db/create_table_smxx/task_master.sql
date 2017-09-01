-- ----------------------------
-- Table structure for `task_master`
-- ----------------------------
DROP TABLE IF EXISTS `task_master`;
CREATE TABLE `task_master` (
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`master_task`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '师门令任务, 格式[{tid, grade, state},{tid, grade, state},{tid, grade, state}]' ,
`refresh_time`  int(11) NOT NULL DEFAULT 0 COMMENT '刷新时间' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家师门令，刷新列表'

;