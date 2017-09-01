-- ----------------------------
-- Table structure for `log_charge`
-- ----------------------------
DROP TABLE IF EXISTS `log_charge`;
CREATE TABLE `log_charge` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`order_id`  bigint(20) NOT NULL COMMENT '充值订单号' ,
`gold`  int(10) NOT NULL COMMENT '元宝数' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值表'
AUTO_INCREMENT=1

;