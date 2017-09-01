-- ----------------------------
-- Table structure for `temp_stren`
-- ----------------------------
DROP TABLE IF EXISTS `temp_stren`;
CREATE TABLE `temp_stren` (
`stren_lv`  int(10) UNSIGNED NOT NULL COMMENT '强化等级' ,
`add_percent`  int(10) UNSIGNED NOT NULL COMMENT '附加属性比例' ,
`goods`  int(11) NOT NULL DEFAULT 0 COMMENT '强化石id' ,
`cost_coin`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`stren_rate`  int(10) UNSIGNED NOT NULL COMMENT '强化基础成功率' ,
`stren_succ`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '强化成功等级增加区间' ,
`stren_fail`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '强化失败等级掉落区间' ,
`add_succ_rate`  int(10) NOT NULL COMMENT '强化失败后，下次强化成功率增加值' ,
`add_holes`  smallint(6) NOT NULL DEFAULT 0 COMMENT '新增插槽' ,
`desc`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '备注' ,
PRIMARY KEY (`stren_lv`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='强化模版表'

;