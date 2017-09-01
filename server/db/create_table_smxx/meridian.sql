-- ----------------------------
-- Table structure for `meridian`
-- ----------------------------
DROP TABLE IF EXISTS `meridian`;
CREATE TABLE `meridian` (
`player_id`  bigint(20) NOT NULL AUTO_INCREMENT COMMENT '玩家Id' ,
`mer_detail_1`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '玩家经脉1详细数据[{MerType,Merlv}...]' ,
`mer_detail_2`  varchar(256) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '玩家经脉2详细数据[{MerType,Merlv}...]' ,
`mer_state`  varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '玩家修炼经脉阶段{state1, state2}' ,
`cool_down`  varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{0,0}' COMMENT '剩余的冷却时间 {玩家开始修炼时间戳,剩余冷却时间，状态}' ,
PRIMARY KEY (`player_id`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=530000000326

;

-- ----------------------------
-- Auto increment value for `meridian`
-- ----------------------------
ALTER TABLE `meridian` AUTO_INCREMENT=1719022918;