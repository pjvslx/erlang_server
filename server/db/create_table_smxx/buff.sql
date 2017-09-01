-- ----------------------------
-- Table structure for `buff`
-- ----------------------------
DROP TABLE IF EXISTS `buff`;
CREATE TABLE `buff` (
`uid`  bigint(20) UNSIGNED NOT NULL COMMENT '角色ID' ,
`buff1`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, ExpireTime}]参考buff_util.erl' ,
`buff2`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, Cd, RemTimes},...]参考buff_util.erl' ,
`buff3`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '[]' COMMENT 'BUFF记录[{BufId, Cd, RemNumer},...]参考buff_util.erl' ,
PRIMARY KEY (`uid`)
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_unicode_ci
COMMENT='物品buff记录表\r\n'

;