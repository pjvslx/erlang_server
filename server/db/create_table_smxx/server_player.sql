-- ----------------------------
-- Table structure for `server_player`
-- ----------------------------
DROP TABLE IF EXISTS `server_player`;
CREATE TABLE `server_player` (
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家ID，全平台唯一' ,
`accid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家Id' ,
`serv_id`  int(50) NOT NULL DEFAULT 0 COMMENT '服务器标识' ,
`domain`  smallint(4) NOT NULL DEFAULT 0 COMMENT '大区标识' ,
`acc_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '账号名字' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '角色名字' ,
`sex`  smallint(2) NOT NULL DEFAULT 0 COMMENT '角色性别' ,
`career`  smallint(2) NOT NULL DEFAULT 0 COMMENT '角色职业' ,
`lv`  int(4) NOT NULL DEFAULT 0 COMMENT '角色等级' ,
`icon`  int(4) NOT NULL DEFAULT 0 COMMENT '图标' ,
`last_login`  int(11) NOT NULL DEFAULT 0 COMMENT '最后登录时间' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='服务器列表'

;