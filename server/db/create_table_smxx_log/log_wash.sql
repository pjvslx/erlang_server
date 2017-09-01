-- ----------------------------
-- Table structure for `log_wash`
-- ----------------------------
DROP TABLE IF EXISTS `log_wash`;
CREATE TABLE `log_wash` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) NOT NULL ,
`gid`  bigint(20) NOT NULL ,
`gtid`  int(11) NOT NULL ,
`old_attri`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`new_attri`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`coin`  int(11) NOT NULL ,
`bcoin`  int(11) NOT NULL ,
`gold`  int(11) NOT NULL ,
`bgold`  int(11) NOT NULL ,
`cost_goods`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='œ¥¡∑»’÷æ'
AUTO_INCREMENT=1

;