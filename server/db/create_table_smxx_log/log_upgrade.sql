-- ----------------------------
-- Table structure for `log_upgrade`
-- ----------------------------
DROP TABLE IF EXISTS `log_upgrade`;
CREATE TABLE `log_upgrade` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`new_gtid`  int(11) NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='×°±¸Éý¼¶'
AUTO_INCREMENT=1

;