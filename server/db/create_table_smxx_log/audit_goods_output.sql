-- ----------------------------
-- Table structure for `audit_goods_output`
-- ----------------------------
DROP TABLE IF EXISTS `audit_goods_output`;
CREATE TABLE `audit_goods_output` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`item_id`  int(11) NOT NULL COMMENT '物品id' ,
`get_count`  int(11) NOT NULL COMMENT '玩家获得的物品数量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品产出统计（统计除了商城购买外，其他任何方式取得的道具数据，包括开箱子、淘宝等方式，可以只统计商城有售的物品清单）'
AUTO_INCREMENT=1

;