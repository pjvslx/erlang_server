-- ----------------------------
-- Table structure for `guild`
-- ----------------------------
DROP TABLE IF EXISTS `guild`;
CREATE TABLE `guild` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '帮派编号' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '帮派名称' ,
`chief_id`  bigint(20) NOT NULL DEFAULT 0 COMMENT '帮主角色' ,
`chief_name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '帮主名字' ,
`announce`  varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '帮派公告' ,
`level`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '帮派等级' ,
`current_num`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '当前人数' ,
`elite_num`  int(11) NOT NULL DEFAULT 0 COMMENT '当前长老数' ,
`devo`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '帮派贡献度' ,
`fund`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '帮派资金' ,
`upgrade_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '最近升级时间' ,
`create_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '创建时间' ,
`maintain_time`  int(11) NOT NULL DEFAULT 0 COMMENT '下次维护时间' ,
`state`  int(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '弹劾盟主时为1' ,
`accuse_id`  bigint(20) UNSIGNED NOT NULL COMMENT '发起弹劾的成员ID' ,
`accuse_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '弹劾到期时间' ,
`against`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '反对分数' ,
`agree`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '赞成分数' ,
`accuse_num`  int(11) NOT NULL DEFAULT 0 COMMENT '劾弹次数' ,
PRIMARY KEY (`id`),
UNIQUE INDEX `name` USING BTREE (`name`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='帮派'
AUTO_INCREMENT=106000001

;

-- ----------------------------
-- Auto increment value for `guild`
-- ----------------------------
ALTER TABLE `guild` AUTO_INCREMENT=106000001;