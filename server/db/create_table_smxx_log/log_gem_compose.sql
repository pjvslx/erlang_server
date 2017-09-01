-- ----------------------------
-- Table structure for `log_gem_compose`
-- ----------------------------
DROP TABLE IF EXISTS `log_gem_compose`;
CREATE TABLE `log_gem_compose` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NULL DEFAULT NULL ,
`gid`  bigint(20) NULL DEFAULT NULL ,
`gtid`  int(11) NULL DEFAULT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,
`coin`  int(11) NULL DEFAULT NULL ,
`bcoin`  int(11) NULL DEFAULT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='±¦Ê¯ºÏ³É'
AUTO_INCREMENT=1

;