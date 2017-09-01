-- ----------------------------
-- Table structure for `temp_pet_medicine`
-- ----------------------------
DROP TABLE IF EXISTS `temp_pet_medicine`;
CREATE TABLE `temp_pet_medicine` (
`gtid`  int(11) NOT NULL DEFAULT 0 COMMENT '丹药类型id' ,
`growth`  int(11) NULL DEFAULT 0 COMMENT '增加成长值' ,
`aptitude`  int(11) NULL DEFAULT 0 COMMENT '增加资质值' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物丹药增加进度模版'

;