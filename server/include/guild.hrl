%%------------------------------------------------
%% File    : guild.hrl
%% Author  : water
%% Created : 2013-02-19
%% Description: 帮派宏定义
%%------------------------------------------------
%% 避免头文件多重包含
-ifndef(__HEADER_GUILD__).
-define(__HEADER_GUILD__, 0).

%%-------------------------------------------------
%% 帮派错误返回码
%%-------------------------------------------------
-define(GUILD_ERROR,               0). %%系统繁忙
-define(GUILD_OK,                  1). %%成功
%%-define(GUILD_LEVEL_NOT_ENOUGH,    2). %%等级不够
-define(GUILD_COIN_NOT_ENOUGH,     3). %%铜币不够
-define(GUILD_GOLD_NOT_ENOUGH,     4). %%元宝不足
-define(GUILD_NAME_EXIST,          5). %%帮派名字已存在
-define(GUILD_NAME_INVALID,        6). %%帮派名字含特殊字符
-define(GUILD_TOO_FAST,            7). %%间隔时间太短
-define(GUILD_NOT_EXIST,           8). %%帮派不存在
-define(GUILD_NOT_IN_GUILD,        9). %%你不在任何帮派中
-define(GUILD_ALREAD_IN_GUILD,    10). %%您已加入了帮派
-define(GUILD_MEMBER_FULL,        11). %%帮派成员数量已满
-define(GUILD_APPLY_FULL,         12). %%帮派的申请人数已经超过上限
-define(GUILD_MAX_APPLY,          13). %%申请加入帮派个数已达上限
-define(GUILD_QUIT_CD,            14). %%最近有加入并退出过帮派，间隔时间太短
-define(GUILD_IN_WAR,             15). %%帮派战期间，不允许操作
-define(GUILD_FUNC_UNOPEN,        16). %%未开通帮派功能
-define(GUILD_PERMISSION_DENY,    17). %%你没有权限
-define(GUILD_INVALID_PLAYER,     18). %%对方玩家不存在
-define(GUILD_NOT_SAME_GUILD,     19). %%对方不是你的帮派成员
-define(GUILD_IN_ACCUSE,          20). %%弹劾期间，不允许操作
-define(GUILD_TO_SELF,            21). %%操作对象不能是自己
-define(GUILD_MONEY_NOT_ENOUGH,   22). %%帮派资金不足
-define(GUILD_CONTRIB_NOT_ENOUGH, 23). %%帮派贡献度不足
-define(GUILD_MAX_LEVEL,          24). %%已经是最高等级了
-define(GUILD_POS_EMPTY,          25). %%当前职务人数已满
-define(GUILD_ALREADY_VOTE,       26). %%已经投过票了
-define(GUILD_IN_WAR_ACCUSE,      27). %%弹劾/帮派战斗期间，不允许操作
-define(GUILD_WRONG_STATE,        28). %%错误的状态或参数
-define(GUILD_WRONG_POSITION,     29). %%提升时原职位不对
-define(GUILD_APPLY_NOT_EXIST,    30). %%申请不存在
-define(GUILD_MEMBERS_LIMIT,      31). %%帮派人数已满
-define(GUILD_REJECT_SUCCESS,     32). %%已经拒绝

-define(GUILD_LEVEL_NOT_ENOUGH,    50). %%等级不够
-define(GUILD_NAME_LEN_INVALID,    51). %%长度不超过4
-define(GUILD_CREATE_GUILD_GOOD_NOT_ENOUGH, 52). %%建帮令不足
-define(GUILD_APPY_GUILD_SUCCESS,  53). %%申请成功
-define(GUILD_HAS_APPIED_GUILD,    54). %%已经申请过该帮派
-define(GUILD_NOT_SAME_CAMP,       55).%%不同阵营

-define(GUILD_CAN_NOT_HANDLE_CHIEF,56).%%不能处理帮主
-define(GUILD_CAN_NOT_HANDLE_SELF,57).%%不能转让给自己
-define(GUILD_CAN_NOT_KICK_OUT_SELF,57).%%不能开除自己
-define(GUILD_CAN_NOT_KICK_OUT_CHIEF,58).%%不能开除帮主


-define(GUILD_YOU_HAVE_CREATED_GUILD,59). %%你已经创建了帮派，只能创建一个。
-define(GUILD_THIS_IS_FAILED,60). %%操作失败

%%-------------------------------------------------

%%职位定义
-define(GUILD_CHIEF, 1).          %% 1帮主
-define(GUILD_ASSIST_CHIEF, 2).   %% 2副帮主
-define(GUILD_HU_FA,3).           %% 3护法
-define(GUILD_ELITE, 4).          %% 4精英
-define(GUILD_NORMAL, 10).        %% 10-帮众

-endif.
