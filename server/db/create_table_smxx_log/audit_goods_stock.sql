-- ----------------------------
-- Table structure for `audit_goods_stock`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_stock`;
CREATE TABLE `audit_goods_stock` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`remain_count`  int(11) NOT NULL COMMENT '剩余的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品的库存量（仅统计商城有出售的物品）'
AUTO_INCREMENT=1

;