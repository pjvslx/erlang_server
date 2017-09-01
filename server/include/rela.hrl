%%%------------------------------------------------
%%% File    : rela.hrl
%%% Author  : water
%%% Created : 2013-02-01
%%% Description: 返回码定义
%%%------------------------------------------------

%%-------------------------------------------------
%% 关系模块 错误返回码
%%-------------------------------------------------
-define(RELA_UNKNOWN_ERROR, 21).          %%未知错误功能/好友模块未开通(如客户端错误行为或参数)
-define(RELA_ALREADY_FRIEND, 22).         %%已经是好友
-define(RELA_ALREADY_FOE, 23).            %%已经是仇人
-define(RELA_MAX_FRIEND_REACH, 24).       %%最大好友数达到
-define(RELA_MAX_FOE_REACH, 25).          %%最大仇人数达到
-define(RELA_IN_FOE_LIST, 26).            %%加仇人为好友
-define(RELA_IN_FRIEND_LIST, 27).         %%加好友为仇人
-define(RELA_INVALID_UID, 28).            %%非法的玩家ID
-define(RELA_NOT_FRIEND, 29).             %%不是好友
-define(RELA_NOT_FOE, 30).               %%不是仇人
-define(RELA_NOT_RECENT, 31).            %%不是最近联系人
-define(RELA_FRIEND_OFFLINE, 32).        %%好友不在线
-define(RELA_MAX_BLESS_TIMES_REACH, 33). %%祝福次数用完
-define(RELA_FRI_NOT_AVAILABLE, 34).      %%好友没有开通玩家模块
-define(RELA_INVALID_PLAYER,35).           %%无效玩家
-define(RELA_MAX_BLACK_REACH, 36).        %%最大黑名单人数达到
-define(RELA_ALREADY_BlACK, 37).         %%已经是黑名单了
-define(RELA_FLOWER_NOT_AVAILABLE,38).	 %%鲜花类型不合法
-define(RELA_FLOWER_NOT_ENOUGHT,39).	 %%鲜花数量不足
-define(RELA_OUT_OF_AVAILABLE,40).	 %%超过每天可免费送花次数     
-define(RELA_SEND_TO_MUCH,41).	 %%客户端发包太频繁
%%-------------------------------------------------

%-----------玫瑰种类-------------
-define(FLOWER_1,420004202).%1朵玫瑰
-define(FLOWER_9,420004203).%9朵玫瑰
-define(FLOWER_99,420004204).%99朵玫瑰
-define(FLOWER_999,420004205).%999朵玫瑰
-define(BIND_FLOWER_1,421004202).%1朵绑定玫瑰
-define(BIND_FLOWER_9,421004203).%9朵绑定玫瑰
-define(BIND_FLOWER_99,421004204).%99朵绑定玫瑰
-define(BIND_FLOWER_999,421004205).%999朵绑定玫瑰
-define(ALL_FLOWER_TYPE,%%所有鲜花类型
		[?FLOWER_1,?FLOWER_9,?FLOWER_99,?FLOWER_999,?BIND_FLOWER_1,?BIND_FLOWER_9,?BIND_FLOWER_99,?BIND_FLOWER_999]).
-define(ALL_NONE_BIND_FLOWER_TYPE,%%所有非绑定鲜花类型
		[?FLOWER_1,?FLOWER_9,?FLOWER_99,?FLOWER_999]).
%------------每天最大免费送玫瑰数--------
-define(DAILY_MAX_SEND_FLOWER,3).

-define(BIND_FLOWER_FLAG,1000000).

%------------自动购买-------------
-define(AUTO_BUY_FLOWER,1).

-define(NULL_AUTO_BUY_FLOWER,2).

-define(FLOWER_NPC,10000).

-define(FLOWER_NPC_PAGE,1).