-- ----------------------------
-- Table structure for `temp_npc`
-- ----------------------------
DROP TABLE IF EXISTS `temp_npc`;
CREATE TABLE `temp_npc` (
`nid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NPC编号' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '字名' ,
`title`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '称号' ,
`icon`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '怪物或者NPC形象' ,
`head`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '怪物或者NPC头像' ,
`model`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT 'NPC头顶图片资源' ,
`half_length`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT 'NPC半身原画(在玩家点击打开NPC对话时显示的资源)' ,
`npc_type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '类型：10-NPC;11-采集怪;20-普通小怪;21-精英怪物;22-副本小怪;30-野外BOS;31-世界BOSS;32-副本BOSS;33-帮派BOSS;40-宠物;50-坐骑' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物等级' ,
`fire_range`  int(11) NOT NULL DEFAULT 0 COMMENT '追击范围(格子距离)' ,
`warn_range`  int(11) NOT NULL DEFAULT 0 COMMENT '警介范围(格子距离)为0 的时候是被动怪物，大于0是主动怪物' ,
`hit_point`  int(11) NOT NULL DEFAULT 0 COMMENT '生命值' ,
`magic`  int(11) NOT NULL DEFAULT 0 COMMENT '法力值上限' ,
`greeting`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '怪物招呼语(怪物自说自话)' ,
`dialog`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT 'NPC无任务的时候点击显示' ,
`func`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' ,
`drop_id`  int(11) NOT NULL DEFAULT 0 COMMENT '掉落ID(temp_drop_main.did) 需要广播到场景中掉落物品' ,
`output_id`  int(11) NOT NULL DEFAULT 0 COMMENT '产出的掉落(temp_drop_main.did) 根据不同的怪物类型决定发给具体的角色' ,
`act_skilllist`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '主动技能列表[ID]' ,
`pas_skilllist`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '被动技能列表 [ID]' ,
`ai_id`  int(11) NOT NULL DEFAULT 0 COMMENT '怪物AI id' ,
`size`  int(8) NULL DEFAULT 0 COMMENT 'NPC缩放比例' ,
PRIMARY KEY (`nid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='NPC基础表'

;