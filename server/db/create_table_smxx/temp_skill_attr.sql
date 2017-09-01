-- ----------------------------
-- Table structure for `temp_skill_attr`
-- ----------------------------
DROP TABLE IF EXISTS `temp_skill_attr`;
CREATE TABLE `temp_skill_attr` (
`sid`  smallint(6) NOT NULL DEFAULT 0 COMMENT '技能ID' ,
`level`  smallint(6) NOT NULL DEFAULT 0 COMMENT '等级' ,
`require_list`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '学习技能需要技能列表[{SkilId, Level},...]' ,
`learn_level`  int(11) NOT NULL DEFAULT 0 COMMENT '学习技能需要玩家等级' ,
`cost_lilian`  int(11) NOT NULL DEFAULT 0 COMMENT '升级需要历练值' ,
`cost_coin`  int(11) NOT NULL DEFAULT 0 COMMENT '升级需要铜钱值' ,
`cost_magic`  int(11) NOT NULL DEFAULT 0 COMMENT '技能需要消耗法力值' ,
`cost_anger`  int(11) NOT NULL DEFAULT 0 COMMENT '使用需要的怒气值' ,
`abs_damage`  int(11) NOT NULL DEFAULT 0 COMMENT '技能附加的绝对伤害值' ,
`buff`  varchar(10240) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '技能BUFF[BuffId,...]' ,
`desc`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '描述，用于前端显示' ,
PRIMARY KEY (`sid`, `level`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='技能属性'

;