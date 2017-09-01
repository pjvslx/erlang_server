-- ----------------------------
-- Table structure for `task_finish`
-- ----------------------------
DROP TABLE IF EXISTS `task_finish`;
CREATE TABLE `task_finish` (
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家ID' ,
`td1`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '1-10级任务ID' ,
`td2`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '11-20级任务ID' ,
`td3`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '21-30级任务ID' ,
`td4`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '31-40级任务ID' ,
`td5`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '41-50级任务ID' ,
`td6`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '51-60级任务ID' ,
`td7`  varchar(1000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '61-70级任务ID' ,
`td`  varchar(10) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '任务ID' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;