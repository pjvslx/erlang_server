-- ----------------------------
-- Table structure for `temp_pet`
-- ----------------------------
DROP TABLE IF EXISTS `temp_pet`;
CREATE TABLE `temp_pet` (
`level`  smallint(6) NOT NULL COMMENT '等级' ,
`attack`  int(11) NOT NULL COMMENT '普通攻击' ,
`crit`  int(11) NOT NULL COMMENT '暴击' ,
`hit`  int(11) NOT NULL COMMENT '命中' ,
`attr_attack`  int(11) NOT NULL COMMENT '属攻' ,
`skill_holes`  tinyint(4) NOT NULL COMMENT '技能槽数' ,
PRIMARY KEY (`level`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物模版'

;