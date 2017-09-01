-- ----------------------------
-- Table structure for `feedback`
-- ----------------------------
DROP TABLE IF EXISTS `feedback`;
CREATE TABLE `feedback` (
`id`  bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ID' ,
`type`  tinyint(1) UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型(1-Bug/2-投诉/3-建议/4-其它)' ,
`state`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态(已回复1/未回复0)' ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '玩家ID' ,
`name`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '玩家名' ,
`content`  mediumtext CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '内容' ,
`timestamp`  int(11) NOT NULL DEFAULT 0 COMMENT 'Unix时间戳' ,
`ip`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '玩家IP' ,
`server`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '服务器' ,
`gm`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '' COMMENT '游戏管理员' ,
`reply`  text CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '回复内容[{Nick,Content}....]' ,
`reply_time`  int(11) NULL DEFAULT 0 COMMENT '回复时间' ,
PRIMARY KEY (`id`),
INDEX `player_id` USING BTREE (`uid`) ,
INDEX `player_name` USING BTREE (`name`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家反馈'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `feedback`
-- ----------------------------
ALTER TABLE `feedback` AUTO_INCREMENT=1;