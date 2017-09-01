-- ----------------------------
-- Table structure for `temp_dungeon_trigger`
-- ----------------------------
DROP TABLE IF EXISTS `temp_dungeon_trigger`;
CREATE TABLE `temp_dungeon_trigger` (
`sid`  int(11) NOT NULL DEFAULT 0 COMMENT '触发器标识' ,
`action`  int(11) NOT NULL DEFAULT 0 COMMENT '该副本的触发器标识\r\n\r\n1、玩家进入地图\r\n2、玩家死亡\r\n11 - 99 、玩家移动(位置同步)\r\n101 - 199、触发机关' ,
`area`  varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '{}' COMMENT '{X1,Y1,...,Xn,Yn}在校验的时候，玩家的位置X，Y满足这样的关系: X1<= X <= X2 && Y1<= Y <= Y2' ,
`event`  int(11) NOT NULL DEFAULT 0 COMMENT '响应时间类型:\r\n1 - 刷怪\r\n2 - 播放剧情\r\n3 - 播放动画' ,
`param`  varchar(500) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '[]' COMMENT '事件参数\r\n根据event的取值进行，配置数据格式不一样：\r\n1、刷怪，填刷怪的区域，建议是给一个中心点，然后给一个范围随机出现。如[{X,Y,MonId}] ;\r\n2、播放剧情，填剧情ID 如 [FilmId] ;\r\n3、播放动画，填动画ID和动作ID[{AnimId,ActionId}]' ,
PRIMARY KEY (`sid`, `action`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='场景数据结构\r\n1、基础'

;