-- ----------------------------
-- Table structure for `temp_vip_bag`
-- ----------------------------
DROP TABLE IF EXISTS `temp_vip_bag`;
CREATE TABLE `temp_vip_bag` (
`vip_gtid`  int(10) NOT NULL DEFAULT 0 ,
`cell_num`  int(10) NULL DEFAULT NULL ,
PRIMARY KEY (`vip_gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='vip±³°üÄ£°æ±í'

;