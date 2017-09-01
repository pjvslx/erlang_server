%%%-----------------------------------
%%% @Module  : lib_activity
%%% @Author  : ly
%%% @Created : 2013.09.28
%%% @Description: 活跃度
%%%-----------------------------------
-module(lib_activity).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("activity.hrl").
-compile(export_all).

%%处理活跃度加载
role_login(Status) ->
	case get_activity(Status#player.id) of
		[] ->
			open_activity(Status);
		Activity ->
			skip
	end.

%登出时活跃度卸载
role_logout(Status) ->
	ets:delete(?ETS_ACTIVITY,Status#player.id).

%获取活跃度信息 客户端协议获取
get_activity_info(Status) ->
	Activity = get_activity(Status#player.id),
	ActiveValue = Activity#activity.active_value,
	RewardList = Activity#activity.reward_cur,
	F1 = fun({RewardId,HasReward}) ->
		if
			HasReward == 1 ->
				[RewardId];
			true ->
				[]
		end
	end,
	
	NewRewardList = lists:map(F1, RewardList),
	{ActiveValue,Activity#activity.active_cur,NewRewardList}.
	

%完成单次的活跃度任务 (各模块调用)
finish_activity_single(Status,Btype,SType) ->
	Activity = get_activity(Status#player.id),
	Activity_cur = Activity#activity.active_cur,
	[TplActivity] = tpl_activity:get_by_btype_stype(Btype,SType),
	if
		TplActivity == [] ->
			skip;
		true ->
			TargetNum = TplActivity#temp_activity.target_num,
			ActiveId = TplActivity#temp_activity.id,
			%判断玩家是否曾经完成过  如果从来没完成过  则新添加记录 否则修改(若超过最大次数 则不予理会)
			case lists:keyfind(ActiveId, 1, Activity#activity.active_cur) of
				false ->
					%%没有查到
					NewActivity_cur = Activity_cur ++ [{ActiveId,1,0,0}],
					NewActivity = Activity#activity{active_cur = NewActivity_cur},
					ets:insert(?ETS_ACTIVITY,NewActivity),
					spawn(fun()->db_agent_activity:update_activity(NewActivity) end);
				{Id,CurTimes,HasReward,IsCritical} ->
					if
						CurTimes >= TargetNum ->
							skip;
						true ->
							NewCurTimes = CurTimes + 1,
							NewActivity_cur = lists:keyreplace(ActiveId, 1, Activity_cur, {ActiveId,NewCurTimes,HasReward,IsCritical}),
							NewActivity = Activity#activity{active_cur = NewActivity_cur},
							%%更新ETS 更新DB
						    ets:insert(?ETS_ACTIVITY, NewActivity),
							spawn(fun()->db_agent_activity:update_activity(NewActivity) end)	
					end
			end
				
	end.

%凌晨重置功能
refresh_midnight_data(Status) ->
	Activity = get_activity(Status#player.id),
	NewActivity = Activity#activity{active_cur = [],active_value = 0,reward_cur = []},
	ets:insert(?ETS_ACTIVITY, NewActivity),
	spawn(fun()->db_agent_activity:update_activity(NewActivity) end).
		

%领取活跃值(客户端交互)
get_activity_value(Status,Btype,Stype) ->
	Activity = get_activity(Status#player.id),
	Activity_cur = Activity#activity.active_cur,
	[TplActivity] = tpl_activity:get_by_btype_stype(Btype,Stype),
	if
		TplActivity == [] ->
			{?CONFIG_ERROR,0,0,Btype,Stype};%%错误提示？
		true ->
			ActiveId = TplActivity#temp_activity.id,
			TargetNum = TplActivity#temp_activity.target_num,
			%%判断当前完成次数是否等于目标次数
			case lists:keyfind(ActiveId, 1, Activity_cur) of
				false ->
					%%没查到记录 则肯定没完成
					{?TARGET_NOT_FINISH,0,0,Btype,Stype};
				{_, CurTimes, HasReward,IsCritical} ->
					if 
						CurTimes == TargetNum ->
							if
								HasReward == 0 ->
									NewHasReward = 1,
									%%写状态 计算领取到的活跃值
									Base = TplActivity#temp_activity.point,
									TestData = TplActivity#temp_activity.crit,
									[Chance,Critical] = TestData,
									FuckData = calc_active_value(TplActivity#temp_activity.point,Chance,Critical),
									{ActiveValue,ReallyCrit} = FuckData,
									NewActivity_cur = lists:keyreplace(ActiveId, 1, Activity_cur, {ActiveId,CurTimes,NewHasReward,ReallyCrit}),
									NewActivity = Activity#activity{active_cur = NewActivity_cur,active_value = Activity#activity.active_value + ActiveValue},
									ets:insert(?ETS_ACTIVITY, NewActivity),
									spawn(fun()->db_agent_activity:update_activity(NewActivity) end),
									{?SUCCESS,ReallyCrit,NewActivity#activity.active_value,Btype,Stype};
								true ->
									{?ALREADY_FETCH_VALUE,0,0,Btype,Stype}%已经领取的错误提示
							end;
						true ->
							%%如果都没有完成目标 则报未完成的错误提示
							{?TARGET_NOT_FINISH,0,0,Btype,Stype}	
					end
			end
							
	end.

%根据暴击率和暴击倍数计算领取的活跃值
calc_active_value(Base,Chance,Critical) ->
	CurRandNum = util:rand(1,10000),
	if
		CurRandNum > Chance ->
			{Base,0};
		true ->
			{Base*Critical,1}
	end.

%根据玩家的等级以及宝箱ID得出对应的RewardId
get_reward_id_by_level(Level,Type,Index,Length)->
	TplActivityReward = tpl_activity_reward:get(Index),
	ConfigType = TplActivityReward#temp_activity_reward.type,
	ConfigMinLevel = TplActivityReward#temp_activity_reward.min_level,
	ConfigMaxLevel = TplActivityReward#temp_activity_reward.max_level,
	if
		% ConfigMinLevel <= Level <= ConfigMaxLevel
		ConfigType == Type andalso (  Level >= ConfigMinLevel andalso Level =< ConfigMaxLevel ) ->
			TplActivityReward#temp_activity_reward.id;
		Index == Length ->
			-1;
		true ->
			get_reward_id_by_level(Level,Type,Index+1,Length)
	end.

get_reward_list_length(StartRewardId,Length) ->
	RewardInfo = tpl_activity_reward:get(StartRewardId),
	if 
		RewardInfo == [] ->
			Length;
		true ->
			NewStartRewardId = StartRewardId + 1,
			get_reward_list_length(NewStartRewardId,Length+1)
	end.
	

%领取奖励(客户端交互)
get_reward(Status,Type) ->
	DefaultLength = 0,
	StartRewardId = 1,
	RewardListLength = get_reward_list_length(StartRewardId,DefaultLength),
	RewardId = get_reward_id_by_level(Status#player.level,Type,1,RewardListLength),
	TplActivityReward = tpl_activity_reward:get(RewardId),
	Activity = get_activity(Status#player.id),
	if 
		TplActivityReward == [] ->
			?CONFIG_ERROR;%找不到对应RewardId的宝箱 错误提示？
		true ->
			%%判断当前活跃值是否满足
				if 
					Activity#activity.active_value >= TplActivityReward#temp_activity_reward.point ->
						%%点数充足 判断是否已经领取过
						Reward_cur = Activity#activity.reward_cur,
						case lists:keyfind(RewardId, 1, Reward_cur) of
							false ->
								%%写状态元祖 并领取奖励
								NewReward_cur = Reward_cur ++ [{RewardId,1}],
								NewActivity = Activity#activity{reward_cur = NewReward_cur},
								ets:insert(?ETS_ACTIVITY, NewActivity),
								spawn(fun()->db_agent_activity:update_activity(NewActivity) end),
								fetch_box_reward(Status#player.id,RewardId),
								?SUCCESS;
							{_, HasReward} ->
								?ALREADY_REWARD  %%已经领取过了 (错误提示?)
						end;
					true ->
						%%点数不够
						?POINT_NOT_ENOUGH %(错误提示)
				end
			
	end.

fetch_box_reward(PlayerId,RewardId) ->
	TplActiveReward = tpl_activity_reward:get(RewardId),
	GiftList = TplActiveReward#temp_activity_reward.gift,
	F = fun({ItemId,Num,Chance},List1) ->
		RandNum = util:rand(1,10000),
		if
			RandNum =< Chance ->
				List1 ++ [{0,ItemId,Num}];
			true ->
				List1
		end
	end,
	
	MailGoodsList = lists:foldl(F, [], GiftList),
	lib_mail:send_mail_to_one(PlayerId,1,16,MailGoodsList).

%每到凌晨12点 重刷(午夜重置)
refresh_timer(Status) ->
	skip.

%获取活跃度信息(内部使用)
get_activity(PlayerId) ->
	case ets:lookup(?ETS_ACTIVITY, PlayerId) of
		[] ->
			case db_agent_activity:get_activity(PlayerId) of
				[] ->
					[];
				Activity ->
					Activity
			end;
		[Activity] ->
			Activity
	end.

%开启活跃度系统 往数据库冲插入数据
open_activity(Status) ->
	Activity = #activity{uid = Status#player.id,active_cur = [],active_value = 0, reward_cur = []},
	ets:insert(?ETS_ACTIVITY, Activity),
	spawn(fun()->db_agent_activity:insert_activity(Activity) end).


	
	

