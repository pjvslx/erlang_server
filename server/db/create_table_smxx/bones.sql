-- ----------------------------
-- Table structure for `bones`
-- ----------------------------
DROP TABLE IF EXISTS `bones`;
CREATE TABLE `bones` (
`uid`  bigint(20) NOT NULL DEFAULT 0 ,
`bones_info`  varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '[]' COMMENT '根骨状况[{根骨类型,根骨等级,成功率}...]' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='根骨'

;