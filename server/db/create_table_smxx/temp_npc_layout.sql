-- ----------------------------
-- Table structure for `temp_npc_layout`
-- ----------------------------
DROP TABLE IF EXISTS `temp_npc_layout`;
CREATE TABLE `temp_npc_layout` (
`scene_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '场景ID' ,
`npcid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NPCID' ,
`x`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'X坐标' ,
`y`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Y坐标' ,
`towards`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1.北；2.东北；3.东；4.东南；5.南；6.西南；7.西；8.西北' ,
`npcrcd`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT 'NPC实例，配置的时候不用填' ,
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'NPC唯一ID 配置的时候不用填' ,
PRIMARY KEY (`scene_id`, `npcid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='NPC刷新'

;