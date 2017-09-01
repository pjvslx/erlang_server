-- ----------------------------
-- Table structure for `config_task_type`
-- ----------------------------
DROP TABLE IF EXISTS `config_task_type`;
CREATE TABLE `config_task_type` (
`id`  int(10) NOT NULL DEFAULT 0 ,
`task_type`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='任务类型配置表'

;