-- ----------------------------
-- Table structure for `temp_shop`
-- ----------------------------
DROP TABLE IF EXISTS `temp_shop`;
CREATE TABLE `temp_shop` (
`shop_tab_page`  int(11) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`page`  int(10) NOT NULL ,
`location`  int(10) NOT NULL ,
`original_price`  int(10) NOT NULL ,
`real_price`  int(10) NOT NULL ,
`gold_type`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '0非绑定元宝,1绑定元宝' ,
`level_limit`  int(10) NOT NULL COMMENT '开放等级限制' ,
PRIMARY KEY (`shop_tab_page`, `gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='商城配置表'

;