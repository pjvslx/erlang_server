-- ----------------------------
-- Table structure for `temp_mon_ai`
-- ----------------------------
DROP TABLE IF EXISTS `temp_mon_ai`;
CREATE TABLE `temp_mon_ai` (
`id`  int(10) NOT NULL COMMENT 'AI编号' ,
`ai_trigger`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '触发条件' ,
`chat`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '怪物喊话' ,
`skill`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '使用技能' ,
`target`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '动作目标,触发AI后引发的行为' ,
`trigger_flag`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '整场战斗触发次数,0:不限次数,1:只触发1次' ,
`ai_type`  tinyint(4) NOT NULL DEFAULT 0 COMMENT 'AI类型:1怪物喊话,2怪物释放某技能,3选取仇恨列表第n位为目标,4怪物召唤同伴,5角色召唤同伴' ,
`next_ai`  int(11) NOT NULL DEFAULT 0 COMMENT '跳转到ai' ,
`content`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '备注' ,
PRIMARY KEY (`id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='怪物AI模版表'

;