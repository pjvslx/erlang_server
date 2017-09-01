-- ----------------------------
-- Table structure for `buy_npc_shop_log`
-- ----------------------------
DROP TABLE IF EXISTS `buy_npc_shop_log`;
CREATE TABLE `buy_npc_shop_log` (
`uid`  bigint(20) NOT NULL ,
`shopid`  int(11) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`buy_num`  int(11) NOT NULL ,
`buy_time`  int(11) NOT NULL ,
PRIMARY KEY (`uid`, `shopid`, `gtid`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='π∫¬Únpc…ÃµÍ»’÷æ'

;