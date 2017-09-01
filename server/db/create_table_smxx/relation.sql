-- ----------------------------
-- Table structure for `relation`
-- ----------------------------
DROP TABLE IF EXISTS `relation`;
CREATE TABLE `relation` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家id' ,
`bless_times`  int(5) NOT NULL DEFAULT 0 COMMENT '今天祝福次数' ,
`max_friend`  int(5) NOT NULL DEFAULT 0 COMMENT '最大好友数目' ,
`max_blacklist`  int(5) NOT NULL COMMENT '最大黑名单数目' ,
`max_foe`  int(5) NOT NULL DEFAULT 0 COMMENT '最大仇人数目' ,
`friend_list`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '好友列表格式 [{玩家id,玩家姓名,玩家头像,好感度}, ...]' ,
`foe_list`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '仇人列表格式 [{玩家id,玩家姓名,玩家头像,好感度}...]' ,
`black_list`  varchar(2048) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '[{玩家id,玩家姓名,玩家头像}...]' ,
`recent_list`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '最近联系人列表格式 [{Uid, Time, Name, Career, Gender}, ...], Time 最近一次发生关系时间(秒)' ,
`flower`  int(7) NOT NULL DEFAULT 0 COMMENT '玩家收到的鲜花' ,
`flower_avail`  varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{3,0}' COMMENT '{玩家每天免费送花次数,已用次数}' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='关系列表'

;