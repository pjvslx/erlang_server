% 避免头文件多重包含
-ifndef(_ACTIVITY_HEADER_).
-define(_ACTIVITY_HEADER_, 0).

-define(SUCCESS, 1).				%%操作成功
-define(CONFIG_ERROR, 2).			%%配置出错 
-define(TARGET_NOT_FINISH, 3).		%%目标并未完成
-define(ALREADY_FETCH_VALUE, 4).	%%已经领取过活跃值
-define(ALREADY_REWARD, 5).			%%已经领取过奖励了
-define(POINT_NOT_ENOUGH, 6).		%%点数不够

-endif.  %% _ACTIVITY_HEADER_