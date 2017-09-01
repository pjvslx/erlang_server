% 避免头文件多重包含
-ifndef(_ACTIVITY_HEADER_).
-define(_ACTIVITY_HEADER_, 0).

%%---------------气泡类型----------------%%
-define(BUNBLE_FIGHT,    1).				%%战斗气泡
-define(BUNBLE_MAIL, 	 2).				%%邮件气泡
-define(BUNBLE_FRIEND,   3).				%%好友气泡
-define(BUNBLE_GUILD,    4).				%%帮派气泡
-define(BUNBLE_FLOWER,   5).				%%鲜花气泡
-define(BUBLE_GIFT,      6).				%%礼品气泡

-define(BUNBLE_FIGHT_SUB_LOST,		1).		%%[战斗]输掉战斗
-define(BUNBLE_FRIEND_SUB_INVITE,   1).		%%[好友]邀请加好友
-define(BUNBLE_GUILD_SUB_INVITE,    1).		%%[帮派]邀请加入帮派
-define(BUNBLE_GUILD_SUB_KICK,		2).		%%[帮派]踢出帮派
-define(BUNBLE_GUILD_SUB_ACTIVE,	3).		%%[帮派]帮派活动
-define(BUNBLE_GUILD_SUB_REQ,		4).		%%[帮派]帮派申请
-define(BUNBLE_FLOWER_SUB_RECV,     1).		%%[鲜花]收到鲜花
-define(BUNBLE_GIFT_SUB_RECV,		1).     %%[礼包]收到礼包

-endif.  %% _ACTIVITY_HEADER_