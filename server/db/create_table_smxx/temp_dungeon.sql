-- ----------------------------
-- Table structure for `temp_dungeon`
-- ----------------------------
DROP TABLE IF EXISTS `temp_dungeon`;
CREATE TABLE `temp_dungeon` (
`sid`  int(11) NOT NULL DEFAULT 0 COMMENT '地图ID，temp_scene.sid' ,
`name`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '\"\"' ,
`grp`  int(10) NULL DEFAULT 0 COMMENT '副本组ID' ,
`duration`  int(11) NOT NULL DEFAULT 0 COMMENT '进入副本后持续时间（从进入副本之时开始算，时间到后自动传出）\r\n\r\n单位 秒' ,
`last_sid`  int(11) NOT NULL DEFAULT 0 COMMENT '地图ID，temp_scene.sid' ,
`pass_type`  int(2) NULL DEFAULT 0 COMMENT '通关条件类型：\r\n1 - 杀死固定的怪物和数量\r\n2 - 杀死总共的怪物数量' ,
`pass_cond`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '通关条件内容：\r\n1、杀死指定的怪物和数量的时候\r\n   配置为[{MonId,Number}]\r\n2、杀死总共怪物数量的时候，则为[totalNumber]' ,
`rewards`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '副本通关奖励' ,
`king_rewards`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '霸主奖励' ,
`hard_desc`  varchar(15) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '前端用于显示副本难度的内容' ,
PRIMARY KEY (`sid`, `last_sid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='场景数据结构\r\n1、基础'

;