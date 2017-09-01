-- ----------------------------
-- Table structure for `log_cost_gold`
-- ----------------------------
DROP TABLE IF EXISTS `log_cost_gold`;
CREATE TABLE `log_cost_gold` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`gold`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`bgold`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗绑定元宝' ,
`cost_type`  int(11) NOT NULL DEFAULT 0 COMMENT '消费类型' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `create_time` USING BTREE (`create_time`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='元宝消耗日志'
AUTO_INCREMENT=165

;