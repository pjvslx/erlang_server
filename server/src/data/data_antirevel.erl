%%%---------------------------------------
%%% @Module  : data_antirevel
%%% @Author  : water
%%% @Created : 2013-01-15
%%% @Description: 防沉迷配置
%%%---------------------------------------
-module(data_antirevel).
-compile(export_all).

%%获取防沉迷常量
get_antirevel_con(Atom) ->
	case Atom of
		act_time -> 10800;       %%防沉迷状态下可玩游戏时间（3*3600秒）
		warn_time1 -> 3600;      %%防沉迷1小时提醒（60*60秒）  忽略  + 5秒
		warn_time2 -> 7200;      %%防沉迷2小时提醒（120*60秒） 忽略  + 5秒
		warn_time3 -> 10500;     %%防沉迷到时前5分钟提醒（175*60秒）忽略  + 5秒
        off_time -> 5*3600;      %%防沉迷累计达到后再次登录要求离线时长
		_ -> err
	end.
