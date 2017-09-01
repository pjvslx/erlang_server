-- ----------------------------
-- Table structure for `log_pet_evolve`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_evolve`;
CREATE TABLE `log_pet_evolve` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_growth_lv`  tinyint(4) NOT NULL COMMENT '原来成长值' ,
`new_growth_lv`  tinyint(4) NOT NULL COMMENT '新的成长值' ,
`old_growth_progress`  smallint(6) NOT NULL COMMENT '原来成长进度' ,
`new_growth_progress`  smallint(6) NOT NULL COMMENT '新的成长进度' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物进化'
AUTO_INCREMENT=3258

;