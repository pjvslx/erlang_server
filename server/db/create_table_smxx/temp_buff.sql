-- ----------------------------
-- Table structure for `temp_buff`
-- ----------------------------
DROP TABLE IF EXISTS `temp_buff`;
CREATE TABLE `temp_buff` (
`buff_id`  int(11) NOT NULL DEFAULT 0 COMMENT 'BuffID' ,
`name`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '杂技' COMMENT 'Buff名字' ,
`type`  int(11) NOT NULL DEFAULT 0 COMMENT 'Buff类型(1增减属，2扣血加血，3特殊状态(不能移动)，4特殊状态(不能使用技能)，5特殊状态(石化)，6经验加成，7气血包，8法力包，9情缘Buff，10改变外观' ,
`group`  smallint(6) NOT NULL DEFAULT 0 COMMENT 'BUFF组' ,
`priority`  smallint(6) NOT NULL DEFAULT 0 COMMENT '同组BUFF应用优先级' ,
`last_time`  int(11) NOT NULL DEFAULT 0 COMMENT '持续时间（毫秒）,对有外观的BUFF，则为播放BUFF特效的时间' ,
`times`  int(11) NOT NULL DEFAULT 0 COMMENT '作用次数' ,
`ratio`  int(11) NOT NULL DEFAULT 10000 COMMENT '成功概率(10000为一定成功)' ,
`link_skill`  varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '挂接技能(对其他玩家起作用)[{SkillId, Lv}]' ,
`overlay`  tinyint(4) NOT NULL DEFAULT 0 COMMENT 'BUFF是否可以叠加1可以，0不可以' ,
`max_num`  int(11) NOT NULL DEFAULT 0 COMMENT '最大叠加数量' ,
`data`  varchar(10240) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT 'Buff效果列表[{Key, Value},...]' ,
`frame_speed`  int(11) NOT NULL COMMENT 'BUFF是否有挂接外怪:0-无，1-有' ,
`apearance`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '外观资源编号。数字类型，对应外观去temp_goods_facade查找' ,
`appearance_priority`  smallint(6) NOT NULL COMMENT '外观优先级。填写数字。数字的值越高，则在前' ,
PRIMARY KEY (`buff_id`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci

;