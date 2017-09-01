%%------------------------------------------------
%% File    : mail.hrl
%% Author  : water
%% Created : 2013-02-07
%% Description: 邮件宏定义
%%------------------------------------------------
%% 避免头文件多重包含
-ifndef(__HEADER_MAIL__).
-define(__HEADER_MAIL__, 0).

%%邮件类型
-define(MAIL_TYPE_SYS, 0).          %% 系统信件
-define(MAIL_TYPE_SHOP, 1).         %% 物品信件

%%-------------------------------------------------
%% 邮件/GM模块 错误返回码
%%-------------------------------------------------
-define(MAIL_OTHER_ERROR,           0).  %% 其它错误
-define(MAIL_WRONG_TITLE,           2).  %% 标题错误
-define(MAIL_WRONG_CONTENT,         3).  %% 内容错误
-define(MAIL_WRONG_NAME,            4).  %% 无合法收件人
-define(MAIL_BOX_FULL,              5).  %% 对方邮件已满
-define(MAIL_NOT_ENOUGH_SPACE,      6).  %% 背包已满
-define(MAIL_ATTACH_NOT_EXIST,      7).  %% 信件中不存在附件
-define(MAIL_GOODS_NOT_EXIST,       8).  %% 信件中物品已提取
-define(MAIL_WRONG_ID,              9).  %% 信件ID有误
-define(MAIL_TOO_FAST,             10).  %% 信件发得太快了休息一下吧
%%-------------------------------------------------

-endif.
