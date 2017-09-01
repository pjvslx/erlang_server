-- ----------------------------
-- Table structure for `opera`
-- ----------------------------
DROP TABLE IF EXISTS `opera`;
CREATE TABLE `opera` (
  `uid` bigint(20) unsigned NOT NULL COMMENT '角色ID',
  `operaDialogue` varchar(3000) NOT NULL DEFAULT '[]' COMMENT '已播放过的剧情对话',
  `operaAnimation` varchar(3000) NOT NULL DEFAULT '[]' COMMENT '已播放过的剧情动画',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色禁言表';
