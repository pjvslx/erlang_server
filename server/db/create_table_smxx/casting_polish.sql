-- ----------------------------
-- Table structure for `casting_polish`
-- ----------------------------
DROP TABLE IF EXISTS `casting_polish`;
CREATE TABLE `casting_polish` (
`gid`  bigint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '装备ID' ,
`uid`  bigint(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家ID' ,
`cur_attri`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '当前洗炼属性' ,
`new_attri`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '新洗炼属性' ,
PRIMARY KEY (`gid`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='洗炼属性表'

;