-- ----------------------------
-- Table structure for `temp_mon_layout`
-- ----------------------------
DROP TABLE IF EXISTS `temp_mon_layout`;
CREATE TABLE `temp_mon_layout` (
`scene_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '场景ID' ,
`monid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物ID' ,
`x`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '出生X坐标' ,
`y`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '出生Y坐标' ,
`towards`  tinyint(1) UNSIGNED NOT NULL DEFAULT 0 COMMENT '1.北；2.东北；3.东；4.东南；5.南；6.西南；7.西；8.西北' ,
`revive_time`  int(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物死亡后的复活时长' ,
`state`  tinyint(2) NOT NULL DEFAULT 0 COMMENT '怪物状态：1-正常，2-战斗中，3-追击，4-死亡。' ,
`pos_x`  smallint(2) NOT NULL DEFAULT 0 COMMENT '当前位置的X左边' ,
`pos_y`  smallint(2) NOT NULL DEFAULT 0 COMMENT '当前位置的Y左边' ,
`attack_skill`  int(10) NOT NULL DEFAULT 0 COMMENT '攻击技能' ,
`skill_lv`  int(10) NOT NULL DEFAULT 0 COMMENT '技能等级' ,
`refresh_time`  int(10) NOT NULL DEFAULT 0 COMMENT '下次需要刷新的时间' ,
`last_move_time`  int(11) NOT NULL DEFAULT 0 COMMENT '上次移动的时间' ,
`move_time`  int(11) UNSIGNED ZEROFILL NOT NULL DEFAULT 00000000000 COMMENT '移动时间间隔,一个范围内的随机值' ,
`move_path`  int(11) UNSIGNED ZEROFILL NOT NULL DEFAULT 00000000000 COMMENT '上次移动的路径' ,
`hate_list`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '怪物的仇恨列表[{UID,DAMAGE,ADDTIME}]' ,
`buff_list`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '怪物的BUFF列表[{BUFFID,ExpireTime}]' ,
`sing_expire`  int(11) NULL DEFAULT NULL COMMENT '开始吟唱时间' ,
`monrcd`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '怪物配置结构，配置的时候不用填' ,
`battle_attr`  varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '战斗属性战斗属性，玩家不用填' ,
`target_uid`  int(11) NOT NULL DEFAULT 0 COMMENT '主动怪物，被动怪物的攻击 目标玩家ID' ,
`id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物唯一标识(场景ID+怪物ID+**).配置的时候不用填' ,
`round_times`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物第攻击次数' ,
`ai_skill_id`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '怪物AI产生的技能,0为无AI技能' ,
`ai_skill_lv`  tinyint(4) NOT NULL DEFAULT 0 COMMENT '怪物AI产生的技能等级' ,
`start_fight_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '怪物进入战斗时间,单位秒' ,
`ai_handle_list`  varchar(150) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '整场战斗触发AI产生的行为列表,整场战斗只触发1次' ,
`hate_seq`  tinyint(4) NOT NULL DEFAULT 1 COMMENT '选取仇恨列表第n位为目标,0为最后1位' ,
`pid` varchar(50) COMMENT '怪物进程的id',
PRIMARY KEY (`scene_id`, `monid`, `x`, `y`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='怪物刷新'

;
