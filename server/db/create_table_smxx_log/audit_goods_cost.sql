-- ----------------------------
-- Table structure for `audit_goods_cost`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_cost`;
CREATE TABLE `audit_goods_cost` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`used_count`  int(11) NOT NULL COMMENT '消耗的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品的消耗量（不区分是商城购买还是系统产出，只要有消耗，就加1，区分两套道具，只有在商城有销售的物品才统计消耗）'
AUTO_INCREMENT=1

;