-- ----------------------------
-- Table structure for `log_pet_upgrade`
-- ----------------------------
DROP TABLE IF EXISTS `log_pet_upgrade`;
CREATE TABLE `log_pet_upgrade` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL COMMENT '玩家id' ,
`old_aptitude_lv`  tinyint(4) NOT NULL COMMENT '原来资质' ,
`new_aptitude_lv`  tinyint(4) NOT NULL COMMENT '新的资质' ,
`old_aptitude_progress`  smallint(6) NOT NULL COMMENT '原来资质进度' ,
`new_aptitude_progress`  smallint(6) NOT NULL COMMENT '新的资质进度' ,
`gold`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗元宝' ,
`coin`  smallint(6) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`cost_goods`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗物品' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物提升'
AUTO_INCREMENT=992

;