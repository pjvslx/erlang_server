-- ----------------------------
-- Table structure for `pet`
-- ----------------------------
DROP TABLE IF EXISTS `pet`;
CREATE TABLE `pet` (
`uid`  bigint(20) NOT NULL ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '昵称' ,
`attack`  int(11) NOT NULL DEFAULT 0 COMMENT '普通攻击力' ,
`attr_attack`  int(11) NOT NULL DEFAULT 0 COMMENT '属攻' ,
`attack_type`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '属攻类型:1仙攻,2魔攻,3妖攻' ,
`hit`  int(11) NOT NULL DEFAULT 0 COMMENT '命中' ,
`crit`  int(11) NOT NULL DEFAULT 0 COMMENT '暴击' ,
`fighting`  int(11) NOT NULL DEFAULT 0 COMMENT '战力' ,
`quality_lv`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '品阶' ,
`fail_times`  int(11) NOT NULL DEFAULT 0 COMMENT '升级品级失败次数' ,
`growth_lv`  smallint(6) NOT NULL DEFAULT 0 COMMENT '成长值' ,
`growth_progress`  smallint(6) NOT NULL DEFAULT 0 COMMENT '成长进度' ,
`aptitude_lv`  smallint(6) NOT NULL DEFAULT 0 COMMENT '资质' ,
`aptitude_progress`  smallint(6) NOT NULL DEFAULT 0 COMMENT '资质进度' ,
`status`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '0休息,1参战' ,
`skill_hole`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '开启技能槽总数' ,
`skill_list`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '技能ID列表[{SkillId, Level}]' ,
`current_facade`  int(11) NOT NULL DEFAULT 0 COMMENT '当前外观id' ,
`old_facade`  int(11) NOT NULL DEFAULT 0 COMMENT '原来外观id' ,
`facade_list`  varchar(300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '外观列表[]' ,
`suit_list`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '套装列表' ,
`create_time`  int(11) NOT NULL COMMENT '创建时间' ,
`battle_attr`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '战斗属性' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='宠物表'

;