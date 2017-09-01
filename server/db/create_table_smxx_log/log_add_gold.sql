-- ----------------------------
-- Table structure for `log_add_gold`
-- ----------------------------
DROP TABLE IF EXISTS `log_add_gold`;
CREATE TABLE `log_add_gold` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '角色id' ,
`num`  int(11) NOT NULL DEFAULT 0 COMMENT '数量' ,
`type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '0绑定元宝,1元宝' ,
`source`  int(11) NOT NULL DEFAULT 0 COMMENT '来源' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='发放元宝和绑定元宝日志'
AUTO_INCREMENT=342

;