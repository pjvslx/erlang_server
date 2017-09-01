-- ----------------------------
-- Table structure for `log_kick_off`
-- ----------------------------
DROP TABLE IF EXISTS `log_kick_off`;
CREATE TABLE `log_kick_off` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT ,
`uid`  bigint(20) UNSIGNED NOT NULL COMMENT '用户ID' ,
`nick`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '名称' ,
`k_type`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '踢出类型:1废号,2发包异常,3超时,7心跳包异常,8走路异常,9切换场景异常' ,
`time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '时间记录' ,
`scene`  int(11) NOT NULL ,
`x`  int(11) NOT NULL ,
`y`  int(11) NOT NULL ,
`other`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '其他' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=latin1 COLLATE=latin1_swedish_ci
COMMENT='镇妖塔日志'
AUTO_INCREMENT=7721

;