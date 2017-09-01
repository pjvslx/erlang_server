-- ----------------------------
-- Table structure for `mail`
-- ----------------------------
DROP TABLE IF EXISTS `mail`;
CREATE TABLE `mail` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '信件id' ,
`uid`  bigint(11) NOT NULL COMMENT '收件人id' ,
`type`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '类型(0系统)' ,
`timestamp`  int(11) NOT NULL DEFAULT 0 COMMENT '发送时间戳(秒)' ,
`content`  int(11) NOT NULL DEFAULT 0 COMMENT '信件正文ID' ,
`goods_list`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '物品列表[{GoodsId, GTypeId, Num},...]' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `id` USING BTREE (`id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='信件信息'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `mail`
-- ----------------------------
ALTER TABLE `mail` AUTO_INCREMENT=1;