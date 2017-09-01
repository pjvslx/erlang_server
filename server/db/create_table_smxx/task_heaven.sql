-- ----------------------------
-- Table structure for `task_heaven`
-- ----------------------------
DROP TABLE IF EXISTS `task_heaven`;
CREATE TABLE `task_heaven` (
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家id, 主键' ,
`reset_time`  int(11) NOT NULL DEFAULT 0 COMMENT '刷新事件' ,
`publish_count`  smallint(6) NOT NULL DEFAULT 0 COMMENT '当天发布数量' ,
`publish_heavens`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '发布的天道令数量,依次是天,地,玄,黄,{1,1,1,1}' ,
`receive_count`  smallint(6) NOT NULL DEFAULT 0 COMMENT '当天领取的次数' ,
`receive_heavens`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '领取的天道令数量,依次是天,地,玄,黄,{1,1,1,1}' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家天道令数据'

;