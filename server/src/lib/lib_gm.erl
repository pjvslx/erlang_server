%%%-------------------------------------- 
%%% @Module: lib_gm
%%% @Author: 
%%% @Created: 
%%% @Description: gm指令
%%%-------------------------------------- 
-module(lib_gm).

-include("common.hrl").
-include("record.hrl"). 
-include("debug.hrl").
-include("log.hrl").

-export([handle_cmd/2, 
		 handle_gm_cmd/2,
		 getPlayerStatus/1]).

%%GM指令格式:
%%　　"-coin 10000"  参数之用半角的空格分开,不要使用全角的空格及字符串
%%    "-coin 10000\r -gold 10000"  是两条GM指令.　指令之间用换行符分隔

%%把聊天信息当成gm指令
handle_cmd(Status, []) ->
   {ok, Status};  
handle_cmd(Status, [ChatMsg|T]) ->
   ChatMsg1 = string:tokens(ChatMsg, " "),
   F = fun(CM) -> %将字符串解码、解码失败的保持原样。特别备注——中文名和英语名可能会有不同的结果  
            Reply = util:string_to_term(CM),
            if CM == "undefined" ->
                  undefined;
               Reply =/= undefined ->
                  Reply;
               true ->
                  CM
            end
       end,
 
   ChatMsg2 = [F(CM) || CM <- ChatMsg1],
   case handle_gm_cmd(Status, ChatMsg2) of
      {ok, Status2} when is_record(Status2, player) ->
         handle_cmd(Status2, T);
      _ ->
         handle_cmd(Status, T)
   end.

%%-----------------------------------------------
%% GM指令实现
%%-----------------------------------------------
handle_gm_cmd(Status, ["-get_time"]) ->
   CurTime = mod_mytime:time(),
   PromptMsg = io_lib:format(<<"当前时间：~p">>, [CurTime]),
   send_prompt(Status, PromptMsg);

%%直接改等级
handle_gm_cmd(Status, ["-level", Level])->
   Lv = if Level < 1 -> 1;
           Level > 100 -> 100;
           true -> Level
       end,
   Status2 = Status#player{level=Lv},  
   lib_player:notice_client_upgrade(Status2, Status#player.level),
   Status3  = lib_player:calc_player_battle_attr(Status2 ),
   NewStatus =lib_player:open_level_func(Status3),
   mod_player:save_online(NewStatus),
   lib_task:call_event(Status,lv,{Level}),
   {ok, NewStatus};

handle_gm_cmd(Status, ["-midnight"])->
	Pid = mod_misc:get_mod_misc_pid(),
	Pid !midnight,
	{ok, Status};

%%直接改等级
handle_gm_cmd(Status, ["-reset_dungeon"])->
   mod_dungeon:clear_times(Status#player.id) ,
   {ok, Status};

%%加法力
handle_gm_cmd(Status, ["-magic",Num]) ->
   Status2 = lib_player:add_magic(Status, Num),                 
   lib_player:send_player_attribute3(Status2),
   {ok, Status2};

%%加怒气
handle_gm_cmd(Status, ["-anger",Num]) ->
   Status2 = lib_player:add_anger(Status, Num),                 
   lib_player:send_player_attribute3(Status2),
   {ok, Status2};

%%置满能量值
handle_gm_cmd(Status, ["-energy"]) ->
   Status2 = lib_player:add_energy(Status),                 
   lib_player:send_player_attribute2(Status2),
   {ok, Status2};

%%加铜钱
handle_gm_cmd(Status, ["-coin",Num]) ->
   Status2 = lib_money:add_coin(Status, Num, ?LOG_MONEY_GM),                 
   lib_player:send_player_attribute3(Status2),
   {ok, Status2};

%%加绑定铜钱
handle_gm_cmd(Status, ["-bcoin",Num]) ->
   Status2 = lib_money:add_bcoin(Status, Num, ?LOG_MONEY_GM),                 
   lib_player:send_player_attribute3(Status2),
   {ok, Status2};
%%添加仇人
handle_gm_cmd(Status, ["-addfoe",Uid]) ->
	pp_relation:handle_cmd(14015, Status, [Uid]),
	pp_relation:handle_cmd(14002, Status, 0);
%%添加黑名单
handle_gm_cmd(Status, ["-addblacklist",Uid]) ->
	pp_relation:handle_cmd(14017, Status, [Uid]),
	pp_relation:handle_cmd(14002, Status, 0);
%%加金币
handle_gm_cmd(Status, ["-gold",Num])-> 
   Status2 = lib_money:add_gold(Status, Num, ?LOG_MONEY_GM),                 

   PlayerStatusNew = lib_vip:chargeVip(Status2,Num),
   lib_player:send_player_attribute3(PlayerStatusNew),
   lib_task:call_event(PlayerStatusNew,gold_charge,{Num}),

   Now = util:unixtime(),
   db_agent_log:insert_charge_log(
       PlayerStatusNew#player.id,
       PlayerStatusNew#player.account_id, 
       PlayerStatusNew#player.level, 
       Num, 
       ?CHARGE_CHANEL_GM,   
       0, 
       0, 
       Now
   ), 
   {ok, PlayerStatusNew};

%%加绑定金币
handle_gm_cmd(Status, ["-bgold",Num]) ->
   Status2 = lib_money:add_bgold(Status, Num, ?LOG_MONEY_GM),                  
   lib_player:send_player_attribute3(Status2),
   {ok, Status2};

%%加经验
handle_gm_cmd(Status, ["-exp",Num]) ->
   Status2 = lib_player:add_exp(Status, Num, 0),                 
   lib_player:send_player_attribute1(Status2),
   {ok, Status2};

handle_gm_cmd(Status, ["-lilian",Num]) ->
   Status2 = lib_player:add_lilian(Status, Num), 
   lib_player:send_player_attribute4(Status2),
   {ok, Status2};

%%清空任务数据
handle_gm_cmd(Status, ["-xtask"]) ->
	gen_server:cast(Status#player.other#player_other.pid_task, {gm_command,"-xtask",[Status#player.id],Status}),
	skip;
%%接任务
handle_gm_cmd(Status, ["-gettask",Tid]) ->
	gen_server:cast(Status#player.other#player_other.pid_task, {'accept_task', Status, Tid}),
	skip; 
%%完成任务
handle_gm_cmd(Status, ["-taskcomplete",Tid]) ->
	gen_server:cast(Status#player.other#player_other.pid_task, {gm_command,"-taskcomplete",[Status,Tid],Status}),
	skip;
%%跳到特定的任务
handle_gm_cmd(Status, ["-taskgoto",Tid]) ->
	%%同时需要修改玩家等级
	case tpl_task:get(Tid) of 
		Task when is_record(Task, tpl_task) ->
			Level = Task#tpl_task.level,
			%%如果玩家等级不够, 升级处理
			if Status#player.level < Level ->
				   Status2 = Status#player{level=Level},
				   lib_player:notice_client_upgrade(Status2, Status#player.level),
                   gen_server:cast(Status2#player.other#player_other.pid_task, {gm_command,"-taskgoto",[Status2,Tid],Status2}),
				   {ok, Status2};
			   true->
                   gen_server:cast(Status#player.other#player_other.pid_task, {gm_command,"-taskgoto",[Status,Tid],Status})
			end;
		_->
			skip
	end;
%%任务事件
handle_gm_cmd(Status,["-task_event",Content])->
	NewContent = util:bitstring_to_term(Content),
	[Event,Param] = NewContent,
	lib_task:call_event(Status, Event, Param), 
	 {ok, Status};
%%加物品
handle_gm_cmd(Status, ["-addgoods", GoodsTid, Num]) ->
  goods_util:send_goods_to_role([{GoodsTid, Num}], Status, 0);

%%加宠物物品
handle_gm_cmd(Status, ["-petall"]) ->
	lib_leader:open_func(Status, 2, 25),
	goods_util:send_goods_to_role([{251005201, 2997}], Status, 0),
	goods_util:send_goods_to_role([{251005202, 2997}], Status, 0),
	goods_util:send_goods_to_role([{251005203, 2997}], Status, 0),
	goods_util:send_goods_to_role([{253005201, 2997}], Status, 0),
	goods_util:send_goods_to_role([{253005202, 2997}], Status, 0),
	goods_util:send_goods_to_role([{253005203, 2997}], Status, 0),
	goods_util:send_goods_to_role([{255005201, 999}], Status, 0),
	goods_util:send_goods_to_role([{255005202, 999}], Status, 0),	
	goods_util:send_goods_to_role([{255005203, 999}], Status, 0),
	goods_util:send_goods_to_role([{442005201, 999}], Status, 0),
	goods_util:send_goods_to_role([{442005202, 999}], Status, 0),
	goods_util:send_goods_to_role([{602001001, 999}], Status, 0),
	goods_util:send_goods_to_role([{602001002, 999}], Status, 0),
	goods_util:send_goods_to_role([{602002001, 999}], Status, 0),
	goods_util:send_goods_to_role([{602002002, 999}], Status, 0),
	goods_util:send_goods_to_role([{601001001, 999}], Status, 0),
	goods_util:send_goods_to_role([{601001002, 999}], Status, 0),
	Status2 = lib_money:add_coin(Status, 10000000, ?LOG_MONEY_GM),                 
    lib_player:send_player_attribute3(Status2),
    {ok, Status2};

%%删物品
handle_gm_cmd(Status, ["-delgoods", GoodsTid, Num]) ->
  goods_util:del_bag_goods(Status, GoodsTid, Num, 0);

%%加一系列的测试物品
handle_gm_cmd(Status, ["-test", Type]) ->
	{ok, Status1} = handle_gm_cmd(Status, ["-gold", 10000]),
	{ok, Status2} = handle_gm_cmd(Status1, ["-bgold", 10000]),
	{ok, Status3} = handle_gm_cmd(Status2, ["-coin", 1000000]),
	{ok, Status4} = handle_gm_cmd(Status3, ["-bcoin", 1000000]),
	{ok, Status5} = pp_goods:handle(15003, Status4, [0,80]),
	goods_util:give_test_goods(Status5, Type),
	{ok, Status5};

%%加战斗属性
handle_gm_cmd(Status, ["-bat", Field, Num]) ->
   Status2 = lib_player:update_battle_attr(Status, [{Field, Num}]),                 
   lib_player:send_player_attribute1(Status2),
   {ok, Status2};

%%加玩家实力不足的提示语句
handle_gm_cmd(Status,["-noticemail"]) ->
	lib_mail:send_mail_to_one(Status#player.id,1,6,[]);
%%加宠物
handle_gm_cmd(Status, ["-pet"]) ->
   lib_pet:create_pet(Status) ;

%%给自己发邮件
handle_gm_cmd(Status, ["-mail", Num]) ->
   Num1 = if is_integer(Num) -> Num; true -> 10 end,
   lib_mail:rand_insert_mail(Status#player.id, 1, Num1),
   lib_mail:notify_new_mail(Status#player.id, 1);

%%World Level
handle_gm_cmd(_Status, ["-worldlv", Num]) ->
   lib_world_level:update(Num),
   skip;

%%Open Mount
handle_gm_cmd(Status, ["-mount"]) ->
    Status1 = lib_mount:open_mount(Status),
    {ok, Status1};
%%用于测试功能开放接口
handle_gm_cmd(Status, ["-openfunc", Type, Cond_id]) -> 
  	lib_leader:open_func(Status,Type,Cond_id);
%%用于测试技能引导开启
handle_gm_cmd(Status, ["-startskill",LeaderId]) ->
	lib_leader:change_skill_leader(Status#player.id,LeaderId,1);

%%用于测试技能引导结束
handle_gm_cmd(Status, ["-endskill",LeaderId]) ->
	lib_leader:change_skill_leader(Status#player.id,LeaderId,2);

%%直接将红和蓝加满
handle_gm_cmd(Status,["-full"])->
	Status1 = lib_player:full_hp_magic(Status),
	lib_player:send_player_attribute1(Status1),
	{ok, Status1};

%%玩家死亡
handle_gm_cmd(Status,["-suicide"])->
  	BattleAttr = Status#player.battle_attr,
	NewBattleAttr = BattleAttr#battle_attr{hit_point = 0},
	Status1 = Status#player{status = ?PLAYER_NORMAL_STATE, battle_attr = NewBattleAttr},
	NewStatus = lib_skill:remove_all_skill_buffer_when_dead(Status1),
	{ok,Data} = pt_22:write(22003,[?ELEMENT_PLAYER,Status#player.id,1,0,0]),
	lib_send:send_to_sid(Status#player.other#player_other.pid_send, Data),
	{ok, NewStatus};

%%玩家重生
handle_gm_cmd(Status,["-reborn"])->
	BattleAttr = Status#player.battle_attr,
	HitPoint = BattleAttr#battle_attr.hit_point_max,
	NewBattleAttr = BattleAttr#battle_attr{hit_point = HitPoint},
	Status1 = Status#player{status = 0, battle_attr = NewBattleAttr},
	{ok, Status1};

%%玩家注销
handle_gm_cmd(Status,["-logoff"]) ->
	db_agent_player:delete_role(Status#player.id,Status#player.account_id),
	erlang:exit(Status#player.other#player_other.pid, logoff),
	{ok, Status};
%%玩家踢下线
handle_gm_cmd(Status,["-kitoff"]) -> 
	gen_server:cast(Status#player.other#player_other.pid, {stop, normal}),
	{ok, Status};
%%开启经脉模块
handle_gm_cmd(Status, ["-meridian"]) -> 
   lib_player:open_meridian(Status),    
   {ok, Status};
handle_gm_cmd(Status,["-buff",Id])->
	lib_skill:apply_self_skill_buff(Status,[Id],{1,1,1}),
	{ok, Status};
handle_gm_cmd(Status,["-teleport",PosX,PosY]) ->
	SceneId = lib_scene:get_base_scene(Status#player.scene),
	{ok,Status1} = pp_scene:handle(12001,Status,[SceneId,PosX div 32,PosY div 64]),
	{ok,Status1};

handle_gm_cmd(Status,["-comebyname",Name]) ->
	case lib_account:get_id_by_nick(Name) of
		[] -> skip;
		Uid -> 
			case lib_player:get_player_pid(Uid) of 
        		Pid when is_pid(Pid) ->  %%在线
            		gen_server:call(Pid, 
									{'SOCKET_EVENT', 
									 12001, 
									 [Status#player.scene,
									  Status#player.battle_attr#battle_attr.x,
									  Status#player.battle_attr#battle_attr.y]});
        		_Other ->  
            		?ERROR_MSG("PlayerId: ~p is not online~n", [Uid])
    		end
	end;

handle_gm_cmd(Status,["-gobyname",Name]) ->
	case lib_account:get_id_by_nick(Name) of
		[] -> skip;
		Uid ->
			case
				case lib_scene:get_scene_player(Uid) of
					Player when is_record(Player, player) ->
						pp_scene:handle(12001,
										Status,
										[Player#player.scene,
									 	Player#player.battle_attr#battle_attr.x,
									 	Player#player.battle_attr#battle_attr.y]);
					_ ->
						?ERROR_MSG("PlayerId: ~p is not found ~n", [Uid])
				end
			of
				{ok,Status1} -> {ok,Status1};
				_ -> {ok,Status}
			end	
	end;
	

handle_gm_cmd(Status,["-slay",MonsterId]) ->
	PIdScene = mod_scene:get_scene_pid(Status#player.scene),
	gen_server:call(PIdScene,{apply_call, lib_mon, remove_moster, [MonsterId]}),
	BattleWithMonster =[{?ELEMENT_MONSTER, 
					 MonsterId, 
					 0, %设置血量0通知前端删除怪物
					 0,
					 999, 0, 1}] ,
	PosX = Status#player.battle_attr#battle_attr.x,
	PosY = Status#player.battle_attr#battle_attr.y,
	{ok,DataBin} =  pt_20:write(20001, [Status#player.id, 0, 0, 0,  0, 0,0,0,
										BattleWithMonster]),
	lib_battle:send_battle_data(Status,PosX,PosY, DataBin) ,
	{ok,Status};

handle_gm_cmd(Status,["-slayall",Range]) ->
	PIdScene = mod_scene:get_scene_pid(Status#player.scene),
	MonList = case gen_server:call(PIdScene,{apply_call, lib_mon, get_squre_mons, [Status#player.id, 
				Status#player.battle_attr#battle_attr.x, 
				Status#player.battle_attr#battle_attr.y, 
				Range]}) of
		error -> 
			[] ;
		Data ->
			Data
	end,
	MonIds = lists:map(fun(M) ->
						M#temp_mon_layout.id
		  				end, MonList),
	gen_server:call(PIdScene,{apply_call, lib_mon, remove_mosters, [MonIds]}),
	BattleWithMonster = lists:map(fun(M) ->
									{?ELEMENT_MONSTER,M, 
					 				0, %设置血量0通知前端删除怪物
									0,999, 0, 1}
		  							end,MonIds),
	{ok,DataBin} =  pt_20:write(20001, [Status#player.id, 0, 0, 0,  0, 0,0,0,
										BattleWithMonster]),
	lib_battle:send_battle_data(Status,
								Status#player.battle_attr#battle_attr.x,
								Status#player.battle_attr#battle_attr.y,
								DataBin) ,
	{ok,Status};

handle_gm_cmd(Status,["-enter_dungeon",DunId]) ->
	pp_dungeon:handle(23001, Status, [10,DunId]),
	{ok,Status};

handle_gm_cmd(Status,["-create_monster",MonId]) ->
    case lib_scene:is_dungeon_scene(Status#player.scene) of
        true ->
            gen_server:call(Status#player.other#player_other.pid_dungeon,{apply_call, lib_mon, create_monster, 
							  [MonId,Status,Status#player.battle_attr#battle_attr.x,Status#player.battle_attr#battle_attr.y,1]});
        false ->
            gen_server:call(Status#player.other#player_other.pid_scene,{apply_call, lib_mon, create_monster, 
							  [MonId,Status,Status#player.battle_attr#battle_attr.x,Status#player.battle_attr#battle_attr.y,1]})
    end,

	{ok,Status};

%%清空角色包裹栏
handle_gm_cmd(Status,["-itemxx"]) ->
	gen_server:cast(Status#player.other#player_other.pid_goods, {'delete_player_goods', Status, ?LOCATION_BAG, ?LOG_MONEY_GM}),
	{ok,Status};

%%设置道具、装备的属性
handle_gm_cmd(_Status,["-itemset",_GoodsId,_AtriType,_AttriValue]) ->
	%%?TRACE("-itemset ~p ~p ~p ~n", [GoodsId,AtriType,AttriValue]),
	ok;

%%送自动穿上的装备
handle_gm_cmd(Status, ["-autoequip",GTid,Num]) ->	
	goods_util:send_goods_and_money_by_task([{GTid,Num}], Status, 1),	
	{ok, Status};

%%功能全部开放
handle_gm_cmd(Status, ["-openall"]) ->
	%%得出tpl_label的所有元素
	List1 = lib_leader:assemble_openfunc_list(1),
	F = fun(LabelId) ->
		LabelInfo = tpl_label:get(LabelId),
		{LabelInfo#temp_label.type,LabelInfo#temp_label.condition_id}
	end,
	ListOpenfunc = lists:map(F, List1),
	ListOpenfuncNew = lists:usort(ListOpenfunc),
	
	F1 = fun({Type,ConditionId}) ->
		lib_leader:open_func(Status,Type,ConditionId)
	end,
	lists:map(F1, ListOpenfuncNew),

	{ok, Status};

%%完成活跃度任务
handle_gm_cmd(Status, ["-activity",Btype,Stype]) ->
	lib_activity:finish_activity_single(Status,Btype,Stype),
	{ok, Status};
%%领取活跃度积分
handle_gm_cmd(Status, ["-getActivityScore",Btype,Stype])->
	lib_activity:get_activity_value(Status,Btype,Stype),
	{ok, Status};
%%领取宝箱奖励
handle_gm_cmd(Status, ["-getActivityBox",RewardId])->
	lib_activity:get_reward(Status,RewardId),
	{ok, Status};
	
	
%%更新玩家装备评分GM指令
handle_gm_cmd(Status, ["-equipscore",NewScore]) ->
	NewStatus = lib_player:update_equip_score(Status,NewScore),
	{ok,NewStatus};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handle_gm_cmd(Status, ["-create_guild",GuildName]) ->
    handle_gm_cmd(Status, ["-cg",GuildName]);
handle_gm_cmd(Status, ["-cg",GuildName]) ->
    ?TRACE("begin  GM: -cg\n"),
    {ok, Status1} = handle_gm_cmd(Status, ["-level", 50]),
    ?TRACE("-level\n"),

    goods_util:send_goods_to_role_immediatly(?LOCATION_BAG,[{390004205,2}], Status1, 0),

    ?TRACE("-addgoods\n"),
    {ok, Status2} = handle_gm_cmd(Status1, ["-gold", 10000]),
     {ok,Status3}= pp_guild:handle(40002, Status2, [GuildName,  "We are family"]),
    
    {ok,Status3};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%测试lib_mail:send_mail_to_one
handle_gm_cmd(Status, ["-sendtoone1",Param]) ->
	if
		Param == undefine ->
			ParamList = [];	
		true ->
			if
				is_number(Param) == true ->
					ParamList = lists:duplicate(Param, "test");
				true ->
					ParamList = []
			end	
	end,
	lib_mail:send_mail_to_one(Status#player.id,1,1,[{0,322104204,1}],ParamList);

handle_gm_cmd(Status, ["-sendtoone2",Param]) ->
	lib_mail:send_mail_to_one(Status#player.id,1,1,[{0,322104204,1}]);

handle_gm_cmd(Status, ["-testmail"]) ->
	lib_mail:send_mail_to_one(Status#player.id,1,18,[{0,322104204,1}],["背包","宠物技能书"]);
	

%%测试lib_mail:send_mail_to_some
handle_gm_cmd(Status, ["-sendtosome1",Param]) ->
	lib_mail:send_mail_to_some([Status#player.id],1,1,1,[{0,322104204,1}]);
handle_gm_cmd(Status, ["-sendtosome2",Param]) ->
	if
		Param == undefine ->
			ParamList = [];	
		true ->
			if
				is_number(Param) == true ->
					ParamList = lists:duplicate(Param, "test");
				true ->
					ParamList = []
			end	
	end,
	lib_mail:send_mail_to_some([Status#player.id],1,1,1,[{0,322104204,1}],ParamList);

%%测试lib_notice:send_bubble_msg
handle_gm_cmd(Status, ["-send_bubble", Type, Stype, Uid]) ->
	lib_notice:send_bubble_msg(Type,Stype,[],Uid);

handle_gm_cmd(Status, ["-send_system_notice",TypeId,Num,Gtid]) ->
	lib_notice:send_system_notice(Status,TypeId,Num,Gtid);

%%测试私聊
handle_gm_cmd(Status, ["-private_chat",Uid,Msg]) ->
	lib_chat:chat_private(Status,Uid,Msg);
	

%%清除vip
handle_gm_cmd(Status, ["-cvip"]) ->
    NewStatus = lib_vip:clearVip(Status),
    {ok, NewStatus};

handle_gm_cmd(_Event, _Val) ->
   skip.

%%发送提示消息
send_prompt(Status, RespMsg) ->
   {ok, BinData} = pt_11:write(11000, [Status#player.id, Status#player.nick, 5, RespMsg,lib_vip:getVipLevel(Status)]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%获得玩家信息，方便调试
getPlayerStatus(PlayerId) ->
	lib_common:get_ets_info(?ETS_ONLINE, PlayerId).
