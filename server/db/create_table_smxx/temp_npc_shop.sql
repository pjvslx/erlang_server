-- ----------------------------
-- Table structure for `temp_npc_shop`
-- ----------------------------
DROP TABLE IF EXISTS `temp_npc_shop`;
CREATE TABLE `temp_npc_shop` (
`shop_id`  int(10) NOT NULL COMMENT '商店编号' ,
`shop_page`  int(10) NOT NULL COMMENT '商店页码' ,
`shop_type`  int(10) NOT NULL COMMENT '商店类型(0不限购,1限购)' ,
`shop_goods`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '[{购买兑换物品, 消耗物品,数量, 限购数量}]' ,
PRIMARY KEY (`shop_id`, `shop_page`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='商店模板表'

;