-- ----------------------------
-- Table structure for `notice`
-- ----------------------------
DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice` (
`id`  int(11) NOT NULL AUTO_INCREMENT ,
`uid`  int(11) NULL DEFAULT NULL ,
`claz`  tinyint(2) NULL DEFAULT 0 COMMENT '通知类型：1-系统补偿；2-登陆奖励，3-世界BOSS，4-新手奖励，5-竞技场，6-天宫探宝，7-联盟战赛事奖励,8-首冲礼包,9-联盟战据点收益奖励\',' ,
`type`  tinyint(2) NULL DEFAULT 0 COMMENT '消息类型(0-系统通知，1 => 竞技场；2 => 联盟; 3 => 活动; 4 => 好友  ;5=>世界BOSS; 6=>好友祝福 ; 7=>好友  ;8=>祝福; 9=> 联盟战,99 -系统发给个人的邮件' ,
`cntt`  varchar(4000) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '\"\"' COMMENT '消息内容' ,
`tmsp`  int(11) NULL DEFAULT NULL COMMENT '消息生成时间戳' ,
`exp`  int(11) NULL DEFAULT 0 COMMENT '附件：体力' ,
`eng`  int(11) NULL DEFAULT 0 COMMENT '附件：经验' ,
`coin`  int(11) NULL DEFAULT 0 COMMENT '附件：铜钱' ,
`prstg`  int(11) NULL DEFAULT 0 COMMENT '战勋奖励' ,
`sprt`  int(11) NULL DEFAULT 0 COMMENT '附件：灵力' ,
`soul`  int(11) NULL DEFAULT 0 COMMENT '元魂' ,
`gold`  int(11) NULL DEFAULT 0 COMMENT '附件：元宝' ,
`goods`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '附件：物品[{goodtypeid,number},...]' ,
`sts`  tinyint(2) NULL DEFAULT 1 COMMENT '状态：-1-审核不通过，0-未审核，1-未领取，2-已领取' ,
`rtmsp`  int(11) NULL DEFAULT 0 COMMENT '消息读取时间戳' ,
`otid`  int(11) NULL DEFAULT 0 COMMENT '其它ID，例如好友ID' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=cp850 COLLATE=cp850_general_ci
AUTO_INCREMENT=1

;

-- ----------------------------
-- Auto increment value for `notice`
-- ----------------------------
ALTER TABLE `notice` AUTO_INCREMENT=1;