-- ----------------------------
-- Table structure for `temp_goods`
-- ----------------------------
DROP TABLE IF EXISTS `temp_goods`;
CREATE TABLE `temp_goods` (
`gtid`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型编号' ,
`name`  varchar(100) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '物品名称' ,
`icon`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '0' COMMENT '物品图标资源ID' ,
`fall`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '物品掉落在地图标ID' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型(参考宏定义)' ,
`subtype`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品子类型(参考宏定义)' ,
`quality`  tinyint(1) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色' ,
`sell_price`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品出售价格' ,
`career`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '职业限制，0为不限' ,
`gender`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '性别限制，0为女，1为男，2为男女不限' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '等级限制，0为不限' ,
`max_num`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '可叠加数' ,
`limit`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '限制条件，0不限制 1捡取绑定 2装备绑定 4不能出售' ,
`expire_time`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '有效期，0为不限，单位为秒' ,
`suit_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '套装ID，0为不是套装' ,
`cd`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'cd' ,
`desc`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '' COMMENT '物品描述信息' ,
`type_desc`  varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '对物品类型的描述      如弓手护肩' ,
PRIMARY KEY (`gtid`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='物品基础表'

;