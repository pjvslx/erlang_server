-- ----------------------------
-- Table structure for `audit_gold_stock`
-- ----------------------------
DROP TABLE IF EXISTS `audit_gold_stock`;
CREATE TABLE `audit_gold_stock` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`all_gold`  int(11) NOT NULL COMMENT '总充值元宝' ,
`send_gold`  int(11) NOT NULL DEFAULT 0 COMMENT '充值赠送元宝数' ,
`used_gold`  int(11) NOT NULL COMMENT '消耗元宝' ,
`remain_gold`  int(11) NOT NULL COMMENT '元宝库存总量' ,
`recdate`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `recdate` USING BTREE (`recdate`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='元宝库存'
AUTO_INCREMENT=1

;