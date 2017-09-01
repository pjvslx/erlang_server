-- ----------------------------
-- Table structure for `temp_combat_attr`
-- ----------------------------
DROP TABLE IF EXISTS `temp_combat_attr`;
CREATE TABLE `temp_combat_attr` (
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '等级' ,
`career`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '对人是职业，对怪物是类型。' ,
`exp`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '对人是升级所需经验，对怪是产出经验。' ,
`hit_point_max`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '生命上限' ,
`magic_max`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '法力上限' ,
`combopoint_max`  int(11) NOT NULL DEFAULT 0 COMMENT '最大连击点数' ,
`anger_max`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怒气值上限' ,
`attack`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '普通攻击力' ,
`abs_damage`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '绝对伤害值' ,
`defense`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '普通防御力' ,
`fattack`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '仙攻值' ,
`mattack`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '魔攻值' ,
`dattack`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '妖攻值' ,
`fdefense`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '仙防值' ,
`mdefense`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '魔防值' ,
`ddefense`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '妖防值' ,
`speed`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '移动速度' ,
`attack_speed`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '攻击速度' ,
`hit_ratio`  smallint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '命中率(万分比)' ,
`dodge_ratio`  smallint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '闪避率(万分比)' ,
`crit_ratio`  smallint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '暴击率(万分比)' ,
`tough_ratio`  smallint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '坚韧率(万分比)' ,
`frozen_resis_ratio`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '冰冻抗性率(万分比)' ,
`weak_resis_ratio`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '虚弱抗性率(万分比)' ,
`flaw_resis_ratio`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '破绽抗性率(万分比)' ,
`poison_resis_ratio`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '中毒抗性率(万分比)' ,
PRIMARY KEY (`level`, `career`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='战斗属性表'

;