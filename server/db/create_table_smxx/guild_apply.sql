-- ----------------------------
-- Table structure for `guild_apply`
-- ----------------------------
DROP TABLE IF EXISTS `guild_apply`;
CREATE TABLE `guild_apply` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '角色ID' ,
`guild_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '帮派ID' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '角色昵称' ,
`gender`  tinyint(3) NOT NULL DEFAULT 0 COMMENT '性别' ,
`career`  tinyint(3) NOT NULL DEFAULT 0 COMMENT '职业' ,
`level`  int(5) NOT NULL DEFAULT 0 COMMENT '玩家等级' ,
`force`  int(5) NOT NULL DEFAULT 0 COMMENT '玩家战斗力' ,
`timestamp`  int(11) NOT NULL DEFAULT 0 COMMENT '申请时间' ,
PRIMARY KEY (`uid`, `guild_id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `guild_id` USING BTREE (`guild_id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='帮派申请'

;