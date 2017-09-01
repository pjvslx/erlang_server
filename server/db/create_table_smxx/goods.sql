-- ----------------------------
-- Table structure for `goods`
-- ----------------------------
DROP TABLE IF EXISTS `goods`;
CREATE TABLE `goods` (
`id`  bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '玩家物品Id' ,
`uid`  bigint(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '玩家ID' ,
`pet_id`  tinyint(4) UNSIGNED NOT NULL DEFAULT 0 COMMENT '宠物Id（装备穿在宠物身上时对应的武将唯一Id）' ,
`gtid`  int(11) NOT NULL DEFAULT 0 COMMENT '物品类型编号' ,
`location`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品所在位置' ,
`cell`  smallint(5) NOT NULL DEFAULT 0 COMMENT '物品所在格子位置' ,
`num`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品数量' ,
`score`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '装备评分：非装备用0表示' ,
`hole`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '镶孔数' ,
`hole_goods`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '孔所镶物品类型ID' ,
`polish_num`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '洗练次数' ,
`stren_lv`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '强化等级' ,
`stren_percent`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '强化完美度' ,
`add_succ_rate`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '增加强化成功率' ,
`type`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品类型(参考宏定义)' ,
`subtype`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品子类型(参考宏定义)' ,
`quality`  tinyint(1) NOT NULL COMMENT '品质，决定了物品名称颜色1:白色，2：绿色，3：蓝色，4：紫色，5：橙色' ,
`sell_price`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品出售价格' ,
`career`  tinyint(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT '职业限制，0为不限' ,
`gender`  tinyint(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT '性别限制，0为女，1为男，2为男女不限' ,
`level`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '等级限制，0为不限' ,
`max_num`  smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT '可叠加数，0为不可叠加' ,
`bind`  tinyint(2) UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定状态,0不限制,2装备绑定,3已绑定' ,
`expire_time`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '有效期，0为不限，单位为秒' ,
`suit_id`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '套装ID，0为不是套装' ,
`gilding_lv`  tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '镀金等级' ,
`goods_cd`  int(11) UNSIGNED NOT NULL DEFAULT 0 COMMENT '物品使用cd' ,
PRIMARY KEY (`id`),
INDEX `uid` USING BTREE (`uid`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='玩家物品记录'
AUTO_INCREMENT=530000000575

;