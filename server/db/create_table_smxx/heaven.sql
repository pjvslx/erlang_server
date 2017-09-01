-- ----------------------------
-- Table structure for `heaven`
-- ----------------------------
DROP TABLE IF EXISTS `heaven`;
CREATE TABLE `heaven` (
`id`  int(10) NOT NULL AUTO_INCREMENT COMMENT '主键' ,
`reset_time`  int(17) NOT NULL DEFAULT 0 ,
`heaven_count`  int(10) NOT NULL DEFAULT 0 COMMENT '天道令数量' ,
PRIMARY KEY (`id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='天道令信息'
AUTO_INCREMENT=5

;

-- ----------------------------
-- Auto increment value for `heaven`
-- ----------------------------
ALTER TABLE `heaven` AUTO_INCREMENT=5;