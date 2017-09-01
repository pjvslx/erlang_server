-- ----------------------------
-- Table structure for `log_godtried`
-- ----------------------------
DROP TABLE IF EXISTS `log_godtried`;
CREATE TABLE `log_godtried` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='±¶ Ø…Ò¡∂'
AUTO_INCREMENT=1

;