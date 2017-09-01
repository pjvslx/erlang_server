-- ----------------------------
-- Table structure for `goods_strength`
-- ----------------------------
DROP TABLE IF EXISTS `goods_strength`;
CREATE TABLE `goods_strength` (
`id`  bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '玩家物品id' ,
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家id' ,
`gtid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型id' ,
`type`  mediumint(8) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型' ,
`stype`  mediumint(8) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品子类型' ,
`quality`  mediumint(8) UNSIGNED NOT NULL DEFAULT 0 COMMENT '品质，决定颜色' ,
`num`  mediumint(8) NOT NULL COMMENT '当前数量' ,
`cell`  mediumint(8) NOT NULL COMMENT '所在格子' ,
`streng_lv`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '强化等级' ,
`use_times`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '使用次数' ,
`expire_times`  bigint(20) NOT NULL COMMENT '有效时间' ,
`spec`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '特殊字段' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `goods_strength`
-- ----------------------------
ALTER TABLE `goods_strength` AUTO_INCREMENT=1;