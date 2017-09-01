-- ----------------------------
-- Table structure for `skill`
-- ----------------------------
DROP TABLE IF EXISTS `skill`;
CREATE TABLE `skill` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '角色id' ,
`skill_list`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '已学习的技能ID列表[{SkillId, Level}]' ,
`cur_skill_list`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '当前正在使用的技能的ID[{SkillId, Level},...]' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='技能'

;