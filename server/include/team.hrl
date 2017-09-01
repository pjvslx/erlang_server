%%------------------------------------------------
%% File    : team.hrl
%% Author  : water
%% Created : 2013-03-12
%% Description: 组队宏定义
%%------------------------------------------------
%% 避免头文件多重包含
-ifndef(__HEADER_TEAM__).
-define(__HEADER_TEAM__, 0).

%%-------------------------------------------------
%% 队伍错误返回码
%%-------------------------------------------------
-define(TEAM_ERROR,               0). %%系统繁忙
-define(TEAM_OK,                  1). %%成功
-define(TEAM_LEVEL_NOT_ENOUGH,    2). %%等级不够
-define(TEAM_COIN_NOT_ENOUGH,     3). %%铜币不够
-define(TEAM_TOO_FAST,            4). %%间隔时间太短
-define(TEAM_NOT_EXIST,           5). %%队伍不存在
-define(TEAM_NOT_IN_TEAM,         6). %%你不在任何队伍中
-define(TEAM_ALREAD_IN_TEAM,      7). %%您已加入了队伍
-define(TEAM_MEMBER_FULL,         8). %%队伍成员数量已满
-define(TEAM_QUIT_CD,             9). %%最近有加入并退出过队伍，间隔时间太短
-define(TEAM_IN_WAR,             10). %%队伍战期间，不允许操作
-define(TEAM_FUNC_UNOPEN,        11). %%未开通队伍功能
-define(TEAM_NOT_LEADER,         12). %%你没有权限
-define(TEAM_INVALID_PLAYER,     13). %%对方玩家不存在
-define(TEAM_NOT_SAME_TEAM,      14). %%对方不是你的队伍成员
-define(TEAM_TO_SELF,            15). %%操作对象不能是自己
-define(TEAM_WRONG_STATE,        16). %%错误的状态或参数
%%-------------------------------------------------
-endif.
