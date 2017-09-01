-- ----------------------------
-- Table structure for `goods_attribute`
-- ----------------------------
DROP TABLE IF EXISTS `goods_attribute`;
CREATE TABLE `goods_attribute` (
`id`  bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '编号' ,
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '角色ID' ,
`gid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品编号ID' ,
`attribute_type`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '属性类型，1 强化，2 强化+4，3 强化+7，5 镶嵌' ,
`stone_type_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '宝石编号ID，无宝石为0' ,
`attribute_id`  mediumint(8) UNSIGNED NOT NULL DEFAULT 0 COMMENT '属性类型Id：0-气血，1-物理攻击。。。' ,
`value`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '属性值' ,
`value_type`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '属性值类型，0为数值，1为百分比' ,
`hole_seq`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '镶嵌宝石孔位置' ,
`status`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否生效，1为生效，0为不生效' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `gid_hole_seq` USING BTREE (`gid`, `hole_seq`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品属性表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `goods_attribute`
-- ----------------------------
ALTER TABLE `goods_attribute` AUTO_INCREMENT=1;