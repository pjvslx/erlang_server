-- ----------------------------
-- Table structure for `dungeon_finish`
-- ----------------------------
DROP TABLE IF EXISTS `dungeon_finish`;
CREATE TABLE `dungeon_finish` (
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '平台账号ID' ,
`dlv`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' ,
`dlv0`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv1`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv2`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv3`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv4`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv5`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv6`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv7`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv8`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv9`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv10`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv11`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv12`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv13`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv14`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv15`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv16`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv17`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv18`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
`dlv19`  varchar(250) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '1-10级打过的副本' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;