%%------------------------------------------------
%% File    : mount.hrl
%% Author  : water
%% Created : 2013-03-13
%% Description: 座骑宏定义
%%------------------------------------------------
%% 避免头文件多重包含
-ifndef(__HEADER_MOUNT__).
-define(__HEADER_MOUNT__, 0).

%%-------------------------------------------------
%%座骑错误返回码
%%-------------------------------------------------
-define(MOUNT_ERROR,               0). %%玩家没有坐骑
-define(MOUNT_OK,                  1). %%成功
-define(MOUNT_LEVEL_NOT_ENOUGH,    2). %%等级不够
-define(MOUNT_COIN_NOT_ENOUGH,     3). %%铜币不够
-define(MOUNT_MAX_LEVEL,           4). %%座骑达到最大阶级
-define(MOUNT_MAX_STAR,            5). %%座骑达到最大星级
-define(MOUNT_MAX_SKILL_LEVEL,     6). %%技能达到最大等级
-define(MOUNT_FASHION_NOT_EXIST,   7). %%幻化不存在或已过期
-define(MOUNT_NOGOOD_FOR_LEVEL,    8). %%升阶符不够
-define(MOUNT_NOGOOD_FOR_STAR,     9). %%升星符不够
-define(MOUNT_NOSTAR_FOR_LEVEL,   10). %%星阶不够
-define(MOUNT_GOLD_NOT_ENOUGH,    11). %%金币不够
-define(MOUNT_NOT_ON_MOUNT,       12). %%不在骑上
-define(MOUNT_ALREADY_ONMOUNT,    13). %%已经在骑上
-define(MOUNT_AUTOBUY_NOT_ENOUGH, 14). %%身上的货币不足以支付材料
-define(MOUNT_COST_FASHION_FAIL,15).   %%消耗幻化卡失败
-define(MOUNT_FASHION_NOT_ACTIVE,16).  %%幻化形象没激活
-define(MOUNT_FASHION_UNVALIDE,17).    %%幻化形象非法
%%-------------------------------------------------

%%默认坐骑外观编号
-define(MOUNT_DEFAULT_FASHION,201).
%%坐骑计时器
-define(MOUNT_TIMER,mount_timer).

%%玩家上坐骑状态码
-define(MOUNT_GET_ON_STATE,1).
%%玩家下坐骑状态码
-define(MOUNT_GET_OFF_STATE,0).
-endif.
