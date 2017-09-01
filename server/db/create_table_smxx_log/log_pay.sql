-- ----------------------------
-- Table structure for `log_pay`
-- ----------------------------
DROP TABLE IF EXISTS `log_pay`;
CREATE TABLE `log_pay` (
`id`  int(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '自增id' ,
`pay_num`  varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '充值订单号' ,
`pay_user`  varchar(20) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '充值用户名' ,
`player_id`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家角色ID' ,
`nickname`  varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' COMMENT '角色名称' ,
`lv`  smallint(6) UNSIGNED NOT NULL DEFAULT 0 COMMENT '角色等级' ,
`reg_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '注册时间' ,
`first_pay`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否第一次充值:1-是0-否' ,
`money`  int(11) UNSIGNED NULL DEFAULT 0 COMMENT '币货数' ,
`pay_gold`  int(11) NOT NULL DEFAULT 0 COMMENT '游戏币数量' ,
`pay_time`  int(11) NOT NULL DEFAULT 0 COMMENT '来自平台的时间 ' ,
`insert_time`  int(11) NOT NULL DEFAULT 0 COMMENT '插入数据库时间' ,
`pay_status`  smallint(6) NOT NULL DEFAULT 0 COMMENT '支付状态(1:成功;0失败;2:角色不存在)' ,
`state`  smallint(55) NOT NULL DEFAULT 0 COMMENT '奖励系统使用标志(0 未使用，1已使用)' ,
PRIMARY KEY (`id`),
INDEX `player_id` USING BTREE (`player_id`) ,
INDEX `nickname` USING BTREE (`nickname`) 
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家充值记录表'
AUTO_INCREMENT=1

;