-- ----------------------------
-- Table structure for `temp_goods_buff`
-- ----------------------------
DROP TABLE IF EXISTS `temp_goods_buff`;
CREATE TABLE `temp_goods_buff` (
`gtid`  int(10) NOT NULL COMMENT '物品类型id' ,
`buff_tid`  int(10) NOT NULL COMMENT 'buff类型id' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品buff对应关系模版表'

;