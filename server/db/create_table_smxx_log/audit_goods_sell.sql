-- ----------------------------
-- Table structure for `audit_goods_sell`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_sell`;
CREATE TABLE `audit_goods_sell` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`buy_count`  int(11) NOT NULL COMMENT '购买的物品数量' ,
`cost`  int(11) NOT NULL COMMENT '总价' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='商城物品销售统计'
AUTO_INCREMENT=1

;