-- ----------------------------
-- Table structure for `rela_friend_req`
-- ----------------------------
DROP TABLE IF EXISTS `rela_friend_req`;
CREATE TABLE `rela_friend_req` (
`id`  int(11) NOT NULL AUTO_INCREMENT COMMENT '好友请求记录ID' ,
`uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '被添加的玩家ID' ,
`req_uid`  bigint(20) NOT NULL DEFAULT 0 COMMENT '发出请求的玩家ID' ,
`req_nick`  char(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '发出请求的玩家名' ,
`req_career`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '发出请求的玩家ID' ,
`req_gender`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '发出请求的玩家性别' ,
`req_camp`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '发出请求的玩家阵营' ,
`req_level`  smallint(6) NOT NULL DEFAULT 0 COMMENT '发出请求的玩家ID(秒）' ,
`timestamp`  int(11) NOT NULL DEFAULT 0 COMMENT '发出请求时间（秒）' ,
`response`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '未回应0, 同意好友添加1, 2:不同意好友添加' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) ,
INDEX `req_uid` USING BTREE (`req_uid`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='好友请求表'
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `rela_friend_req`
-- ----------------------------
ALTER TABLE `rela_friend_req` AUTO_INCREMENT=1;