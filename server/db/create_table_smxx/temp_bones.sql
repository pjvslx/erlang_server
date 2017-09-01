-- ----------------------------
-- Table structure for `temp_bones`
-- ----------------------------
DROP TABLE IF EXISTS `temp_bones`;
CREATE TABLE `temp_bones` (
`lv`  int(3) NOT NULL AUTO_INCREMENT COMMENT '根骨id' ,
`bones_val`  int(7) NOT NULL COMMENT '根骨提升值(万分比)' ,
`probability`  int(7) NOT NULL DEFAULT 0 COMMENT '成功率(万分比)' ,
`extend_pro`  int(7) NOT NULL DEFAULT 0 COMMENT '反馈成功率(万分比)' ,
PRIMARY KEY (`lv`)
)
ENGINE=MyISAM
DEFAULT CHARACTER SET=utf8 COLLATE=utf8_general_ci
AUTO_INCREMENT=11

;

-- ----------------------------
-- Auto increment value for `temp_bones`
-- ----------------------------
ALTER TABLE `temp_bones` AUTO_INCREMENT=11;