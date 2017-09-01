-- ----------------------------
-- Table structure for `temp_task_factor`
-- ----------------------------
DROP TABLE IF EXISTS `temp_task_factor`;
CREATE TABLE `temp_task_factor` (
`task_type`  tinyint(4) NOT NULL COMMENT '任务类型' ,
`grade`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '任务品质' ,
`fact1`  float NOT NULL DEFAULT 0 COMMENT '影响因子1' ,
`fact2`  float NOT NULL DEFAULT 0 COMMENT '影响因子2' ,
`fact3`  float NOT NULL DEFAULT 0 COMMENT '影响因子3' ,
`fact4`  float NOT NULL DEFAULT 0 COMMENT '影响因子3' ,
`task_id_span`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '任务id区间 {minId, maxId}' ,
`level_span`  tinyint(5) NOT NULL DEFAULT 0 COMMENT 'level区间' ,
PRIMARY KEY (`task_type`, `grade`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='日常任务等级影响因子'

;