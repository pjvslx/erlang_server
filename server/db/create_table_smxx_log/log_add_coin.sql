-- ----------------------------
-- Table structure for `log_add_coin`
-- ----------------------------
DROP TABLE IF EXISTS `log_add_coin`;
CREATE TABLE `log_add_coin` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`num`  int(11) NOT NULL DEFAULT 0 COMMENT '数量' ,
`type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '0绑定铜钱,1铜钱' ,
`source`  int(11) NOT NULL DEFAULT 0 COMMENT '来源' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='发放铜钱和绑定铜钱日志'
AUTO_INCREMENT=17762

;