-- ----------------------------
-- Table structure for `guild_member`
-- ----------------------------
DROP TABLE IF EXISTS `guild_member`;
CREATE TABLE `guild_member` (
`uid`  bigint(20) UNSIGNED NOT NULL COMMENT '角色ID' ,
`guild_id`  int(11) UNSIGNED NOT NULL COMMENT '帮派ID' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '帮派名称' ,
`nick`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '角色昵称' ,
`gender`  int(5) NOT NULL DEFAULT 0 COMMENT '性别' ,
`career`  int(5) NOT NULL DEFAULT 0 COMMENT '职业' ,
`level`  int(5) NOT NULL DEFAULT 0 COMMENT '玩家等级' ,
`force`  int(5) NOT NULL DEFAULT 0 COMMENT '玩家战斗力' ,
`position`  int(2) UNSIGNED NOT NULL DEFAULT 4 COMMENT '1帮主 2副帮主 3元老 中间预留 10-帮众(最低)' ,
`devo`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '总贡献度' ,
`coin`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '累计捐献铜钱' ,
`gold`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '累计捐献元宝' ,
`today_devo`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '今日贡献度' ,
`devo_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '上次捐献时间' ,
`remain_devo`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '剩余贡献度' ,
`vote`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1赞成票2反对票' ,
`accuse_time`  int(11) NOT NULL DEFAULT 0 COMMENT '投票过期时间' ,
`title`  smallint(5) NOT NULL DEFAULT 0 COMMENT '称号等级' ,
`last_login_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '上次登录时间' ,
`sklist`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '技能列表[{Id, Level}]' ,
PRIMARY KEY (`uid`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `guild_id` USING BTREE (`guild_id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='帮派成员'

;