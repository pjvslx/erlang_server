-- ----------------------------
-- Table structure for `temp_skill`
-- ----------------------------
DROP TABLE IF EXISTS `temp_skill`;
CREATE TABLE `temp_skill` (
`sid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '技能编号' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '技能名称' ,
`icon`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '技能资源编号,填写方式[技能升级面板突变id,主界面图标id]' ,
`type`  smallint(5) NOT NULL DEFAULT 0 COMMENT '技能类型(0:普通(单体攻击)，1:单体攻击 2:群体攻击 3: 单体辅助 4:群体辅助)' ,
`stype`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '子类型0：没要求， 1 玩家技能 2 怪的技能3宠物的技能,10-被动技能' ,
`target_type`  tinyint(4) NOT NULL COMMENT '0-单体目标；1-以自身为中心；2-以目标为中心；3-以地面某点为中心' ,
`career`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '职业要求，0为不要求。1战士，2法师， 3射手,6-宠物，20-普通小怪;21-精英怪物;22-副本小怪;30-野外BOS;31-世界BOSS;32-副本BOSS;33-帮派BOSS;\r\n' ,
`distance`  int(11) NOT NULL DEFAULT 0 COMMENT '技能释放距离：\r\n\r\n以自身为中心时为0；\r\n以目标位中心时，填目标距离玩家的距离。' ,
`aoe_dist`  int(11) NOT NULL DEFAULT 0 COMMENT '技能AOE作用的距离' ,
`aoe_tnum`  int(11) NOT NULL DEFAULT 0 COMMENT '技能AOE目标数量' ,
`cd_all`  int(11) NOT NULL DEFAULT 0 COMMENT '技能CD(毫秒)，对所有技能' ,
`cd_group`  varchar(50) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL DEFAULT '[]' COMMENT '技能CD组(毫秒)，对指定技能[{SkillId, CdTime},...]。' ,
`sing_time`  int(11) NOT NULL DEFAULT 0 COMMENT '吟唱时间(毫秒)' ,
`sing_break`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '吟唱状态可否中断(1可，0木)' ,
`description`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '技能描述' ,
`use_combopoint`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '是否消耗连击点(0为不消耗, 1为消耗)' ,
`attack_choose`  int(10) NULL DEFAULT 0 COMMENT '不知道嘛东西，据说客户端使用' ,
`start_effect_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '起手特效ID' ,
`start_effect_frame`  int(10) NULL DEFAULT 0 COMMENT '起手特效帧数' ,
`start_frame_speed`  int(10) NULL DEFAULT 0 COMMENT '起始帧速' ,
`end_effect_id`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0' COMMENT '终止特效ID' ,
`end_effect_frame`  int(10) NULL DEFAULT 0 COMMENT '起手特效帧数' ,
`end_frame_speed`  int(10) NULL DEFAULT 0 COMMENT '起始帧速' ,
PRIMARY KEY (`sid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='技能数据'

;