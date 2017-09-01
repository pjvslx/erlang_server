-- ----------------------------
-- Table structure for `server`
-- ----------------------------
DROP TABLE IF EXISTS `server`;
CREATE TABLE `server` (
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '编号Id' ,
`domain`  int(11) UNSIGNED NOT NULL DEFAULT 1 COMMENT '分区号' ,
`ip`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'ip地址' ,
`port`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '端口号' ,
`node`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '节点' ,
`num`  int(11) NULL DEFAULT 0 COMMENT '节点用户数' ,
`stop_access`  tinyint(5) NOT NULL DEFAULT 0 COMMENT '是否停止登陆该节点，0为可以登录，1为停止登陆' ,
`start_time`  int(11) NOT NULL DEFAULT 0 COMMENT '开服时间' ,
`state`  tinyint(11) NOT NULL DEFAULT 0 COMMENT '1-新开；2-火爆；3-良好；4-流畅；5-维护。' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='服务器列表'

;