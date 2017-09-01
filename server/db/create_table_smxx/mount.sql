-- ----------------------------
-- Table structure for `mount`
-- ----------------------------
DROP TABLE IF EXISTS `mount`;
CREATE TABLE `mount` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家ID' ,
`state`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '状态1:骑 2休息' ,
`exp`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '经验值' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '等级(阶)' ,
`star`  smallint(5) NOT NULL DEFAULT 0 COMMENT '星级(最大10星)' ,
`fashion`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '当前幻化' ,
`force`  int(11) NOT NULL DEFAULT 0 COMMENT '座骑战斗力' ,
`skill_times`  tinyint(3) NOT NULL DEFAULT 0 COMMENT '技能升级次数' ,
`skill_list`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '技能列表[{SkillId, Lv, Exp},...]' ,
`fashion_list`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '幻化列表[{Fid, Expired},...], Fid幻化ID, Expire过期时间' ,
`old_fashion_list`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '过期幻化列表' ,
PRIMARY KEY (`uid`),
INDEX `level` USING BTREE (`level`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家座骑记录'

;