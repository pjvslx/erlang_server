DROP TABLE IF EXISTS `temp_mount_medicine`;
CREATE TABLE `temp_mount_medicine` (
`gtid`  int(11) NOT NULL COMMENT '坐骑进星丹的id,坐骑进星丹分为初级、中级、高级、特级、顶级' ,
`add_mount_exp`  int(11) NOT NULL COMMENT '服用进星丹，可以使对应星级的进度条增加具体的数值' ,
`gold_id`  int(11) NOT NULL COMMENT '消耗货币ID' ,
`gold_num`  int(11) NOT NULL COMMENT '消耗货币量' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci