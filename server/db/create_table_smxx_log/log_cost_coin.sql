-- ----------------------------
-- Table structure for `log_cost_coin`
-- ----------------------------
DROP TABLE IF EXISTS `log_cost_coin`;
CREATE TABLE `log_cost_coin` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`coin`  int(11) NOT NULL DEFAULT 0 COMMENT '铜钱' ,
`bcoin`  int(11) NOT NULL DEFAULT 0 COMMENT '绑定铜钱' ,
`cost_type`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗类型' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='铜钱消耗日志'
AUTO_INCREMENT=4697

;