-- ----------------------------
-- Table structure for `temp_polish_goods`
-- ----------------------------
DROP TABLE IF EXISTS `temp_polish_goods`;
CREATE TABLE `temp_polish_goods` (
`quality`  int(10) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色' ,
`max_polish`  int(10) NOT NULL COMMENT '最大洗练条数' ,
`goods`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '消耗品' ,
`cost_coin`  int(11) NOT NULL DEFAULT 0 COMMENT '消耗铜钱' ,
PRIMARY KEY (`quality`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='洗练消耗模版表'

;