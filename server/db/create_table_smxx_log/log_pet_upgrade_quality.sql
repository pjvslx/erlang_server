-- ----------------------------
-- Table structure for `log_pet_upgrade_quality`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_upgrade_quality`;
CREATE TABLE `log_pet_upgrade_quality` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_quality_lv`  tinyint(4) NOT NULL COMMENT '原来品阶' ,
`new_quality_lv`  tinyint(4) NOT NULL COMMENT '新的品阶' ,
`succ_rate`  smallint(6) NOT NULL COMMENT '成功率' ,
`add_rate`  smallint(6) NOT NULL COMMENT '幸运值' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物进阶'
AUTO_INCREMENT=95

;