-- ----------------------------
-- Table structure for `temp_cultivation`
-- ----------------------------
DROP TABLE IF EXISTS `temp_cultivation`;
CREATE TABLE `temp_cultivation` (
`lv`  int(7) NOT NULL AUTO_INCREMENT COMMENT '修为等级' ,
`meridian_1`  int(7) NOT NULL COMMENT '经脉一等级' ,
`meridian_2`  int(7) NOT NULL COMMENT '经脉二等级' ,
`steps`  int(7) NOT NULL COMMENT '所需的星阶数' ,
`name`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '修为称号' ,
`property`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '修为属性[{职业类别,属性类型,属性值}]' ,
`cost`  int(7) NOT NULL COMMENT '花费的修为点' ,
PRIMARY KEY (`lv`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=2

;

-- ----------------------------
-- Auto increment value for `temp_cultivation`
-- ----------------------------
ALTER TABLE `temp_cultivation` AUTO_INCREMENT=2;