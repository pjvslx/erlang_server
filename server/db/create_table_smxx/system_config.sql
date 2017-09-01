-- ----------------------------
-- Table structure for `system_config`
-- ----------------------------
DROP TABLE IF EXISTS `system_config`;
CREATE TABLE `system_config` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家Id' ,
`shield_role`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '蔽屏附近玩家和宠物，0：不屏蔽；1：屏蔽' ,
`shield_skill`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '屏蔽技能特效， 0：不屏蔽；1：屏蔽' ,
`shield_rela`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '屏蔽好友请求，0：不屏蔽；1：屏蔽' ,
`shield_team`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '屏蔽组队邀请，0：不屏蔽；1：屏蔽' ,
`shield_chat`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '屏蔽聊天传闻，0：不屏蔽；1：屏蔽' ,
`fasheffect`  tinyint(1) NOT NULL DEFAULT 0 COMMENT '时装显示(0对别人显示，1对别人不显示)' ,
`music`  mediumint(8) UNSIGNED NOT NULL DEFAULT 50 COMMENT '游戏音乐，默认值为50' ,
`soundeffect`  mediumint(8) NOT NULL DEFAULT 50 COMMENT '游戏音效，默认值为50' ,
PRIMARY KEY (`uid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家系统设置'

;