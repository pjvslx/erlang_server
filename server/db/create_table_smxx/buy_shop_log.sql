-- ----------------------------
-- Table structure for `buy_shop_log`
-- ----------------------------
DROP TABLE IF EXISTS `buy_shop_log`;
CREATE TABLE `buy_shop_log` (
`uid`  bigint(20) NOT NULL ,
`shoptabid`  int(11) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`buy_num`  int(11) NOT NULL ,
`buy_time`  int(11) NOT NULL ,
PRIMARY KEY (`uid`, `shoptabid`, `gtid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='购买商城物品日志'

;