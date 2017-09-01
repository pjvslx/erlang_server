-- ----------------------------
-- Table structure for `log_gilding`
-- ----------------------------
DROP TABLE IF EXISTS `log_gilding`;
CREATE TABLE `log_gilding` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='¶Æ½ð'
AUTO_INCREMENT=1

;