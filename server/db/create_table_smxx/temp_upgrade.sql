-- ----------------------------
-- Table structure for `temp_upgrade`
-- ----------------------------
DROP TABLE IF EXISTS `temp_upgrade`;
CREATE TABLE `temp_upgrade` (
`gtid`  int(10) NOT NULL COMMENT '当前物品id' ,
`goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '配方' ,
`cost_coin`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
`target_gtid`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '目标物品id' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='装备升级模版'

;