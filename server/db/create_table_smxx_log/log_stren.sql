-- ----------------------------
-- Table structure for `log_stren`
-- ----------------------------
DROP TABLE IF EXISTS `log_stren`;
CREATE TABLE `log_stren` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`gtid`  int(11) NOT NULL COMMENT '装备类型id' ,
`old_stren`  tinyint(11) NOT NULL COMMENT '原强化等级' ,
`old_stren_percent`  tinyint(11) NOT NULL COMMENT '原强化完美度' ,
`new_stren`  tinyint(11) NOT NULL COMMENT '新强化等级' ,
`new_stren_percent`  tinyint(11) UNSIGNED NOT NULL COMMENT '新强化完美度' ,
`coin`  int(11) NOT NULL COMMENT '消耗铜钱' ,
`gold`  int(11) NOT NULL COMMENT '消耗元宝' ,
`cost_goods`  int(11) NOT NULL COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='强化日志表'
AUTO_INCREMENT=163499

;