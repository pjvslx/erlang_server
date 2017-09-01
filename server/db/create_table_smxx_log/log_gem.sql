-- ----------------------------
-- Table structure for `log_gem`
-- ----------------------------
DROP TABLE IF EXISTS `log_gem`;
CREATE TABLE `log_gem` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`type`  tinyint(4) NOT NULL COMMENT '0ÏâÇ¶,1²ð³ý' ,
`old_gem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`new_gem`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='±¦Ê¯ÏâÇ¶¡¢²ð³ý'
AUTO_INCREMENT=1

;