-- ----------------------------
-- Table structure for `charge`
-- ----------------------------
DROP TABLE IF EXISTS `charge`;
CREATE TABLE `charge` (
`order_id`  bigint(20) NOT NULL COMMENT '充值订单号' ,
`game_id`  varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '游戏编号' ,
`server_id`  int(10) NOT NULL COMMENT '服务器编号' ,
`account_id`  bigint(20) NOT NULL COMMENT '4399平台用户唯一标识' ,
`pay_way`  tinyint(4) NOT NULL COMMENT '1：手游币兑换2：神州行3：联通4：支付宝' ,
`amount`  int(10) NOT NULL COMMENT '支付金额' ,
`gold`  int(10) NOT NULL COMMENT '元宝数' ,
`handle_status`  tinyint(3) UNSIGNED NOT NULL COMMENT '订单处理状态,0游戏未处理,1已处理' ,
`create_time`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ,
PRIMARY KEY (`order_id`),
INDEX `account_id` USING BTREE (`account_id`) 
)
ENGINE=InnoDB
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
COMMENT='充值表'

;