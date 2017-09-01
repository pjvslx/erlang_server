%%%------------------------------------
%%% @Author  : 
%%% @Created : 2010.09.27
%%% @Description: 角色处理
%%%------------------------------------
-module(mod_player). 
-behaviour(gen_server).
-include("common.hrl").
-include("goods.hrl").
-include("record.hrl").  
-include("debug.hrl").
-include("guild.hrl").
-export([code_change/3, handle_call/3, handle_cast/2, handle_info/2, init/1,terminate/2]).
-compile(export_all).

% 每5分钟存一次数据库
-define(SAVE_DB_TICK, 300000).
-define(EXP_BUFF,499).%%特定buffid,待配置

update_pet_battle_attr(Pid, BattleAttr) ->
	gen_server:cast(Pid, {update_pet_battle_attr, BattleAttr}).
  
%%启动角色主进程
start(PlayerId, AccountId, ResoltX, ResoltY ,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen, Socket) ->
    gen_server:start(?MODULE, [PlayerId, AccountId, ResoltX, ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm ,Screen, Socket], []).
 
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([PlayerId, _AccountId, ResoltX,ResoltY ,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen,Socket]) ->
	%%net_kernel:monitor_nodes(true),
	%eprof:start_profiling([self()]), %性能测试开关，非请勿用
	PlayerProcessName = misc:player_process_name(PlayerId),  
	try_2_unregister_pid(PlayerProcessName),
	misc:register(local, PlayerProcessName, self()),
	delete_ets_when_init(PlayerId),

	%%加载玩家数据和各种逻辑
	Status = load_player_info(PlayerId,ResoltX,ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen, Socket),
	%%io:format("Accname:~p ~n", [Status#player.account_name]),
	%%上线防沉迷处理
	%%online_antirevel(AccountId),   
	%%各种定时器 
	erlang:send_after(5*1000, self(),'CHECK_DUPLICATE_LOGIN'),    %% 5秒后检查重复登陆
	erlang:send_after(10*1000, self(), 'CHECK_EXPIRE_TIME'),
	%% 心跳包时间检测
	put(detect_heart_time, [0, ?HEART_TIMEOUT_TIME, []]),
	HeartTimer = erlang:send_after(?HEART_TIMEOUT, self(), 'check_heart_time'),
	put(check_heart_timer, HeartTimer),    
	%% 定时存数据库
	erlang:send_after(util:rand(?SAVE_DB_TICK-60000, ?SAVE_DB_TICK+60000), self(), 'SAVE_DB'),
	misc:write_monitor_pid(self(),?MODULE, {PlayerId}),
    
    %% TODO REUBEN 插入登陆日志
	%%spawn(fun()->db_agent_log:insert_log_login(PlayerId, Status#player.level, Status#player.account_name)end),
	HardWareInfo = Status#player.other#player_other.hardware_info,
	RoleId = Status#player.id,
	AccountName = Status#player.account_name,
	DimLevel = Status#player.level,
	UserIp = Status#player.last_login_ip,
	LoginSceneId = Status#player.scene,
	Os = HardWareInfo#hardware_info.os,
	OsVersion = HardWareInfo#hardware_info.os_version,
	Device = HardWareInfo#hardware_info.device,
	DeviceType = HardWareInfo#hardware_info.device_type,
	Screen = HardWareInfo#hardware_info.screen,
	Mno = HardWareInfo#hardware_info.mno,
	Nm = HardWareInfo#hardware_info.nm,

	OsDesc = config:get_client_os(Os),
    DeviceTypeDesc = config:get_client_device_type(DeviceType),
    MnoDesc = config:get_client_isp(Mno),
    NmDesc = config:get_client_net_type(Nm),

	spawn(fun()->db_agent_log:insert_log_login(RoleId, AccountName, DimLevel, UserIp, LoginSceneId, OsDesc, OsVersion, Device, DeviceTypeDesc, Screen, MnoDesc, NmDesc)end),
    erlang:send_after(?BUFF_TIMER_TIME, self(), 'BUFFER_TIMER'),
    if
        Status#player.vip > 0 ->
            NowTime = util:unixtime(),
            SendStatus = db_agent_mail:checkMailSendStatus(Status#player.id,15),
            if
                SendStatus =:= false ->
                    if
                        Status#player.vip_expire_time < NowTime ->
                            lib_mail:send_mail_to_one(Status#player.id,1,15,[]);%%检查玩家VIP是否过期(过期则发邮件通知玩家)
                        Status#player.vip_expire_time - NowTime =< 3600*24 ->
                            erlang:send_after((Status#player.vip_expire_time - NowTime)*1000, self(), 'VIP_TIMER');
                        true ->
                            skip
                    end;
                true ->
                    skip
            end;
        true ->
            skip
    end,
	%%?TRACE("DEBUG LOGIN"),
	%%?TRACE("[DEBUG] LOGIN ~p ~n", [{RoleId, AccountName, DimLevel, UserIp, LoginSceneId, Os, OsVersion, Device, DeviceType, Screen, Mno, Nm}]),
	{ok, Status} .

%%初始化玩家硬件信息 Player,ResoltX, ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm
init_player_hardwareinfo(Ps,Screen,Os,OsVersion,Device,DeviceType,Mno,Nm)->
  NewPlayerOther = Ps#player.other#player_other{
												  hardware_info = #hardware_info{
																				 os = Os, 
																				 os_version = OsVersion, 
																				 device = Device, 
																				 device_type = DeviceType, 
																				 screen = Screen, 
																				 mno = Mno, 
																				 nm = Nm  				 
																				}
												 },
	Ps#player{
			  other = NewPlayerOther
			 }.

%% 路由
%% cmd:命令号
%% Socket:socket id
%% data:消息体
-ifdef(debug).
	routing(Cmd, Status, Bin) -> 
%%     		 try
			routing2(Cmd, Status, Bin).
%% 		 catch
%% 		 	Err:Reason ->
%% 		 		?ERROR_MSG("处理消息[~p]出异常：~w", [Cmd, {Err, Reason, erlang:get_stacktrace()}]),
%% 		 		ErrMsg = io_lib:format("处理消息[~p]出异常：~p", [Cmd, {Err, Reason, erlang:get_stacktrace()}]),
%% 		 		{ok, BinData} = pt_11:write(11099, ErrMsg),
%% 		 		lib_send:send_one(Status#player.other#player_other.socket, BinData),
%% 		 		{error, "handle cmd error"}
%% 		 end.
-else.
	routing(Cmd, Status, Bin) -> 
		 try
			routing2(Cmd, Status, Bin)
		 catch
		 	Err:Reason ->
		 		?ERROR_MSG("处理消息[~p]出异常：~p", [Cmd, {Err, Reason, erlang:get_stacktrace()}]),
		 		{error, "handle cmd error"}
		 end.
-endif.

routing2(Cmd, Status, Bin) -> 
	%case Cmd >= 15000 of
	%	true ->	?TRACE("Cmd:~p Bin:~p ~n", [Cmd, Bin]);
	%	false -> skip
	%end,
    %%取前面二位区分功能类型
    [H1, H2, _, _, _] = integer_to_list(Cmd), 
    case [H1, H2] of
        %%游戏基础功能处理  
        "10" -> pp_base:handle(Cmd, Status, Bin);
		"11" -> pp_chat:handle(Cmd, Status, Bin);
        "12" -> pp_scene:handle(Cmd, Status, Bin);
        "13" -> pp_player:handle(Cmd, Status, Bin);
        "14" -> pp_relation:handle(Cmd, Status, Bin);
        "15" -> pp_goods:handle(Cmd, Status, Bin);
        "18" -> pp_notice:handle(Cmd, Status, Bin);
        "19" -> pp_mail:handle(Cmd, Status, Bin);
        "20" -> pp_battle:handle(Cmd, Status, Bin);
        "21" -> pp_skill:handle(Cmd, Status, Bin);
        "22" -> pp_buff:handle(Cmd, Status, Bin);
		"23" -> pp_dungeon:handle(Cmd, Status, Bin);
		"25" -> pp_pet:handle(Cmd, Status, Bin);
        "26" -> pp_business_activity:handle(Cmd, Status, Bin);
        "30" -> pp_task:handle(Cmd, Status, Bin);
		"31" -> pp_activity:handle(Cmd, Status, Bin);
        "34" -> pp_system_config:handle(Cmd, Status, Bin); 
        "35" -> pp_team:handle(Cmd, Status, Bin); 
        %"36" -> pp_boss:handle(Cmd, Status, Bin);
        "40" -> pp_guild:handle(Cmd, Status, Bin);
        "41" -> pp_market:handle(Cmd, Status, Bin);
        "44" -> pp_mount:handle(Cmd, Status, Bin);
		"45" -> pp_meridian:handle(Cmd, Status, Bin);
		"50" -> pp_rank:handle(Cmd, Status, Bin);
        "60" -> pp_gateway:handle(Cmd, Status, Bin);
		"16" -> pp_camp:handle(Cmd, Status, Bin);
		"17" -> pp_leader:handle(Cmd, Status, Bin);
        _ -> %%错误处理
            ?ERROR_MSG("Routing Error [~w].", [Cmd]),
            {error, "Routing failure"}
    end.  

%%处理socket协议 (cmd：命令号; data：协议数据)

%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, Status) -> 
	Reply  = ?APPLY(Module, Method, Args,[]),
    {reply, Reply, Status};

handle_call({'SOCKET_EVENT', Cmd, Bin}, _From, Status) ->  
	case routing(Cmd, Status, Bin) of
		{ok, Status1} ->                           %% 修改ets和status  
			save_online(Status1), 
			%%save_online_diff(Status,Status1),
			{reply, ok, Status1};
		{ok, change_ets_table, Status1} ->         %% 修改ets、status和table
			save_online_diff(Status,Status1),            
			save_player_table(Status1, Cmd),
			{reply, ok, Status1};
		{ok, change_status, Status2} ->            %% 修改status
			{reply, ok, Status2};
		{ok,change_online,Status3} ->
			ets:insert(?ETS_ONLINE, Status3) ,
			{reply, ok, Status3};
		_ -> 
			{reply, ok, Status}
	end; 

%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, Status) -> 
	Reply  = ?APPLY(Module, Method, Args,[]),
    {reply, Reply, Status};

	
%%获取用户信息
handle_call('PLAYER', _from, Status) ->
    {reply, Status, Status};

%%获取用户信息(按字段需求)
handle_call({'PLAYER', List}, _from, Status) ->
    Reply = lib_player_rw:get_player_info_fields(Status, List),
    {reply, Reply, Status};
%%收花通知
handle_call({get_flower, FriendId, FlowerNum},_from,Status)->
	NewFlower = lib_relation:do_receive_flower(FriendId,FlowerNum,Status),
	 {reply, NewFlower, Status};

handle_call(Event, From, Status) ->
   ?ERROR_MSG("mod_player_call: /~p/~n",[[Event, From, Status]]),
   {reply, ok, Status}.

%%非法上线的玩家重新上线时重新加载上次的玩家信息
handle_cast({reload_player_data,PlayerId, _, _, _, Socket},Status)->  
	if Status#player.id =/= PlayerId ->
		   {stop, normal, Status};
	   true ->
		   cancel_player_timer(),
		   [PidSend] = Status#player.other#player_other.pid_send,
		   gen_server:cast(PidSend, {reset_socket,Socket}), 
		   NewPlayerOther =  Status#player.other#player_other{socket = Socket},
		   {noreply, Status#player{
								   other = NewPlayerOther 
								  }}
	end;

handle_cast(update_force,Status) ->   
	NewStatus0 = lib_player:calc_player_battle_attr(Status), 
	NewStatus1 = lib_player:calc_player_force(NewStatus0), 
	lib_player:send_player_attribute1(NewStatus1),  
	{noreply,NewStatus1};

%%凌晨操作
handle_cast(midnight, Status) ->
    ?TRACE("midnight operations~n"),  
    lib_task:init_task_module(Status),%%重新初始化任务模块
	lib_activity:refresh_midnight_data(Status),
	rank_util:call_client_2_reflesh_rank(Status),
    NewStatus= check_vip(Status),
    {noreply, NewStatus};

%%给玩家发送奖励
handle_cast({add_coin_exp, Coin, BCoin, BGold, Exp}, Status) -> 
    Status1 = lib_player:add_money(Status, Coin, BCoin, 0, BGold),
    if Exp > 0 ->
            NewStatus = lib_player:add_exp(Status1, Exp, 0) ,
            lib_player:send_player_attribute1(NewStatus),
            {noreply, NewStatus};
       true ->
            %%发送消息更新
            {noreply, Status1}
    end;


%%给玩家增加经验
handle_cast({add_exp, Exp}, Status) -> 
    if Exp > 0 ->
            NewStatus = lib_player:add_exp(Status, Exp, 0),
            lib_player:send_player_attribute1(NewStatus),
            {noreply, NewStatus};
       true ->
            %%发送消息更新
            {noreply, Status}
    end;

%%给玩家发送奖励
handle_cast({add_goods, GoodsList, Source}, Status) ->  
	NewStatus = goods_util:send_goods_and_money(GoodsList, Status, Source),
	Fields = record_info(fields,player),
	OldValueList = lib_player_rw:get_player_info_fields(Status,Fields),
	NewValueList = lib_player_rw:get_player_info_fields(NewStatus,Fields),
	KeyValue = get_diff_val(OldValueList,NewValueList,Fields),
	if
		length(KeyValue) > 0 ->  
			lib_player:send_player_attribute4(NewStatus) ;
		true ->
			skip
	end ,	 
 	{noreply, NewStatus};

%%刷新玩家战斗属性
handle_cast(refresh_battle_attr, Status) ->
   Status1 = lib_player:calc_player_battle_attr(Status),
   {noreply, Status1};

% 战斗操作hp
handle_cast({reducehpmp, HP}, Status) ->
    OldBattleAttr = Status#player.battle_attr,
    CurrentHP = max(0, OldBattleAttr#battle_attr.hit_point - HP),
    NewBattleAttr = OldBattleAttr#battle_attr{hit_point = CurrentHP},
    NewStatus = Status#player{battle_attr = NewBattleAttr},
	%%io:format("====mod_playe reducehpmp,playerid:~p  hp:~p, CurrentHP:~p ~n", [Status#player.id, HP, CurrentHP]),
	case CurrentHP > 0 of
		true ->
			update(NewStatus) ;
		_ ->	%死亡/状态改变时再同步到地图
			save_online(NewStatus)
	end,
	{noreply, NewStatus};
%%改变玩家战斗状态
handle_cast({change_battle_status,NewBattleState,NewEnergy},Ps)-> 
	NewStatus = case Ps#player.status =:= NewBattleState of
					true ->
						Ps;
					false -> 
						BattleAttr = Ps#player.battle_attr#battle_attr{
																	   energy = NewEnergy
																	  }, 
						TempPs	= Ps#player{status = NewBattleState,battle_attr = BattleAttr},
						save_online(TempPs),
						TempPs
				end,
	{noreply, NewStatus};
%% 战斗回写数据，适用于各种场景的战斗
%% 战斗回写数据，适用于各种场景的战斗
handle_cast({battle_callback, DamageHp, BattleAttr,NewBattleStatus,AttrId,AttrType,CallBackFlag}, Status) ->
	OldBattleAttr = Status#player.battle_attr, 
	{NewDemageRedunction,NewDamageHp,NewDamageReductionQueue,BrocastFlag} = battle_util:defend_redunction_call_back(OldBattleAttr#battle_attr.damage_reduction,DamageHp,OldBattleAttr#battle_attr.damage_reduction_queue), 
	CurrentHP = max(0, OldBattleAttr#battle_attr.hit_point - NewDamageHp),
	NewBattleAttr = BattleAttr#battle_attr{hit_point = CurrentHP,damage_reduction = NewDemageRedunction,damage_reduction_queue = NewDamageReductionQueue},
	{_,_,_,Effect} = NewDemageRedunction,
	buff_util:brocast_new_damage_reduction_effect(Status,NewBattleAttr,Effect,BrocastFlag),
	NewStatus0 = Status#player{battle_attr = NewBattleAttr,status = NewBattleStatus},
	NewStatus = lib_skill:remove_all_skill_buffer_when_dead(NewStatus0),
	case CallBackFlag of
		?HURT_CALL_BACK ->
			Now = util:longunixtime(),
			NewBattleAttr1 = lib_skill:reflesh_hurted_trigger_buff(NewStatus#player.battle_attr,Now),  
			FinalStatus = NewStatus#player{
										   battle_attr = NewBattleAttr1},    
			lists:foreach(fun({SkillId,SkillLv,_})->
								  lib_skill:buff_trigger_single_skill(FinalStatus,AttrId,AttrType,SkillId,SkillLv,Now)
						  end,NewBattleAttr1#battle_attr.hurted_buff),
			mod_scene:passive_hurt_call_back(AttrId,AttrType,DamageHp,FinalStatus);
		?HURT_NOT_CALL_BACK->
			FinalStatus = NewStatus
	end,
	save_online(FinalStatus),
	{noreply, FinalStatus};
%%宠物战斗后回写宠物战斗属性数据
handle_cast({pet_fight_call_back,SelfBuff,SkillLv,PetBattleAttr},Status)->
	{NewPetBattleAttr,_ } = lib_skill:update_attack_battle_attr(SelfBuff, SkillLv, PetBattleAttr),
	case lib_common:get_ets_info(?ETS_PET_INFO, Status#player.id) of
		PetInfo when is_record(PetInfo, pet)->
		 	lib_common:insert_ets_info(?ETS_PET_INFO, PetInfo#pet{battle_attr = NewPetBattleAttr});
		_->
			skip
	end,
	{noreply, Status}; 
handle_cast({'save_dungeon_reward',DunRewards}, Status) ->
	put(dungeon_rewards,DunRewards) ,
	{noreply, Status}; 

%% 战斗回写数据，适用于各种场景的战斗
handle_cast({update_pet_battle_attr, BattleAttr}, Status) ->
	 case lib_common:get_ets_info(?ETS_PET_INFO, Status#player.id) of
		{} ->
			skip;
		 PetInfo -> 
		    OldBattleAttr = PetInfo#pet.battle_attr,
		    NewBattleAttr = OldBattleAttr#battle_attr{skill_cd_all = BattleAttr#battle_attr.skill_cd_all,
													  skill_cd_list = BattleAttr#battle_attr.skill_cd_list,
													  skill_buff = BattleAttr#battle_attr.skill_buff ,
													  buff1 = BattleAttr#battle_attr.buff1 ,
													  buff2 = BattleAttr#battle_attr.buff2},
		    NewPetInfo = PetInfo#pet{battle_attr = NewBattleAttr},
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo)
	 end,
	{noreply, Status};

%%停止角色进程(Reason 为停止原因)
handle_cast({stop, Reason}, Status) -> 
    if Reason =:= ?PLAYER_EXIT_UNORMAL andalso Status#player.status =:= ?PLAYER_BATTLE_STATE->
            NewStatus = do_unnormal_offline(Status),
            {noreply, NewStatus};
        true->
            {ok, BinData} = pt_10:write(10007, 0), %%Reason
            lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
            {stop, normal, Status}
    end;
%%主动退出
handle_cast(stop, Status) ->
    {stop, normal, Status};

%%设置用户信息
handle_cast({'SET_PLAYER', NewStatus}, _Status) when is_record(NewStatus, player)->
    %%put(last_msg, [{'SET_PLAYER', NewStatus}]),%%监控记录接收到的最后的消息
    save_online_diff(_Status,NewStatus),
    {noreply, NewStatus};

%%设置用户信息(按字段+数值)
handle_cast({'SET_PLAYER', List}, Status) when is_list(List)->
    NewStatus = lib_player_rw:set_player_info_fields(Status, List),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};

%%发送信息到socket端口
handle_cast({send_to_sid, Bin}, Status) ->
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, Bin),
    {noreply, Status};

%%设置禁言 或 解除禁言
handle_cast({set_donttalk, BeginTime, DurationSeconds}, Status) ->
    put(donttalk, [BeginTime, DurationSeconds]),
    {noreply, Status};    
 
handle_cast(add_adore,Status)->
	db_agent_player:add_player_adore(Status#player.id),
	NewStatus = Status#player{adore_count =Status#player.adore_count+1},
	save_online(NewStatus),
	{noreply, NewStatus};    

% 场景的PID改变了
handle_cast({change_pid_scene, NewScenePId, SceneId}, Status) ->
	%%put(last_msg, [{change_pid_scene, NewScenePId, SceneId}]),%%监控记录接收到的最后的消息
	if Status#player.other#player_other.pid_scene=/= undefined, 
		 Status#player.other#player_other.pid_scene =/= NewScenePId,
		 Status#player.scene == SceneId ->
					ok;
	   true -> no_action
	end,
	NewStatus = Status#player{other=Status#player.other#player_other{pid_scene = NewScenePId}},
    {noreply, NewStatus};

%%处理好友添加请求
handle_cast({add_friend_request, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel}, Status) ->
    lib_relation:put_request_uids([RequestUid]),  %%把请求的玩家ID存起来, 同意好友请求需要判断
    {ok,BinData} = pt_14:write(14012, [[[RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel]]]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
    {noreply, Status};

%%响应好友添加请求
handle_cast({add_friend_response, FriendId, FriendName, FriendCareer, FriendGender}, Status) ->
    lib_relation:add_to_friend_list(Status, {FriendId, FriendName, FriendCareer, FriendGender}),
    {noreply, Status};

%%好友祝福
handle_cast({bless, Type, Uid, Name}, Status) ->
    {ok,BinData} = pt_14:write(14022, [Uid, Name, Type]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
    {noreply, Status};

%%增加Buff
handle_cast({add_goods_buff, BuffId}, Status) ->
    case buff_util:add_goods_buff(Status, BuffId) of
           {add, NewStatus} -> %新加的Buff成功了
                save_online_diff(Status,NewStatus),
                {noreply, NewStatus};
           {replace, NewStatus} -> %加成功,冲掉了旧的Buff
                save_online_diff(Status,NewStatus),
                {noreply, NewStatus};
            _ ->
                {noreply, Status}
    end;
    
%%强制移除Buff
handle_cast({remove_goods_buff, BuffId}, Status) ->
    NewStatus = buff_util:remove_goods_buff(Status, BuffId),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};

%%为玩家赠送物品
%%任务模块特用的接口
handle_cast({give_present,ItemList, TaskId},Status)->
	case lib_task:do_player_get_goods(ItemList,Status) of
		NewStatus when is_record(NewStatus, player)->
	    	save_online_diff(Status,NewStatus),
			%%
			NewStatus2 = lib_task:open_func_system(TaskId, NewStatus),
			{noreply, NewStatus2};
		_->
			?ERROR_MSG("give present to player error good is ~p ~n",[ItemList]),
			{noreply, Status}
	end; 
%%加入了帮派
handle_cast({join_guild, GuildId, GuildName, Position}, Status) ->
    NewStatus = Status#player{guild_id = GuildId, guild_name = GuildName, guild_post = Position},
   
    %%{ok, BinData} = pt_40:write(40078, [GuildId, GuildName]),

     pp_player:pack_and_send(NewStatus, 13021, [NewStatus#player.guild_id,NewStatus#player.guild_name,NewStatus#player.guild_post]),

    %%lib_send:send_to_sid(NewStatus#player.other#player_other.pid_send, BinData),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};
  
%%帮派职位变更
handle_cast({guild_post, Position}, Status) ->
    NewStatus = Status#player{guild_post = Position},
	pp_player:pack_and_send(NewStatus, 13021, [NewStatus#player.guild_id,NewStatus#player.guild_name,NewStatus#player.guild_post]),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};

%%退出帮派
handle_cast({quit_guild}, Status) ->
    NewStatus = Status#player{guild_id = 0, guild_name ="", guild_post = 0},
    pp_player:pack_and_send(NewStatus, 13021, [NewStatus#player.guild_id,NewStatus#player.guild_name,NewStatus#player.guild_post]),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};

%%更新帮派申请信息
handle_cast({new_guild_apply}, Status) ->
    pp_guild:handle(40031, Status, 0),
    {noreply, Status};

%%更新组队信息
handle_cast({update_team, TeamId, TeamLeader}, Status) ->
    NewStatus = Status#player{other = Status#player.other#player_other{team_id = TeamId, team_leader = TeamLeader}},
    save_online_diff(Status, NewStatus),
    {noreply, Status};
%%主动攻击后更新玩家信息
handle_cast({save_battle_attr,BattleAttr,BattleStatus}, Status) ->
	NewStatus = Status#player{
							  battle_attr = BattleAttr,
							  status = BattleStatus
							  }, 
	 save_online(NewStatus),
    {noreply, NewStatus}; 
%%更新玩家信息->ets表
handle_cast({save_online,NewState}, _) ->
  	 save_online(NewState),
    {noreply, NewState}; 

%%buff回调,触发buff后续技能 
handle_cast({battle_buff_callback,AttrInfo,BuffList,RepelList,SkillInfo,NowLong}, Ps) ->    
	{_,SkillLv,_} = SkillInfo,  
	{_AttrType,_AttrId,AttrBattle} = AttrInfo,
	MapId = Ps#player.scene div 100,    
	{NewBattleAttr0,RepelInfo} = battle_util:do_repel(MapId,AttrBattle,Ps#player.battle_attr,RepelList,[]),
	{NewBattleAttr1,{_TotalDamage,DemageInfo}} = buff_util:apply_damage_buff(AttrBattle,NewBattleAttr0,NewBattleAttr0#battle_attr.demage_buff_list,SkillInfo,{0,[]}),	
	{NewBattleAttr2,BuffInfo} = buff_util:active_skill_buff(NewBattleAttr1,SkillLv,BuffList, NowLong), 
	if NewBattleAttr2#battle_attr.remove_buff_list =/= [] ->
		   self()!'remove_skill_buffer_by_id';
	   true ->
		   skip
	end,
	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->     
			buff_util:broadcast_new_skill_buff_in_dungeon(?ELEMENT_PLAYER,Ps#player.id,Ps#player.other#player_other.pid_send, NewBattleAttr2,RepelInfo++BuffInfo++DemageInfo);
		false ->   
			gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast, buff_util, broadcast_new_skill_buff, [Ps#player.scene,?ELEMENT_PLAYER,Ps#player.id,NewBattleAttr2,RepelInfo++BuffInfo++DemageInfo]})
	end,   
	{NewBattleAttr3,LinkSkill} = lib_skill:start_trigger_buff_skill(NewBattleAttr2,SkillLv),  
	NewBattleAttr4 = lib_skill:start_timer_buffer(NewBattleAttr3),
	NewPs = Ps#player{battle_attr = NewBattleAttr4}, 
	lib_skill:trigger_link_skill(NewPs,LinkSkill,0,-1), 
	save_online(NewPs), 
	{noreply, NewPs};  

%%开启阵营系统
handle_cast(open_camp,Status)->
	NewStatus =	if Status#player.switch band ?SW_CAMP_BIT =/= ?SW_CAMP_BIT ->  
					   pp_camp:pack_and_send(Status, 16001, [])  ,
					   Status#player{camp = 0,switch = Status#player.switch bor ?SW_CAMP_BIT};
				   true -> 
					   Status
				end,
	save_online(NewStatus),
	{noreply, NewStatus};

%%开启宠物
handle_cast(open_pet, Status)->
	case lib_pet:create_pet(Status) of
		{fail, _} ->
			{noreply, Status};
		{ok, NewPS} ->
			io:format("[DEBUG] save new PS successfull ~p ~n", [NewPS#player.other#player_other.pet_status]),
			save_online(NewPS),
			{noreply, NewPS}
	end;


%%开启坐骑系统
handle_cast(open_mount,Status)->
	NewStatus = lib_mount:open_mount(Status),
	save_online(NewStatus),
	{noreply, NewStatus};
%%开启经脉系统
handle_cast(open_meridian,Status)-> 
	NewStatus =	if Status#player.switch band ?SW_MER_BIT =/= ?SW_MER_BIT ->   
					   lib_meridian:open_meridian(Status);
				   true -> 
					   Status
				end,
	save_online(NewStatus),
	{noreply, NewStatus};
%%充值
handle_cast(charge, Status) ->
	NewStatus = lib_player:handle_charge_order(Status),
	save_online_diff(Status,NewStatus),
	lib_player:send_player_attribute3(NewStatus),
	{noreply, NewStatus};

%%进入特殊副本
handle_cast(enter_dungeon_exp,Status)->
	NewStatus = lib_player:join_2_level(Status,99,false),
	gen_server:cast(Status#player.other#player_other.pid, {add_goods_buff,?EXP_BUFF}), %%副本buff待配置
	NewStatus2 = case lib_pet:create_pet_temp(NewStatus) of 
		{fail, _} ->
			NewStatus;
		{ok, NewStatus1} ->
			NewStatus1
	end,
	save_online(NewStatus2),
	{noreply, NewStatus2};

%%离开特殊副本
handle_cast({leave_dungeon_exp,PreAttr},Status)-> 
	Status0 = case PreAttr of
		[Level] ->
			lib_player:join_2_level(Status,Level,true);
		_ ->
			Status
	end,
	%%gen_server:cast(Status#player.other#player_other.pid, {remove_goods_buff,235}),
    Status1 = buff_util:remove_goods_buff(Status0, ?EXP_BUFF),	%%副本buff待配置
	Status2 = case lib_pet:del_pet_temp(Status1) of
		{fail, _} ->
			Status1;
		{ok,NewStatus2} ->
			NewStatus2
	end,
    lib_player:send_player_attribute1(Status2), 
	lib_skill:clean_all_skill(Status2),
	save_online(Status2),
	{noreply, Status2};


handle_cast(Event, Status) ->
   ?ERROR_MSG("mod_player_cast: /~p/~n",[[Event, Status]]),
   {noreply, Status}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 发送信息到socket端口
handle_info({send_to_sid, Bin}, Status) ->
   lib_send:send_to_sid(Status#player.other#player_other.pid_send, Bin),
   {noreply, Status};
%buff计时器
handle_info('BUFFER_TIMER',Ps)->
	misc:cancel_timer(?SKILL_TIMER_KEY), 
	Now = util:longunixtime(),    
	{NewBattleAttr1,RemoveBuff,RefleshBuff} = lib_skill:do_check_buff(Ps#player.battle_attr,Now),
	{NewBattleAttr2,SkillList} = lib_skill:reflesh_timer_skill_info(NewBattleAttr1,[],Ps#player.battle_attr#battle_attr.timer_buff,Now),  
 	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->   
			buff_util:broadcast_reflesh_skill_buff_in_dungeon
			  (?ELEMENT_PLAYER, Ps#player.id,Ps#player.other#player_other.pid_send,NewBattleAttr2,RefleshBuff,RemoveBuff);
		false->
			gen_server:cast(mod_scene_agent:get_agent_pid(),
							{apply_cast, buff_util, broadcast_reflesh_remove_skill_buff, 
							 [Ps#player.scene,?ELEMENT_PLAYER,Ps#player.id,NewBattleAttr2,RefleshBuff,RemoveBuff]})
	end,            		 
	NewPs = Ps#player{battle_attr = NewBattleAttr2},
	if NewBattleAttr2#battle_attr.buff_timer_start =/= false andalso NewBattleAttr2#battle_attr.hit_point > 0 -> 
		   ?TRACE("[BUFFER_TIMER] continue trigger skill buff timer ~n",[]),
		   NextTimer =  erlang:send_after(?BUFF_TIMER_TIME, self(), 'BUFFER_TIMER'),
		   put(?SKILL_TIMER_KEY,NextTimer);
	   true ->
		   ?TRACE("[BUFFER_TIMER] trigger buff skill timer stop ~n",[]),
		   skip
	end,   
	save_online(NewPs), 
	lib_skill:trigger_link_skill(NewPs,SkillList,0,-1),  
	FinalPs = lib_skill:remove_all_skill_buffer_when_dead(NewPs),
	{noreply,FinalPs}; 
%vip计时器
handle_info('VIP_TIMER',Ps)->
    pp_player:pack_and_send(Ps, 13008, [-1,0,0,0]),%%通知前端vip失效
    lib_mail:send_mail_to_one(Ps#player.id,1,15,[]),%%检查玩家VIP是否过期(过期则发邮件通知玩家)
    {noreply,Ps};

%%删除过期坐骑外观
handle_info('delete_mount_fashion',Ps)->
	lib_player:send_tips(1402024, [], Ps#player.other#player_other.pid_send),
	NewPs = lib_mount:del_fashion(Ps),
	{noreply,NewPs}; 
%%静态buff计时器
handle_info({'REFLESH_BUFF_EFFECT',ExpriexTime},Ps)->     
	buff_util:delete_buff_timer(ExpriexTime),        
	{NewBattleAttr,RemoveBuff,RefleshBuff} = lib_skill:do_check_buff(Ps#player.battle_attr,ExpriexTime),
	lib_pet:reflesh_pet_buff(Ps#player.id,ExpriexTime),
	case lib_scene:is_dungeon_scene(Ps#player.scene) of  
		true ->   
			buff_util:broadcast_reflesh_skill_buff_in_dungeon
			  (?ELEMENT_PLAYER, Ps#player.id,Ps#player.other#player_other.pid_send,NewBattleAttr,RefleshBuff,RemoveBuff); 
		false->
			gen_server:cast(mod_scene_agent:get_agent_pid(), 
							{apply_cast, buff_util, broadcast_reflesh_remove_skill_buff,
							  [Ps#player.scene,?ELEMENT_PLAYER, Ps#player.id,NewBattleAttr,RefleshBuff,RemoveBuff]})
	end,
	NewPs = Ps#player{battle_attr = NewBattleAttr},	
	save_online(NewPs), 
	{noreply,NewPs};
%%检查是否有重复登陆
handle_info('CHECK_DUPLICATE_LOGIN',Player)->
    PlayerProcessName = misc:player_process_name(Player#player.id),
	case misc:whereis_name({local,PlayerProcessName}) of
        Pid when is_pid(Pid)->
            case misc:is_process_alive(Pid) of
                true  ->
                    Self = self(),
                    if Pid /= Self ->
                            mod_login:logout(self(), 1);
                       true ->
                           skip
                    end;
                flase ->
                    skip
            end;
        _E ->
            skip
    end,
    {noreply,Player};

%% 防沉迷信息播报
handle_info({'ALART_REVEL', Min}, Status) ->
    Accid = Status#player.account_id,
    Idcard_status = db_agent:get_idcard_status(Accid),
    case Idcard_status of
        1 -> {noreply, Status};
        _ ->
            case Min of
                60 ->
                    {ok, BinData} = pt_29:write(29001, 1),
                    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
                120 ->
                    {ok, BinData} = pt_29:write(29001, 2),
                    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
                _ ->
                    {ok, BinData} = pt_29:write(29001, 3),
                    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData)
            end,
            {noreply, Status}
    end;
%%根据buffer_id移除指定buff
handle_info('remove_skill_buffer_by_id',Ps)->
	NewPs = buff_util:remove_skill_buff_by_id(Ps),
	{noreply, NewPs};

%% 防沉迷强制退出
handle_info('FORCE_OUT_REVEL', Status) ->
    Accid = Status#player.account_id,
    Idcard_status = db_agent:get_idcard_status(Accid),    
    case Idcard_status of
        1 -> {noreply, Status};
        _ ->
            mod_login:logout(Status#player.other#player_other.pid, 5),
            {noreply, Status}
    end;

%%设置用户信息(按字段+数值)
handle_info({'SET_PLAYER_INFO', List}, Status) when is_list(List) ->
    NewStatus = lib_player_rw:set_player_info_fields(Status, List),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};
 
%%判断是否死游客
handle_info({check_static_player,[Scene, X, Y, Counter]}, Status) ->
    if [Status#player.scene, Status#player.battle_attr#battle_attr.x, Status#player.battle_attr#battle_attr.y] == [Scene, X, Y] ->
       if Counter >= 30 -> %%9级以下，30分钟都不移动, 则做退出处理
           {ok, BinData} = pt_10:write(10007, 6),
           lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
           {stop, normal, Status};
       true ->
           erlang:send_after(60*1000, self(),
           {check_static_player, [Status#player.scene, Status#player.battle_attr#battle_attr.x,Status#player.battle_attr#battle_attr.y, Counter+1]}),
           {noreply, Status}
       end;
    true -> 
       {noreply, Status}
    end;

%%心跳数据检测
handle_info('check_heart_time', Status) ->
    misc:cancel_timer(check_heart_timer),
    [_PreTime, Num, _TimeList] = get(detect_heart_time),
    if Num > 0 ->
           put(detect_heart_time, [0, Num-1, []]),
           HeartTimer = erlang:send_after(?HEART_TIMEOUT, self(), 'check_heart_time'),
           put(check_heart_timer, HeartTimer),
           {noreply, Status};
       true ->
           Now = util:unixtime(),
           NewTimeListStr = "",
           spawn(fun()-> db_agent_log:insert_kick_off_log(Status#player.id, Status#player.nick, 7, Now, 
                                                          Status#player.scene, Status#player.battle_attr#battle_attr.x, 
                                                          Status#player.battle_attr#battle_attr.y, NewTimeListStr) end),
           mod_player:stop(Status#player.other#player_other.pid, 7),
           {stop, normal, Status}
    end;

%%刷新BUFF
handle_info(refresh_buff, Status) ->
    NewStatus = buff_util:refresh_goods_buff(Status),
    buff_util:refresh_buff_timer(NewStatus),  
%%     save_online_diff(Status,NewStatus),  
    save_online(NewStatus),
    {noreply, NewStatus};

handle_info(refresh_buff_timer, Status) ->
    buff_util:refresh_buff_timer(Status), 
    {noreply, Status};

handle_info(give_first_borned_buff, Status) ->
	?TRACE("give_first_borned_buff~n"),
	buff_util:add_goods_buff(Status, 151),
	{noreply, Status};

handle_info('CHECK_EXPIRE_TIME', Status) ->
	Num = util:rand(5000, 15000),
    erlang:send_after(Num, self(), 'CHECK_EXPIRE_TIME'),
%% 	test(Status, Num),
	NewStatus =  
		case Status#player.other#player_other.pet_status =:= 2 of
			true -> Status;
			false ->	lib_pet:check_facade_expire(Status)
		end,
    {noreply, NewStatus};

%%刷新Mount Fashion
handle_info(refresh_mount_fashion, Status) ->
    NewStatus = lib_mount:refresh_mount_fashion(Status),
    save_online_diff(Status,NewStatus),
    {noreply, NewStatus};

%% 定时存数据库
handle_info('SAVE_DB', Status) ->
	spawn(fun()-> save_player_table(Status, 0) end),
	erlang:send_after(util:rand(?SAVE_DB_TICK-60000, ?SAVE_DB_TICK+60000), self(), 'SAVE_DB'),
    {noreply, Status};

handle_info({delay_buff,BuffId,SkillLevel},Status) ->
	case tpl_buff:get(BuffId) of
		TplBuff when is_record(TplBuff,temp_buff)->
			NewLinkSkill = lists:map(fun(SkillId)->
											 {SkillId,SkillLevel}
									 end, TplBuff#temp_buff.link_skill),
		lib_skill:trigger_link_skill(Status,NewLinkSkill,0,-1);
		_->
			skip
	end,
	{noreply, Status};

handle_info(stop,Status)-> 
	{stop, normal, Status};

handle_info(Info, Status) ->
   ?ERROR_MSG("Mod_player_info: /~p/~n",[[Info]]),
   {noreply, Status}.

test(Status, Num) ->
	GoodsList =[{526004201, 1000},{535004205, 3},{262065202,1}, {262095203,1}, {262085203,1}, {262075203,1},
				 {262085204,1}, {246004204,1}, {262045201, 1}, {262015201,1}, {264075202,1},{322064204,1},{322054205,1},{332044205,1},
				{332054205,1},{213011203,1},{327072205,1}, {217061204, 1}, {215082204,1}, {215081204,1},
				{215073204,1},{215072204,1},{215071204,1},{215063204,1},{215062204,1},{215061204,1},{215053204,1},
				{215052204,1},{215051204,1},{217052204,1}],
	N = util:rand(1, 30),
	GoodsList1 = lists:nth(N, GoodsList),
	case Num > 12000 of
		true ->
			?TRACE("send_goods_and_money ~n"),
			goods_util:send_goods_and_money([GoodsList1], Status, 1);
		false ->
			?TRACE("del_bag_goods ~n"),
			{GoodsId, GoodsNum} = GoodsList1,
			goods_util:del_bag_goods(Status, GoodsId, GoodsNum, 1)
	end.
%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, Status) ->   
    %% 卸载角色数据  
	NewStatus = unload_player_info(Status),    
	mod_disperse:sync_player_to_gateway(NewStatus) ,
    misc:delete_monitor_pid(self()),  
	Now = util:unixtime(), 
	db_agent_log:insert_log_quit(NewStatus),
    ok.

try_2_unregister_pid(PidName) ->     
	case misc:whereis_name({local, PidName}) of
		Pid when is_pid(Pid) ->  
			misc:delete_monitor_pid(Pid),
			erlang:unregister(PidName);
		_ ->
			skip
	end . 

%%非正常下线逻辑
do_unnormal_offline(Status)-> 
	[PidSend] = Status#player.other#player_other.pid_send,
	gen_server:cast(PidSend, 'remove_socket'),
	NewPlayerOther = Status#player.other#player_other{socket = undefined},
	NewStatus = Status#player{other = NewPlayerOther},
	save_online(NewStatus),
	CloseTimer = erlang:send_after(10*1000, self(), stop),
	put(close_timer,CloseTimer),
	NewStatus.
%%关闭下线定时器（不关闭的话玩家非正常下线后10就断线）
cancel_player_timer()->
	case get(close_timer) of
		undefined ->
			skip;
		Timer ->
			erlang:cancel_timer(Timer)
	end.
%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_oldvsn, Status, _extra) ->
    {ok, Status}.

%%----------------------------------------------
%%更新上次登录IP及时间
%%----------------------------------------------
update_last_login(Player, Scoket) ->
    %%最后登录时间和IP
    LastLoginIP = misc:get_ip(Scoket) , 
    db_agent_player:update_last_login(Player#player.last_login_time, LastLoginIP, Player#player.id) .

%%----------------------------------------------
%%更新玩家登陆次数，login_times + 1
%%----------------------------------------------
update_login_times(Player) ->
	LoginTimes = Player#player.login_times + 1,
	db_agent_player:update_login_times(Player#player.id, LoginTimes).
    
%%----------------------------------------------
%%@spec 完善record 结构,包括本身和Other
%%----------------------------------------------
load_for_runtime_data(Player, ResoltX, ResoltY, Socket, LastLoginTime) ->
	%try  
		PlayerId = Player#player.id ,
		%% Socket消息发送进程
		PidSendList = lists:map(fun(N)-> 
										{ok, PidSend} = mod_pid_send:start(Socket, N),
										PidSend
								end, lists:seq(1, ?SEND_MSG)),
		%%打开任务进程
		{ok, PidTask} = mod_task:start_link([PlayerId]) ,
		
		%lib_task:init_task_module(Player),
		    
		{ok, PidDun} = mod_dungeon:start_link([PlayerId]) ,
		  
		%% 创建物品模块PID
		GoodsEtsId = mod_goods_l:get_min_ets_goods_name(),
		{ok, GoodsPid} = mod_goods:start(PlayerId, Player#player.cell_num, GoodsEtsId),
		
		GoodsStatus = gen_server:call(GoodsPid, {'STATUS'}),
		?TRACE("login suc equip current: ~p~n", [GoodsStatus#goods_status.equip_current]),	
		%% 初始化玩家的套装信息
		SuitList = lib_suit:init_login_suit(PlayerId, GoodsEtsId),
		
		%%初始玩家基本战斗属性, 生命力, 法力, 怒气, 连击点用玩家数据库里的
		BattleAttr = lib_player:init_base_battle_attr(Player#player.level, Player#player.career, Player#player.battle_attr), 
		OtherTmp = #player_other{goods_ets_id = GoodsEtsId},
		PlayerTmp = Player#player{other = OtherTmp},		
		[WeaponStrenLv, ArmorStrenLv, FashionStrenLv, WaponAccStrenLv, WingStrenLv] = lib_equip:get_equip_strenlv(GoodsStatus#goods_status.equip_current, PlayerTmp, []),
		{PetFacade, PetStatus, PetQualityLv, PetName} = lib_pet:init_pet_info(PlayerTmp),
		%% 设置角色的相关信息
		Other = #player_other{ skill_list = [],
							   socket = Socket,
							   pid = self(),
						 	   pid_goods = GoodsPid,
							   pid_send = PidSendList,
							   pid_battle = undefined,       % 战斗进程Pid
							   pid_scene = undefined,        % 当前场景Pid
							   pid_dungeon = PidDun,      	 % 当前副本进程
							   pid_task = PidTask,
							   node = node(),
							   pk_mode = 0,
							   goods_ets_id = GoodsEtsId,
							   equip_current = GoodsStatus#goods_status.equip_current,
							   role_suit = SuitList,
							   weapon_strenLv = WeaponStrenLv,
							   armor_strenLv = ArmorStrenLv,
							   fashion_strenLv = FashionStrenLv,
							   wapon_accstrenLv = WaponAccStrenLv,
							   wing_strenLv = WingStrenLv,
							   pet_facade = PetFacade,
							   pet_status = PetStatus,
							   
							   pet_quality_lv = PetQualityLv,
							   pet_name = PetName 
							 },
		
		%% 初始化部分角色属性
		NewPlayer1 = Player#player{ 
								   account_name = tool:to_list(Player#player.account_name) ,
								   nick = tool:to_list(Player#player.nick) ,
								   last_login_time = LastLoginTime ,
								   online_flag = 1 ,
								   resolut_x = ResoltX,
								   resolut_y = ResoltY,
								   battle_attr = BattleAttr,
								   other = Other}, 
		%%更新ETS_ONLINE在线表
		ets:insert(?ETS_ONLINE, NewPlayer1),
		
		%%加载玩家系统配置
		NewPlayer2 = lib_system_config:init_system_config(NewPlayer1),
		
		%%获取技能
		NewPlayer3 = lib_skill:role_login(NewPlayer2),
		
		%%加载座骑
		NewPlayer4 = lib_mount:role_login(NewPlayer3),
		
		%%加载关系 
		lib_relation:role_login(NewPlayer4),
		
		
		%%加载帮派
		NewPlayer5 = guild_util:role_login(NewPlayer4),
		
		%%加载新手引导
		lib_leader:role_login(NewPlayer5),
		
		%%加载活跃度模块
		lib_activity:role_login(NewPlayer5),
		
		%%加载最近联系人模块
		lib_contact:role_login(NewPlayer5),
		
		%%初始化经脉模块数据
		NewPlayer6=lib_meridian:init_meridian(NewPlayer5,0),
		
		buff_util:role_login(NewPlayer6),   
		NewPlayer7 = lib_player:handle_charge_order(NewPlayer6),
		NewPlayer8 = lib_player:calc_player_battle_attr(NewPlayer7), 
		NewPlayer9	= lib_skill:init_passive_skill(NewPlayer8),
	 	%%初始化任务 
		gen_server:cast(PidTask,{'init_task', NewPlayer9}),
		?TRACE("[PLAYER] player passive skill ~p ~n",[NewPlayer9#player.battle_attr#battle_attr.passive_skill_attr]),
        
        %%处理玩家当天首次登陆相关实务
        DataFirstTime = util:getDataFirstTime(),
        if
            DataFirstTime > Player#player.logout_time ->
                NewPlayer11 = check_vip(NewPlayer9);
            true ->
                NewPlayer11 = NewPlayer9
        end,

		NewPlayer11,   
		%%初始化玩家崇拜次数  
		lib_rank:init_player_adore(NewPlayer11).
%% 	catch 
%% 		Error:Reason ->
%% 			?TRACE("mod player error:~p reason:~p ~n get_stacktrace:~p ~n",[Error,Reason,erlang:get_stacktrace()]),
%% 			?ERROR_MSG("mod player error:~p reason:~p ~n get_stacktrace:~p ~n",[Error,Reason,erlang:get_stacktrace()])
%% 	end.

%% 加载玩家成就系统
%%----------------------------------------------
%% @spec 加载角色数据
%%    input: PlayerId -- 玩家ID Os,OsVersion,Device,DeviceType,Screen,Mno,Nm, 
%%         Socket   -- 
%%----------------------------------------------
load_player_info(PlayerId, ResoltX, ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen,Socket) ->
    NowTime = util:unixtime() ,
    LastLoginTime = NowTime + 5 ,
    put(player_id,PlayerId),
    
    %%获取玩家结构 record
    RawPlayer = load_player_table(PlayerId),
	    
    Player = load_for_runtime_data(RawPlayer , ResoltX, ResoltY, Socket, LastLoginTime) ,
    %%更新最近登录时间
    update_last_login(Player, Socket),	
	%%给出生玩家XX东西
	give_things_to_first_borned_player(Player),
	%%更新玩家登陆次数
	update_login_times(Player),
    
    %%获取禁言信息
    [StopBeginTime, StopSeconds] = lib_player:get_donttalk_status(PlayerId),
    put(donttalk, [StopBeginTime, StopSeconds]), 
	%% 初始化商店信息
	
	lib_shop:init_shop_info(PlayerId),
	
	%%获取剧情表
	lib_opera:load_opera(PlayerId),  
	%%获取场景礼包表
	lib_scene_gift:load_scene_gift(PlayerId),
	 
	%%更新玩家硬件信息
	init_player_hardwareinfo(Player,Screen,Os,OsVersion,Device,DeviceType,Mno,Nm) .

%%给出生玩家XX东西
give_things_to_first_borned_player(Player) ->	
	?TRACE("******************give_things_to_first_borned_player ~p ~n", [Player#player.login_times]),
	if Player#player.login_times =:= 0 ->%%刚出生第一次进游戏
		   %%给小气血包			   
		   erlang:send_after(5000, Player#player.other#player_other.pid, give_first_borned_buff);
	   true ->
		   ok
	end.

test() ->
	Fun = fun(P) ->
				  io:format("====player: ~p~n", [[P#player.id,
												  P#player.scene]]) 
		  end ,
	lists:foreach(Fun, ets:tab2list(ets_online)) .

test_scene(ScneId) ->
	Fun = fun(P) ->
				  io:format("====player: ~p~n", [[P#player.id,
												  P#player.scene,
												  P#player.battle_attr#battle_attr.x,
												  P#player.battle_attr#battle_attr.y]]) 
		  end ,
	EtsName = lib_scene:get_ets_name(ScneId) ,
	lists:foreach(Fun, ets:tab2list(EtsName)) .


%% 卸载角色数据
unload_player_info(Status) ->   
	%% 保存状态数据
	Now = util:unixtime(),
	NewStatus = save_player_table(Status#player{online_flag = 0}, 0),
	
	%%删除玩家节点ETS相关信息
	delete_player_ets(Status#player.id), 
	%%禁言回写
	writeback_donttalk(Status#player.id, Now),
	
	%%下线离开场景
	case lib_scene:is_dungeon_scene(Status#player.scene) of
		false ->
			pp_scene:handle(12004, Status, []);
		%% 			mod_dungeon:on_player_logoff(Status) ;
		true ->
			skip
	end ,
	mod_dungeon:on_player_logoff(Status),
	%% 退出副本进程
	gen_server:cast(Status#player.other#player_other.pid_dungeon, {stop, Status}),
	%%pp_scene:handle(12004, Status, []),
	%%mod_dungeon:on_player_logoff(Status) ,
	
	%%座骑退出
	lib_mount:role_logout(Status), 
	%%新手引导退出
	lib_leader:role_logout(Status),
	%%活跃度新手引导退出
	lib_activity:role_logout(Status),
	%%最近联系人退出
	lib_contact:role_logout(Status),
	%%关系退出
	lib_relation:role_logout(Status), 
	goods_util:role_logout(Status),
	lib_pet:role_logout(Status),  
	
	lib_skill:role_logout(Status),
	%% 退出任务进程
	gen_server:cast(Status#player.other#player_other.pid_task, {stop, Status}),
	
	%%下线删除定时器
	logout_cancel_timer(),
	
	%% 下线防沉迷处理
	handle_offline_antirevel(Status, Now),
	
	%%新手引导（改成实时写，在改动的时候）
	%%     lib_system_config:save_system_config(),
	
	mod_goods_l:sub_ets_goods_num(Status#player.other#player_other.goods_ets_id),
	%% 清理商店日志记录
	lib_shop:clear_shop_info(Status#player.id),
	
	%%保存剧情表
	lib_opera:update_opera(Status#player.id),
	%%保存场景礼包表
	lib_scene_gift:update_scene_gift(Status#player.id),
	
	buff_util:role_logout(Status) ,
	%% 关闭socket连接
	if Status#player.other#player_other.socket =/= undefined ->
		   gen_tcp:close(Status#player.other#player_other.socket);
	   true ->
		   skip
	end,
	NewStatus.

delete_ets_when_init(PlayerId)->
    ets:delete(?ETS_ONLINE, PlayerId).

%%停止本游戏进程
stop(Pid, Reason) when is_pid(Pid) ->
    gen_server:cast(Pid, {stop, Reason}).

%% 设置副本
set_dungeon(Pid, PidDungeon) ->
    case misc:is_process_alive(Pid) of
        false -> false;
        true -> gen_server:cast(Pid, {'SET_PLAYER', [{pid_dungeon, PidDungeon}]})
    end.

%% 设置禁言 或 解除禁言
set_donttalk(PlayerId, {BeginTime, DurationSeconds}) ->
      gen_server:cast({local, misc:player_process_name(PlayerId)}, {set_donttalk, BeginTime, DurationSeconds}).

%%回写禁言时间.
%%有必要时才回写
writeback_donttalk(Id, Now) ->
     case get(donttalk) of
        [BeginTime, Duration] ->
            case (BeginTime + Duration) > (Now + 5) of
                true ->
                    db_agent:update_donttalk(Id, BeginTime, Duration);
                false ->
                    skip
            end;
        _Other ->   
            skip
     end.

%% 同步更新ETS中的角色数据
save_online(PlayerStatus) ->   
    %% 更新本地ets里的用户信息
    ets:insert(?ETS_ONLINE, PlayerStatus),
    %% 更新对应场景中的用户信息  :w
    mod_scene:update_player(PlayerStatus),
    ok.

%% 差异同步更新ETS中的角色数据
save_online_diff(OldPlayer,NewPlayer) ->
    if
        is_record(OldPlayer,player) andalso is_record(NewPlayer,player) ->
            Plist = record_info(fields,player),
            Olist = record_info(fields,player_other),
			AList = record_info(fields,battle_attr) ,
            Fields = Plist ++ Olist ++ AList ,
            OvalList = lib_player_rw:get_player_info_fields(OldPlayer,Fields),
            NvalList = lib_player_rw:get_player_info_fields(NewPlayer,Fields),
            KeyValue = get_diff_val(OvalList,NvalList,Fields),
            if
                length(KeyValue) > 0 ->
                    ets:insert(?ETS_ONLINE, NewPlayer),
                    mod_scene:update_player_info_fields(NewPlayer,KeyValue) ;
                true ->
                    skip
            end;
        true ->
            ?ERROR_MSG("badrecord in save_online_diff:~p~n", [[OldPlayer,NewPlayer]])
    end,
    ok.

get_diff_val(Ol,Nl,Fs)->
    get_diff_val_loop(Ol,Nl,Fs,[]).

get_diff_val_loop([],_,_,DiffList) ->
    DiffList;
get_diff_val_loop(_,[],_,DiffList) ->
    DiffList;
get_diff_val_loop(_,_,[],DiffList) ->
    DiffList;
get_diff_val_loop([V1|Ol],[V2|Nl],[K|Fs],DiffList) ->
    if
        K /= other andalso K /= battle_attr andalso V1 /= V2 ->
            get_diff_val_loop(Ol,Nl,Fs,[{K,V2}|DiffList]);
        true ->
            get_diff_val_loop(Ol,Nl,Fs,DiffList)
    end.
    
%%从玩家表读取基本信息, 转换成玩家Record
%%登录时使用
load_player_table(PlayerId) -> 
    PlayerInfo = lib_account:get_info_by_id(PlayerId),
    RawPlayer = list_to_tuple([player|PlayerInfo]),  
    %%战斗信息需要特别处理
    case is_binary(RawPlayer#player.battle_attr) of
        true  ->  case util:bitstring_to_term(RawPlayer#player.battle_attr) of
                      [X, Y, Combopoint, Hit_point, Magic, Anger|_T] ->
                            BattleAttr = #battle_attr{ x = X,
                                                       y = Y,
                                                       combopoint = Combopoint,
                                                       hit_point = Hit_point,
                                                       magic = Magic,
                                                       anger = Anger
                                                      },
                            RawPlayer#player{battle_attr = BattleAttr,adore_detail = util:bitstring_to_term(RawPlayer#player.adore_detail)};
                      _Other ->
                            RawPlayer#player{battle_attr = #battle_attr{},adore_detail = util:bitstring_to_term(RawPlayer#player.adore_detail)}
                  end;
        false ->  RawPlayer#player{battle_attr = #battle_attr{},adore_detail = util:bitstring_to_term(RawPlayer#player.adore_detail)}
    end.

%%保存基本信息
%%这里主要统一更新一些相对次要的数据。
%%当玩家退出的时候也会执行一次这边的信息 
save_player_table(Status, _) -> 
	NewStatus = lib_dungeon_exp:check_save_in_dungeon_exp(Status),
    BattleAttrStr = util:term_to_string([ NewStatus#player.battle_attr#battle_attr.x,
                                          NewStatus#player.battle_attr#battle_attr.y,
                                          NewStatus#player.battle_attr#battle_attr.combopoint,
                                          NewStatus#player.battle_attr#battle_attr.hit_point,
                                          NewStatus#player.battle_attr#battle_attr.magic,
                                          NewStatus#player.battle_attr#battle_attr.anger
                                        ]),
    FieldList = [   coin,
					bcoin,
				 	scene,                               %% 场景ID	
                    cell_num,                            %% 物品格子数
                    level,                               %% 等级	
                    exp,                                 %% 经验	
                    online_flag,                         %% 在线标记，0不在线 1在线	
                    liveness,                            %% 活跃度	
                    lilian,                              %% 历练值
                    switch,                              %% 状态开关码1:功能开 0:功能关，位定义参考common.hrl	
                    battle_attr,                         %% 战斗属性
					force,								 %% 玩家战力
					max_force,							 %% 玩家最高战力
                    vip,                                 %% VIP等级
                    vip_expire_time,                     %% VIP失效时间 
					camp,								 %%玩家阵营
                    freefly,                             %% 免费传送次数,
					adore_count,						 %%崇拜次数
					adore_detail,						 %%崇拜次数详细信息
                	logout_time,						 %%退出时间
					equip_score							 %%玩家装备评分
					],

    ValueList = [   NewStatus#player.coin,
					NewStatus#player.bcoin,
				 	NewStatus#player.scene,                 %% 场景ID	
                    NewStatus#player.cell_num,              %% 物品格子数	
                    NewStatus#player.level,                 %% 等级	
                    NewStatus#player.exp,                   %% 经验	
                    NewStatus#player.online_flag,           %% 在线标记，0不在线 1在线	
                    NewStatus#player.liveness,              %% 活跃度	
                    NewStatus#player.lilian,                %% 历练值	
                    NewStatus#player.switch,                %% 状态开关码1:
                    BattleAttrStr,                       %% 战斗属性存数据库部分
					NewStatus#player.force,				 %% 玩家战力 
					NewStatus#player.max_force,             %% 玩家最高战力
                    NewStatus#player.vip,                   %%VIP等级
                    NewStatus#player.vip_expire_time,       %%VIP失效时间
				    NewStatus#player.camp,					 %%玩家阵营
                    NewStatus#player.freefly,                %%免费传送次数
   				    NewStatus#player.adore_count,			 %%崇拜次数
                    util:term_to_bitstring(NewStatus#player.adore_detail),         %%崇拜次数详细信息
					util:unixtime(),
					NewStatus#player.equip_score
                ] , 
 				 db_agent_player:save_player_table(NewStatus#player.id, FieldList, ValueList),
	NewStatus.

 
%%下线删除定时器
logout_cancel_timer() ->
    misc:cancel_timer(check_heart_timer),
    misc:cancel_timer(antirevel_act_timer),
    misc:cancel_timer(antirevel_warn_timer1),
    misc:cancel_timer(antirevel_warn_timer2),
    misc:cancel_timer(antirevel_warn_timer3),    
    ok.

%% 下线删除节点ETS表相关数据
delete_player_ets(PlayerId) ->
    %%清除玩家ets数据
    ets:delete(?ETS_ONLINE, PlayerId),
    %%清除任务模块及回存任务数据
    %lib_task:offline(PlayerId),
    %%删除在线玩家的ets物品表
    %goods_util:goods_offline(PlayerId, 1),
    ok.

%% --------------------------------------------------------------------
%% @spec 登陆的防沉迷处理
%%    input: acctount id
%% --------------------------------------------------------------------
online_antirevel(AcctId) ->
    case config:get_infant_ctrl(server) of
        1 -> %%防沉迷开启
            case db_agent:get_idcard_status(AcctId) of
                1 -> 
                    ok; %%成年人
                %未成年人或未填写
                _ ->
                    T_time = lib_antirevel:get_total_gametime(AcctId),
                    Alart_time_1h = data_antirevel:get_antirevel_con(warn_time1),    %%60*60 + 5,
                    Alart_time_2h = data_antirevel:get_antirevel_con(warn_time2),    %%120*60 + 5,
                    Alart_time = data_antirevel:get_antirevel_con(warn_time3),       %%(3*60-5)*60 + 5,
                    Force_out_time = data_antirevel:get_antirevel_con(act_time),     %%3*60*60 + 5,
                    if T_time >= Force_out_time ->  %%累计时间10秒后立刻退出，不开其他定时器了
                        ForceOutTimer = erlang:send_after(10*1000, self(), 'FORCE_OUT_REVEL'),
                        put(antirevel_act_timer, ForceOutTimer);
                    true ->
                        %%强制退出定时器
                        ForceOutTimer = erlang:send_after((Force_out_time - T_time + 10)*1000, self(), 'FORCE_OUT_REVEL'),
                        put(antirevel_act_timer, ForceOutTimer),
                        %%1小时通知
                        if T_time < Alart_time_1h ->
                           Timer_1h = erlang:send_after((Alart_time_1h - T_time) * 1000, self(), {'ALART_REVEL', 60}),
                           put(antirevel_warn_timer1, Timer_1h);
                        true -> ok
                        end,

                        %%两小时通知
                        if T_time < Alart_time_2h ->
                            Timer_2h = erlang:send_after((Alart_time_2h - T_time) * 1000, self(), {'ALART_REVEL', 120}),
                            put(antirevel_warn_timer2, Timer_2h);
                        true -> ok
                        end,

                        %%两小时55分钟能知
                        if T_time < Alart_time ->
                            Alart_timer = erlang:send_after((Alart_time - T_time) * 1000, self(), {'ALART_REVEL', 180}),
                            put(antirevel_warn_timer3, Alart_timer);
                        true -> ok
                        end
                    end
            end;
        _ -> 
            ok
    end .

%% 下线防沉迷处理
handle_offline_antirevel(Status, Now_time) ->
    case config:get_infant_ctrl(server) of
        1 -> %%防沉迷开启
            Accid = Status#player.account_id,
            case db_agent:get_idcard_status(Accid) of
                1 -> ok; %%成年人 
                _ ->
                    {TodayMidnight, _NextDayMidnight} = util:get_midnight_seconds(Now_time),
                     TotalTime = lib_antirevel:get_total_gametime(Accid), %%如果没有记录，这个函数会建立一条
                     case Status#player.last_login_time > TodayMidnight of
                         %今天登录的
                         true ->
                             NewTotalTime = TotalTime + tool:int_format(Now_time - Status#player.last_login_time);
                         %昨天登录 只记今天时间
                         false -> 
                             NewTotalTime = tool:int_format(Now_time - TodayMidnight)
                     end,
                     lib_antirevel:set_total_gametime(Accid, NewTotalTime),
                     lib_antirevel:set_logout_time(Accid, Now_time)
            end;
        _ -> ok
    end.

%% 更新本节点信息
update(PlayerStatus) ->
	ets:insert(?ETS_ONLINE, PlayerStatus).

%%协议测试函数
pp_test(PlayerId, Cmd, Data) ->
     case lib_player:get_player_pid(PlayerId) of 
         Pid when is_pid(Pid) ->  %%在线
             gen_server:call(Pid, {'SOCKET_EVENT', Cmd, Data});
         _Other ->  
             io:format("PlayerId: ~p is not online~n", [PlayerId])
     end.

%%处理玩家首次登陆游戏vip相关事务
check_vip(PlayerStatus) ->
    NowTime = util:unixtime(),
    if
        PlayerStatus#player.vip > 0 andalso PlayerStatus#player.vip_expire_time > NowTime ->
        NewPlayerStatus = lib_vip:check_vip_date_gift(PlayerStatus);%%处理VIP玩家首次登陆游戏事件
    true ->
        NewPlayerStatus = PlayerStatus
    end.
