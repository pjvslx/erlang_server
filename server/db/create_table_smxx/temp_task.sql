-- ----------------------------
-- Table structure for `temp_task`
-- ----------------------------
DROP TABLE IF EXISTS `temp_task`;
CREATE TABLE `temp_task` (
`tid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '任务编号' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '任务类型(见task.hrl)' ,
`start_npc`  int(11) NOT NULL DEFAULT 0 COMMENT '开始NPC' ,
`start_scene`  int(11) NOT NULL DEFAULT 0 COMMENT '开始场景' ,
`end_npc`  int(11) NOT NULL DEFAULT 0 COMMENT '结束NPC' ,
`end_scene`  int(11) NOT NULL DEFAULT 0 COMMENT '结束场景' ,
`target_type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '任务目标类型' ,
`target_property`  varchar(60) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '任务目标数量[[id,fin_num,begin_num]]' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '任务名称' ,
`desc`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '任务描述' ,
`ongoing_dialog`  varchar(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '\"\"' COMMENT '未完成任务对白' ,
`finish_dialog`  varchar(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '完成任务对白，格式为：[{NPC对白},{角色对白}]，若角色不说话，则格式为：[{NPC对白}]' ,
`pre_tid`  int(11) NOT NULL DEFAULT 0 COMMENT '要求前置任务编号' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '等级限制' ,
`career`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '职业限定(0:不限，其他为对应职业)' ,
`gender`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '性别限定(2:不限，其他为对应性别)' ,
`guild`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '家族限定(0:不限，1:有家族才能接)' ,
`team`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '组队限定(0：不限，1：组队才能做)' ,
`goods_list`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '任务可选奖励物品列表[{标识类型(0:无标识 1:以职业为标识),类型编号,奖品id,奖品数量}..]' ,
`guild_goods_list`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '任务奖励帮派资源列表' ,
`func_num`  int(11) NOT NULL DEFAULT 0 COMMENT '任务目标类型(前段用)' ,
`next_tid`  int(11) NOT NULL COMMENT '下一级任务id' ,
PRIMARY KEY (`tid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='任务表'

;