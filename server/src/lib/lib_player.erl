%%%--------------------------------------
%%% @Module  : lib_player
%%% @Author  : 
%%% @Created : 2010.10.05
%%% @Description:角色相关处理
%%%--------------------------------------
-module(lib_player).
-compile(export_all).

-include("common.hrl").
-include("record.hrl"). 
-include("battle.hrl").
-include("log.hrl").
-include("goods.hrl").
-include("debug.hrl").
-include("leader.hrl").

-define(FIRST_PASSIVE_SKILL_LV,43).%%第一个被动技能点等级

%%获取在线玩家信息
get_player(PlayerId) ->
    case ets:lookup(?ETS_ONLINE, PlayerId) of
        [] ->
            {} ;
        [R] ->
            R
    end.

%%检测某个角色是否在线
is_online(PlayerId) ->
    case get_player_pid(PlayerId) of
        [] -> false;
        _Pid -> true
    end.

%%取得在线角色的进程PID
get_player_pid(PlayerId) ->
    PlayerProcessName = misc:player_process_name(PlayerId),
    case misc:whereis_name({local, PlayerProcessName}) of
        Pid when is_pid(Pid) ->  
            case misc:is_process_alive(Pid) of
                true -> Pid;
                _ ->
                    []
            end;
        _ -> []
    end.

%%根据ID调用异步调用玩家功能.
cast_player(PlayerId, Msg) ->
    PlayerProcessName = misc:player_process_name(PlayerId),
    case misc:whereis_name({local, PlayerProcessName}) of
        Pid when is_pid(Pid) ->
            case misc:is_process_alive(Pid) of
                true -> 
                    gen_server:cast(Pid, Msg),
                    true;
                _    ->
                    false 
            end;
        _ ->  false 
    end. 

%% 根据角色名称查找ID, 返回Id或[]
get_role_id_by_name(Name) ->
    db_agent_player:get_role_id_by_name(Name).

%%根据角色id查找名称, 返回<<"名字">>或[]
get_role_name_by_id(Id)->
    db_agent_player:get_role_name_by_id(Id).

%%获取模块开启状态, 返回数字或[]
get_switch_by_id(Id)->
    db_agent_player:get_switch_by_id(Id).

%%检测指定名称的角色是否已存在
is_accname_exists(AccName) ->
    case db_agent_player:is_accname_exists(AccName) of
        []     -> false;
        _Other -> true
    end.

%% 通过角色ID取得帐号相关于私聊的信息
get_chat_info_by_id(PlayerId) ->
    case ets:lookup(?ETS_ONLINE, PlayerId) of
        [] ->  
            db_agent_player:get_chat_info_by_id(PlayerId);
        [R] ->
            [R#player.nick, R#player.gender, R#player.career, R#player.camp, R#player.level]
    end.

%% 获取角色禁言信息
get_donttalk_status(PlayerId) ->
    case db_agent:get_donttalk(PlayerId) of
        [StopBeginTime, StopSeconds] ->
            [StopBeginTime, StopSeconds];
        _Other -> 
            db_agent:insert_donttalk(PlayerId),
            [0, 0]
    end.


%%检测指定名称的角色是否已存在
is_exists_name(Name) ->
    case get_role_id_by_name(Name) of
        []    -> false;
        _Other -> true
    end.

%%取得在线角色的角色状态
get_online_info(Id) ->
    case ets:lookup(?ETS_ONLINE, Id) of
        [] ->
            get_user_info_by_id(Id);
        [R] ->
            case misc:is_process_alive(R#player.other#player_other.pid) of
                true -> 
                    R;
                false ->
                    ets:delete(?ETS_ONLINE, Id),
                    []
            end
    end.

%%获取玩家信息
get_user_info_by_id(Id) ->
    case get_player_pid(Id) of
        []  -> [];
        Pid ->
            case catch gen:call(Pid, '$gen_call', 'PLAYER', 2000) of
                {'EXIT',_Reason} ->
                    [];
                {ok, Player} ->
                    Player
            end
    end.

%%获取用户信息(按字段需求)
get_online_info_fields(Id, L) when is_integer(Id) ->
    case get_player_pid(Id) of
        [] -> 
            [];
        Pid ->  
            get_online_info_fields(Pid, L)
    end;

get_online_info_fields(Pid, L) when is_pid(Pid) ->
    case catch gen:call(Pid, '$gen_call', {'PLAYER', L}, 2000) of
        {'EXIT',_Reason} ->
            [];
        {ok, PlayerFields} ->
            PlayerFields
    end.

%% 增加法力
add_magic(Status, 0) ->  
    Status;
add_magic(Status, Num) ->
    Magic = max(Status#player.battle_attr#battle_attr.magic + Num, 0),
    BattleAttr = Status#player.battle_attr ,
    NewBattleAttr = BattleAttr#battle_attr{magic = Magic} ,
    Status#player{battle_attr = NewBattleAttr}.

%% 增加生命值
add_hit_point(Status,0) ->
    Status;
add_hit_point(Status,Num) ->
    Min = 0,
    Max = Status#player.battle_attr#battle_attr.hit_point_max,
    X = Status#player.battle_attr#battle_attr.hit_point + Num,
    Hit_point = util:minmax(X, Min, Max),
    BattleAttr = Status#player.battle_attr,
    NewBattleAttr = BattleAttr#battle_attr{hit_point = Hit_point},
    Status#player{battle_attr = NewBattleAttr}.

check_hp_is_full(PS) ->
    if PS#player.battle_attr#battle_attr.hit_point < PS#player.battle_attr#battle_attr.hit_point_max ->
            no;
        true ->
            yes
    end.

%% 加满生命值和魔法值
full_hp_magic(Status) ->
    BattleAttr = Status#player.battle_attr,
    Max_hit_point = BattleAttr#battle_attr.hit_point_max,
    Max_magic = BattleAttr#battle_attr.magic_max,
    NewBattleAttr = BattleAttr#battle_attr{hit_point = Max_hit_point,magic_max = Max_magic},
    Status1 = Status#player{battle_attr = NewBattleAttr},
    send_player_attribute1(Status1),
    Status1.

%% 玩家自杀
player_suicide(Status) ->
    BattleAttr = Status#player.battle_attr,
    NewBattleAttr = BattleAttr#battle_attr{hit_point = 0},
    db_agent_player:save_player_table(Status#player.id, [status], [3]),
    Status1 = Status#player{status = 3,battle_attr = NewBattleAttr},
    send_player_attribute1(Status1),
    Status1.

%% 玩家复活
player_reborn(Status) ->
    BattleAttr = init_base_battle_attr(Status#player.level,Status#player.career),
    db_agent_player:save_player_table(Status#player.id, [status],[0]),
    Status1 = Status#player{status = 0,battle_attr = BattleAttr},
    send_player_attribute1(Status1),
    Status1.

%% 增加怒气
add_anger(Status, 0) ->  
    Status;
add_anger(Status, Num) ->
    Anger = max(Status#player.battle_attr#battle_attr.anger + Num, 0),
    BattleAttr = Status#player.battle_attr ,
    NewBattleAttr = BattleAttr#battle_attr{anger = Anger} ,
    Status#player{battle_attr = NewBattleAttr}.

add_lilian(Status, 0) ->  
    Status;
add_lilian(Status, Num) ->
    Lilian = max(Status#player.lilian + Num, 0),
    db_agent_player:save_player_table(Status#player.id, [lilian], [Lilian]),
    Status#player{lilian = Lilian}.
%% 置满能量值
add_energy(Status)->
	Energy = Status#player.battle_attr#battle_attr.energy,
	NewEnergy = Energy#energy{energy_val = Energy#energy.max_energy},
	BattleAttr = Status#player.battle_attr#battle_attr{energy = NewEnergy},
	Status#player{battle_attr = BattleAttr}.
%% 增加铜钱
add_coin(Status, 0) ->  
    Status;
add_coin(Status, Num) ->
    Coin = max(Status#player.coin + Num, 0),
    %%     db_agent_player:save_player_table(Status#player.id, [coin], [Coin]),
    Status#player{coin = Coin}.
%%消耗铜钱
cost_coin(Status, Num) ->
    Coin = max(Status#player.coin - Num, 0),
    %%     db_agent_player:save_player_table(Status#player.id, [coin], [Coin]),
    Status#player{coin = Coin}.

%% 增加铜钱
add_bcoin(Status, 0) ->  
    Status;
add_bcoin(Status, Num) ->
    BCoin = max(Status#player.bcoin + Num, 0),
    %%     db_agent_player:save_player_table(Status#player.id, [bcoin], [BCoin]),
    Status#player{bcoin = BCoin}.
%%消耗绑定铜钱
cost_bcoin(Status, Num) ->
    BCoin = max(Status#player.bcoin - Num, 0),
    %%     db_agent_player:save_player_table(Status#player.id, [bcoin], [BCoin]),
    Status#player{bcoin = BCoin}.

%% 增加元宝
add_gold(Status, 0) ->  
    Status;
add_gold(Status, Num) ->
    Gold = max(Status#player.gold + Num, 0),
    db_agent_player:save_player_table(Status#player.id, [gold], [Gold]),
    Status#player{gold = Gold}.
%%消耗元宝
cost_gold(Status, Num) ->
    Gold = max(Status#player.gold - Num, 0),
    db_agent_player:save_player_table(Status#player.id, [gold], [Gold]),
    Status#player{gold = Gold}.

%% 增加元宝
add_bgold(Status, 0) ->  
    Status;
add_bgold(Status, Num) ->
    BGold = max(Status#player.bgold + Num, 0),
    db_agent_player:save_player_table(Status#player.id, [bgold], [BGold]),
    Status#player{bgold = BGold}.
%%消耗绑定元宝
cost_bgold(Status, Num) ->
    BGold = max(Status#player.bgold - Num, 0),
    db_agent_player:save_player_table(Status#player.id, [bgold], [BGold]),
    Status#player{bgold = BGold}.

%%增加元宝铜钱
add_money(Status, Coin, BCoin, Gold, BGold) ->
    Coin = max(Status#player.coin + Coin, 0),
    BCoin = max(Status#player.bcoin + BCoin, 0),
    Gold = max(Status#player.gold + Gold, 0),
    BGold = max(Status#player.bgold + BGold, 0),
    db_agent_player:save_player_table(Status#player.id, [coin, bcoin, gold, bgold], [Coin, BCoin, Gold, BGold]),
    Status#player{coin = Coin, bcoin = BCoin, gold = Gold, bgold = BGold}.

%%增加人物经验入口(FromWhere)
add_exp(Status, Exp, _FromWhere) ->   
    NewExpOri = util:ceil(Status#player.exp + (lib_world_level:get_exp_ratio(Status#player.level) + 1)*Exp),
    NewExp = util:ceil(NewExpOri), 
    NewStatus = upgrade_to_next_level(Status#player{exp = NewExp}),
    if NewStatus#player.level =/= Status#player.level ->
            lib_task:call_event(NewStatus,lv,{NewStatus#player.level}),
            notice_client_upgrade(NewStatus, Status#player.level),
            lib_pet:upgrade_pet_level(NewStatus);
        true -> skip
    end,
    log:log_add_exp(Status#player.id, Exp, _FromWhere, 0),
    db_agent_player:save_player_table(NewStatus#player.id, [level, exp], [NewStatus#player.level, NewStatus#player.exp]),
    NewStatus .

%%更新任务的装备评分
update_equip_score(Status,NewScore)->
	if 
		NewScore == Status#player.equip_score ->
			Status;
		true ->
			%db_agent_player:save_player_table(Status#player.id,[equip_score],[NewScore]),
			NewStatus = Status#player{equip_score = NewScore}
	end.


%%升级到下一级    
upgrade_to_next_level(Status) ->
	MaxLevel = data_player:max_level(),  
	Status0 = if Status#player.level < MaxLevel ->
					 NextLvExp = data_player:next_level_exp(Status#player.career, Status#player.level),
					 case Status#player.exp >= NextLvExp of
						 true ->
							 {SkillPointUsed,OldSkillTotal} = Status#player.other#player_other.skill_point,
							 SkillPointTotal = get_player_new_skill_point(Status#player.level + 1),
							 NewPlayerOther = Status#player.other#player_other{
																			   skill_point = {SkillPointUsed,SkillPointTotal+OldSkillTotal} 
																			  }, 
							 lib_skill:update_player_skill_point(Status),
							 Status1 = Status#player{level = Status#player.level + 1,
													 exp = Status#player.exp - NextLvExp,  
													 other = NewPlayerOther}, 
							 %%升级相应操作
							 Status2 = lib_skill:open_skill(Status1),  
							 NewBattleAttr =  lib_skill:apply_lv_passive_effect(Status2),
							 Status3 = extend_bag(Status2#player{battle_attr = NewBattleAttr}), 
							 LastLvExp = data_player:next_level_exp(Status#player.career, Status#player.level-1),
							 db_agent_log:insert_log_level(Status#player.id, Status#player.nick,Status3#player.level,LastLvExp,Status3#player.exp),
							 mod_task:refresh_task_after_level_up(Status3),
							 pp_skill:handle_cmd(21000, Status3, {}),
							 %%省略1W行
							 upgrade_to_next_level(Status3);
						 false ->
							 Status
					 end;
				 true -> %%已达最大级别
					 Status
			  end,
	NewStatus = open_level_func(Status0),
	%%重新计算一次战斗属性
	if NewStatus#player.level > Status#player.level ->		   
		   NewStatus0 = calc_player_battle_attr(NewStatus),  
		   FinalBattleAttr = lib_energy:filling_energy(NewStatus0#player.battle_attr),
		   NewStatus0#player{
							 battle_attr=FinalBattleAttr
							};
	   true ->
		   NewStatus
	end.

join_2_level(Status,Level,IsNotice)->
	MaxLevel = data_player:max_level(),
	Status0 = if Status#player.level =< MaxLevel andalso Level =< MaxLevel ->   
					 Status1 = Status#player{level = Level} ,
					 NewStatus0 = calc_player_battle_attr(Status1),
					 FinalBattleAttr = lib_energy:filling_energy(NewStatus0#player.battle_attr),
					 NewStatus0#player{
									   battle_attr=FinalBattleAttr
									  };
				 true -> %%已达最大级别
					 Status
			  end,
	case IsNotice of
	    true -> 
	  	  lib_player:notice_client_upgrade(Status0, Status0#player.level);
	    _ ->
	  	  skip
	end,
	mod_player:save_online(Status0),
	Status0.
%%获取玩家当前技能点
get_player_new_skill_point(Lv)->
	case tpl_skill_point:get(Lv) of
		TplSkillPoint when is_record(TplSkillPoint, temp_skill_point) ->
			TplSkillPoint#temp_skill_point.skill_point;
	   _ ->
		   0
	end.
	   
%%等级触发模块开启
open_level_func(Ps)->
%% 	case Ps#player.level of
%% 		32 ->
%% 			open_camp(Ps);
%% 		_->
%% 			Ps
%% 	end.
	lib_leader:open_func(Ps,?LEVEL_OPEN,Ps#player.level).

%%开启阵营系统
open_camp(Ps)->
	gen_server:cast(Ps#player.other#player_other.pid, open_camp).
open_meridian(Ps)->
	gen_server:cast(Ps#player.other#player_other.pid, open_meridian).

extend_bag(Status) ->
    case tpl_level_bag:get(Status#player.level) of
        [] -> Status;
        Info ->
            if
                (Info#temp_level_bag.cell_num > 0) andalso (Status#player.cell_num < ?CELL_NUM_MAX_BAG) ->
                    CellNum = Status#player.cell_num + Info#temp_level_bag.cell_num,
                    AddNum = 
                    case ?CELL_NUM_MAX_BAG > CellNum of
                        true -> 
                            Info#temp_level_bag.cell_num;
                        false ->
                            CellNum - ?CELL_NUM_MAX_BAG
                    end,
                    [NewStatus, Res] = gen_server:call(Status#player.other#player_other.pid_goods, {'EXTEND_BAG', Status, AddNum}),
                    {ok, BinData} = pt_15:write(15003, [Res, NewStatus#player.cell_num]),
                    lib_send:send_one(NewStatus#player.other#player_other.socket, BinData),
                    NewStatus;
                true -> Status
            end
    end.

%%通知客户端等级提升了
notice_client_upgrade(Status, OldLevel) ->  
    ExpNextLevel = data_player:next_level_exp(Status#player.career, Status#player.level), 
    Data = [ Status#player.force,
        OldLevel,
        Status#player.level,
        Status#player.exp,
        ExpNextLevel,   
        Status#player.battle_attr#battle_attr.hit_point,
        Status#player.battle_attr#battle_attr.hit_point_max,
        Status#player.battle_attr#battle_attr.combopoint,
        Status#player.battle_attr#battle_attr.combopoint_max,
        Status#player.battle_attr#battle_attr.energy#energy.energy_val,
        Status#player.battle_attr#battle_attr.energy#energy.max_energy,
        Status#player.battle_attr#battle_attr.anger,
        Status#player.battle_attr#battle_attr.anger_max,
        Status#player.battle_attr#battle_attr.attack,
        Status#player.battle_attr#battle_attr.defense,
        Status#player.battle_attr#battle_attr.abs_damage,
        Status#player.battle_attr#battle_attr.fattack,
        Status#player.battle_attr#battle_attr.mattack,
        Status#player.battle_attr#battle_attr.dattack,
        Status#player.battle_attr#battle_attr.fdefense,
        Status#player.battle_attr#battle_attr.mdefense,
        Status#player.battle_attr#battle_attr.ddefense,
        Status#player.battle_attr#battle_attr.speed,
        Status#player.battle_attr#battle_attr.attack_speed,
        Status#player.battle_attr#battle_attr.hit_ratio,
        Status#player.battle_attr#battle_attr.dodge_ratio,
        Status#player.battle_attr#battle_attr.crit_ratio,
        Status#player.battle_attr#battle_attr.tough_ratio
    ],

    {ok, BinData} = pt_13:write(13007, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

% 发送玩家战斗力更新
send_player_attribute1(Status) -> 
	% ?ASSERT(util:floor(Status#player.battle_attr#battle_attr.energy#energy.energy_val)>0),
	ExpNextLevel = data_player:next_level_exp(Status#player.career, Status#player.level), 
	Data = [ Status#player.force,
			 Status#player.exp,
			 ExpNextLevel,   
			 Status#player.battle_attr#battle_attr.hit_point,
			 Status#player.battle_attr#battle_attr.hit_point_max,
			 Status#player.battle_attr#battle_attr.combopoint,
			 Status#player.battle_attr#battle_attr.combopoint_max,
			 Status#player.battle_attr#battle_attr.energy#energy.energy_val,
			 Status#player.battle_attr#battle_attr.energy#energy.max_energy,
			 Status#player.battle_attr#battle_attr.anger,
			 Status#player.battle_attr#battle_attr.anger_max,
			 Status#player.battle_attr#battle_attr.attack,
			 Status#player.battle_attr#battle_attr.defense,
			 Status#player.battle_attr#battle_attr.abs_damage,
			 Status#player.battle_attr#battle_attr.fattack,
			 Status#player.battle_attr#battle_attr.mattack,
			 Status#player.battle_attr#battle_attr.dattack,
			 Status#player.battle_attr#battle_attr.fdefense,
			 Status#player.battle_attr#battle_attr.mdefense,
			 Status#player.battle_attr#battle_attr.ddefense,
			 Status#player.battle_attr#battle_attr.speed,
			 Status#player.battle_attr#battle_attr.attack_speed,
			 Status#player.battle_attr#battle_attr.hit_ratio,
			 Status#player.battle_attr#battle_attr.dodge_ratio,
			 Status#player.battle_attr#battle_attr.crit_ratio,
			 Status#player.battle_attr#battle_attr.tough_ratio
		   ],    
	{ok, BinData} = pt_13:write(13003, Data), 
	lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).


%% 发送玩家战斗力更新(基本)
%% 可用于战斗过程更新
send_player_attribute2(Status) ->
    Data = [ Status#player.battle_attr#battle_attr.hit_point,
        Status#player.battle_attr#battle_attr.hit_point_max,
        Status#player.battle_attr#battle_attr.combopoint,
        Status#player.battle_attr#battle_attr.combopoint_max,
        Status#player.battle_attr#battle_attr.energy#energy.energy_val,
        Status#player.battle_attr#battle_attr.energy#energy.max_energy,
        Status#player.battle_attr#battle_attr.anger,
        Status#player.battle_attr#battle_attr.anger_max
    ],
    {ok, BinData} = pt_13:write(13004, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%发送玩家金钱更新
send_player_attribute3(Status) ->
    Data = [ Status#player.gold,
        Status#player.bgold,
        Status#player.coin,  
        Status#player.bcoin ],
    {ok, BinData} = pt_13:write(13005, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%发送玩家常用信息更新
send_player_attribute4(Status) ->
    Data = [ Status#player.exp,
        Status#player.lilian,
        Status#player.coin,
        Status#player.bcoin,
        Status#player.gold,
        Status#player.bgold
    ],  
    {ok, BinData} = pt_13:write(13006, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%告诉客户端刷新属性
refresh_client(Status, Code) ->
    {ok, BinData} = pt_13:write(13010, [Code]),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%加载怪基本战斗属性
%%Career对人物是职业, 对怪是怪类型, 生命恢复最大
init_base_battle_attr(Level, Career) ->
    TempAttr = tpl_combat_attr:get(Level, Career),  
    if is_record(TempAttr, temp_combat_attr) ->
            #battle_attr{
                career = Career,            
                skill_cd_all = 0,           
                skill_cd_list = [],          
                buff1 = [],              
                combopoint_max = TempAttr#temp_combat_attr.hit_point_max, 
                combopoint = 0,                
                hit_point = TempAttr#temp_combat_attr.hit_point_max,    
                hit_point_max = TempAttr#temp_combat_attr.hit_point_max,
                magic = TempAttr#temp_combat_attr.magic_max,                     
                magic_max = TempAttr#temp_combat_attr.magic_max,                 
                anger = 0,                     
                anger_max = TempAttr#temp_combat_attr.anger_max,                 
                attack = TempAttr#temp_combat_attr.attack,                    
                attack_ratio = 0,                             
                defense = TempAttr#temp_combat_attr.defense,                   
                defense_ratio = 0,             
                abs_damage = TempAttr#temp_combat_attr.abs_damage,                
                fattack = TempAttr#temp_combat_attr.fattack,                   
                fattack_ratio = 0,              
                mattack = TempAttr#temp_combat_attr.mattack,                   
                mattack_ratio = 0,             
                dattack = TempAttr#temp_combat_attr.dattack,                   
                dattack_ratio = 0,             
                fdefense = TempAttr#temp_combat_attr.fdefense,                  
                fdefense_ratio = 0,            
                mdefense = TempAttr#temp_combat_attr.mdefense,                   
                mdefense_ratio = 0,            
                ddefense = TempAttr#temp_combat_attr.ddefense,                   
                ddefense_ratio = 0,            
                speed = TempAttr#temp_combat_attr.speed,                      
                attack_speed = TempAttr#temp_combat_attr.attack_speed,              
                hit_ratio = TempAttr#temp_combat_attr.hit_ratio,                       
                dodge_ratio = TempAttr#temp_combat_attr.dodge_ratio,  
                crit_ratio = TempAttr#temp_combat_attr.crit_ratio,                      
                tough_ratio = TempAttr#temp_combat_attr.tough_ratio,     
                frozen_resis_ratio = TempAttr#temp_combat_attr.frozen_resis_ratio,
                weak_resis_ratio = TempAttr#temp_combat_attr.weak_resis_ratio,
                flaw_resis_ratio = TempAttr#temp_combat_attr.flaw_resis_ratio,
                poison_resis_ratio = TempAttr#temp_combat_attr.poison_resis_ratio,
                avoid_attack_ratio = 0,        
                avoid_fattack_ratio = 0,       
                avoid_mattack_ratio = 0,       
                avoid_dattack_ratio = 0,       
                avoid_crit_attack_ratio = 0,   
                avoid_crit_fattack_ratio = 0,  
                avoid_crit_mattack_ratio = 0,  
                avoid_crit_dattack_ratio = 0,  
                ignore_defense = 0,            
                ignore_fdefense = 0,           
                ignore_mdefense = 0,           
                ignore_ddefense = 0,
				real_defense = TempAttr#temp_combat_attr.defense
            };
        true ->
            ?ERROR_MSG("init_base_battle_attr: wrong paramter level: ~p, career: ~p~n", [Level, Career]),
            #battle_attr{}
    end.

%%加载玩家基本战斗属性
%%Career对人物是职业, 对怪是怪类型
init_base_battle_attr(Level, Career, BattleAttr) ->  
    ?ASSERT(Career >= 1 andalso Career =< 3),
    TempAttr = tpl_combat_attr:get(Level, Career), 
    if BattleAttr#battle_attr.speed =:= 0 ->
            NewSpeed = TempAttr#temp_combat_attr.speed,
            NewAttrSpeed = TempAttr#temp_combat_attr.attack_speed;
        true->
            NewSpeed = BattleAttr#battle_attr.speed,
            NewAttrSpeed = BattleAttr#battle_attr.attack_speed
    end, 
    if is_record(TempAttr, temp_combat_attr) ->  
            NewEnergy = lib_energy:init_energy(Level,Career,BattleAttr,TempAttr),
            #battle_attr{
                x = BattleAttr#battle_attr.x ,
                y = BattleAttr#battle_attr.y ,
                career = Career,          
                skill_cd_all = 0,           
                skill_cd_list = [],          
                buff1 = BattleAttr#battle_attr.buff1,    
                buff2 = BattleAttr#battle_attr.buff2,    
                skill_buff = BattleAttr#battle_attr.skill_buff,    
                combopoint_max = TempAttr#temp_combat_attr.hit_point_max, 
                combopoint = BattleAttr#battle_attr.combopoint,                
                hit_point = TempAttr#temp_combat_attr.hit_point_max,    
                hit_point_max = TempAttr#temp_combat_attr.hit_point_max,
                magic = TempAttr#temp_combat_attr.magic_max,                     
                magic_max = TempAttr#temp_combat_attr.magic_max,                 
                anger = BattleAttr#battle_attr.anger,                     
                anger_max = TempAttr#temp_combat_attr.anger_max,                 
                attack = TempAttr#temp_combat_attr.attack,                    
                attack_ratio = 0,                             
                defense = TempAttr#temp_combat_attr.defense,    
				real_defense = TempAttr#temp_combat_attr.defense,                  
                defense_ratio = 0,             
                abs_damage = TempAttr#temp_combat_attr.abs_damage,                
                fattack = TempAttr#temp_combat_attr.fattack,                   
                fattack_ratio = 0,              
                mattack = TempAttr#temp_combat_attr.mattack,                   
                mattack_ratio = 0,             
                dattack = TempAttr#temp_combat_attr.dattack,                   
                dattack_ratio = 0,             
                fdefense = TempAttr#temp_combat_attr.fdefense,                  
                fdefense_ratio = 0,            
                mdefense = TempAttr#temp_combat_attr.mdefense,                   
                mdefense_ratio = 0,            
                ddefense = TempAttr#temp_combat_attr.ddefense,                   
                ddefense_ratio = 0,            
                speed =NewSpeed,                      
                attack_speed = NewAttrSpeed,              
                hit_ratio = TempAttr#temp_combat_attr.hit_ratio,                       
                dodge_ratio = TempAttr#temp_combat_attr.dodge_ratio,  
                crit_ratio = TempAttr#temp_combat_attr.crit_ratio,                      
                tough_ratio = TempAttr#temp_combat_attr.tough_ratio,     
                frozen_resis_ratio = TempAttr#temp_combat_attr.frozen_resis_ratio,
                weak_resis_ratio = TempAttr#temp_combat_attr.weak_resis_ratio,
                flaw_resis_ratio = TempAttr#temp_combat_attr.flaw_resis_ratio,
                poison_resis_ratio = TempAttr#temp_combat_attr.poison_resis_ratio,
                avoid_attack_ratio = 0,        
                avoid_fattack_ratio = 0,       
                avoid_mattack_ratio = 0,       
                avoid_dattack_ratio = 0,       
                avoid_crit_attack_ratio = 0,   
                avoid_crit_fattack_ratio = 0,  
                avoid_crit_mattack_ratio = 0,  
                avoid_crit_dattack_ratio = 0,  
                ignore_defense = 0,            
                ignore_fdefense = 0,           
                ignore_mdefense = 0,           
                ignore_ddefense = 0,
                energy = NewEnergy
            };
        true ->
            ?ERROR_MSG("init_base_battle_attr: wrong paramter level: ~p, career: ~p~n", [Level, Career]),
            #battle_attr{}
    end.

test() ->
    ?ERROR_MSG("init_base_battle_attr: wrong paramter level: ~p, career: ~p~n", [fuck, you]) .

% 计算装备属性,基本属性、强化、洗练等
recount_player_equip_attr(PlayerStatus) ->
    % 获取装备列表
    EquipList = lib_equip:get_own_equip_list(?LOCATION_PLAYER, PlayerStatus), 
    % 获取装备基础属性  
    EquipAttr = lib_equip:get_equip_attri_list(EquipList), 
    % 获取装备铸造属性
    CastingAttri = lib_equip:get_equip_casting_attri(PlayerStatus, EquipList),
    % 获取全身强化奖励
    StrenReward = lib_equip:get_equip_stren_reward(PlayerStatus, EquipList),
	% 获取全身洗炼奖励  
	PolishReward = lib_equip:get_equip_all_polish_reward(PlayerStatus, EquipList, all),
    % 获取镶嵌全身加成
    InlayReward= lib_equip:get_equip_inlay_reward(PlayerStatus, EquipList),
    % 套装装备加成
    SuitReward = lib_equip:get_equip_suit_reward(PlayerStatus#player.other#player_other.role_suit),
    % 镀金加成
    GildingReward = lib_equip:get_equip_gilding_reward(PlayerStatus, EquipList),

    KeyValueList = EquipAttr ++ CastingAttri ++ StrenReward ++ PolishReward ++ InlayReward ++ SuitReward ++ GildingReward,
	F = fun(KeyValueNode, ResultList) ->
				{Key,Value} = KeyValueNode,
				NewKey = lib_goods:get_attr_name_atom_by_career(PlayerStatus, Key),
				[{NewKey,Value}|ResultList]
		end,
	NewKeyValueList = lists:foldl(F, [], KeyValueList), 
	NewKeyValueList = lib_equip:get_player_equip_attr(PlayerStatus, EquipList, all),
	TotalScore = lib_equip:calc_attr_score(NewKeyValueList),
	PS = lib_player:update_equip_score(PlayerStatus, TotalScore), 
	?TRACE("recount player equip attr ~n KeyValueList: ~n~p ~n end*********** ~n", [NewKeyValueList]), 
    update_battle_attr(PS, NewKeyValueList). 

%%战斗属性计算
calc_player_battle_attr(Status) -> 
    %% 初始化战斗属性
    InitBattleAttr = init_base_battle_attr(Status#player.level, Status#player.career, Status#player.battle_attr),
    Status1 = Status#player{battle_attr = InitBattleAttr},
    % 计算装备属性
    Status2 = recount_player_equip_attr(Status1),
    %%计算被动技能加成
    Status3 = lib_skill:add_skill_attr_to_player(Status2),
    Status4 = lib_mount:add_mount_attr_to_player(Status3),
    Status5 = lib_meridian:reflesh_player_meridian_state(Status4),
    Status6 = calc_player_force(Status5),  

    %%不计入战斗力部分属性
    Status7 = buff_util:readd_goods_buff(Status6), 
 
	Status7.


%%Update force
calc_player_force(Status) ->
    BattleAttr = Status#player.battle_attr,
    ForceAtt = BattleAttr#battle_attr.abs_damage*0.8 +
    BattleAttr#battle_attr.attack*0.5 +
    BattleAttr#battle_attr.hit_ratio*0.25 +
    BattleAttr#battle_attr.crit_ratio*0.25 +
    BattleAttr#battle_attr.dodge_ratio*0.25 +
    BattleAttr#battle_attr.tough_ratio*0.25 +
    BattleAttr#battle_attr.fdefense*0.2 +
    BattleAttr#battle_attr.mdefense*0.2 +
    BattleAttr#battle_attr.ddefense*0.2 +
    BattleAttr#battle_attr.defense*0.25 +
    BattleAttr#battle_attr.hit_point_max*0.05 +
    BattleAttr#battle_attr.magic_max*0.1,
    case Status#player.career of
        ?CAREER_F ->
            ForceAtt1 = round(ForceAtt + BattleAttr#battle_attr.fattack*0.6);
        ?CAREER_M ->
            ForceAtt1 = round(ForceAtt + BattleAttr#battle_attr.mattack*0.6);
        ?CAREER_D ->
            ForceAtt1 = round(ForceAtt + BattleAttr#battle_attr.dattack*0.6);
        _ ->
            ForceAtt1 = round(ForceAtt + BattleAttr#battle_attr.fattack*0.6)
    end,
%% 	ForceMon = lib_mount:get_fight_value(Status),
%% 	NewForce = ForceAtt1, 
    Status#player{force = ForceAtt1,max_force = max(ForceAtt1,Status#player.max_force)}.

%%复活处理
%%清掉技能的BUFF
revive(Status, here) -> 
	OldBattleAttr = Status#player.battle_attr,
	NewBattleAttr0 = OldBattleAttr#battle_attr{hit_point = round(OldBattleAttr#battle_attr.hit_point_max * data_config:get_config(here_revive_hp)),
											   magic = round(OldBattleAttr#battle_attr.magic_max * data_config:get_config(here_revive_mp)),
											   energy = OldBattleAttr#battle_attr.energy#energy{
																								energy_val = 0
																							   }},
	{BrocastPassiveEffect,NewBatttleAtte1} = lib_skill:passive_skill_call_back(NewBattleAttr0),
	lib_skill:borcast_passive_skill_effect(Status,NewBatttleAtte1,BrocastPassiveEffect),
	Status#player{battle_attr = NewBatttleAtte1};
revive(Status, city) -> 
    OldBattleAttr = Status#player.battle_attr,
    NewBattleAttr0 = OldBattleAttr#battle_attr{hit_point = round(OldBattleAttr#battle_attr.hit_point_max * data_config:get_config(city_revive_hp)),
        magic = round(OldBattleAttr#battle_attr.magic_max * data_config:get_config(city_revive_mp)),
        energy = OldBattleAttr#battle_attr.energy#energy{
            energy_val = 0
        }},
	{BrocastPassiveEffect,NewBatttleAtte1} = lib_skill:passive_skill_call_back(NewBattleAttr0),
	lib_skill:borcast_passive_skill_effect(Status,NewBatttleAtte1,BrocastPassiveEffect), 
    Status#player{battle_attr = NewBatttleAtte1}.

update_battle_attr(BattleAttr, []) ->
    BattleAttr;
update_battle_attr(Status, KeyValueList) when is_record(Status, player) ->
    TplBattleAttr= update_battle_attr(Status#player.battle_attr,KeyValueList),
	NewBattleAttr = TplBattleAttr#battle_attr{real_defense = TplBattleAttr#battle_attr.defense},
    Status#player{battle_attr = NewBattleAttr};
update_battle_attr(BattleAttr,KeyValueList) when is_record(BattleAttr, battle_attr) ->
    {NewBattleAttr,_} = update_battle_attr(BattleAttr,[],1,0, KeyValueList),
    NewBattleAttr.


%%更新玩家的战斗属性
%%先不作范围检查,看看有没有值出现负或过大的情况  
update_battle_attr(BattleAttr,ReturnInfo,_SkillLevel,_BuffType,[]) -> 
	{BattleAttr,ReturnInfo};

update_battle_attr(BattleAttr,ReturnInfo,SkillLevelOri,BuffType,[BuffEffectElement | T]) when is_record(BattleAttr, battle_attr) -> 
 	SkillLevel = max(SkillLevelOri,1),
	case size(BuffEffectElement) of
		2 ->
			{Key,Value1} = BuffEffectElement,
			Value2 = 0;
		3 -> 
			{Key,Value1,Value2} = BuffEffectElement;
		4 ->
			{Key,Value1,Value2,_} = BuffEffectElement;
		_ ->
			{Key,Value1} = BuffEffectElement,
			Value2 = 0
	end,
	if  is_list(Value1) ->
			Value  = Value2;
		true->
			Value = Value1*SkillLevel + Value2
	end,
	NewBattleAttr = 
		case Key of
			%%----------------------------------------------改变上下限----------------------------------------------------
			combopoint_max ->             %% 最大连击点数()
				ReturnVal1 = [],
				BattleAttr#battle_attr{combopoint_max = BattleAttr#battle_attr.combopoint_max + Value};
			combopoint ->                 %% 连击点数(技能消耗/获得的属性,可额外增加伤害率或防御率)
				ReturnVal1 = [],
				NewCombopoint = min(BattleAttr#battle_attr.combopoint_max, max(0, BattleAttr#battle_attr.combopoint + Value)),
				BattleAttr#battle_attr{combopoint = NewCombopoint};
			magic ->                      %% 法力值	  
				ReturnVal1 = [],
				NewMagic = min(BattleAttr#battle_attr.magic_max, max(0, BattleAttr#battle_attr.magic + Value)),
				BattleAttr#battle_attr{magic = NewMagic};
			magic_max ->                  %% 法力值上限	
				ReturnVal1 = [],
				BattleAttr#battle_attr{magic_max = BattleAttr#battle_attr.magic_max + Value};
			anger ->                      %% 怒气值	
				ReturnVal1 = [],
				NewAnger = min(BattleAttr#battle_attr.anger_max, max(0, BattleAttr#battle_attr.anger + Value)),
				BattleAttr#battle_attr{anger = NewAnger};
			anger_max ->                  %% 怒气值上限	
				ReturnVal1 = [],
				BattleAttr#battle_attr{anger_max = BattleAttr#battle_attr.anger_max + Value};
			
			%%----------------------------------------------增减属性值----------------------------------------------------
			attack ->                     %% 普通攻击力	
				ReturnVal1 = [],
				BattleAttr#battle_attr{attack = BattleAttr#battle_attr.attack + Value};
			attack_ratio ->               %% 普通攻击力伤害率(Buff附加值)              
				ReturnVal1 = [],  
				BattleAttr#battle_attr{attack_ratio = BattleAttr#battle_attr.attack_ratio + Value};
			defense ->                    %% 普通防御力
				ReturnVal1 = [], 
				io:format("[BUFF_PLAYER]~p ~n",[{BattleAttr#battle_attr.defense , Value}] ),
				AdditionDefense = BattleAttr#battle_attr.real_defense - BattleAttr#battle_attr.defense,
				BattleAttr#battle_attr{defense = BattleAttr#battle_attr.defense + Value,real_defense =BattleAttr#battle_attr.defense + Value+ AdditionDefense};
			defense_ratio ->              %% 普通防御力防御率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{defense_ratio = BattleAttr#battle_attr.defense_ratio + Value};
			abs_damage ->                 %% 绝对伤害值	
				ReturnVal1 = [],
				BattleAttr#battle_attr{abs_damage = BattleAttr#battle_attr.abs_damage + Value};
			fattack ->                    %% 仙攻值
				ReturnVal1 = [],
				BattleAttr#battle_attr{fattack = BattleAttr#battle_attr.fattack + Value};
			fattack_ratio ->              %% 仙攻值伤害率(Buff附加值)      
				ReturnVal1 = [],
				BattleAttr#battle_attr{fattack_ratio = BattleAttr#battle_attr.fattack_ratio + Value};
			mattack ->                    %% 魔攻值	
				ReturnVal1 = [],
				BattleAttr#battle_attr{mattack = BattleAttr#battle_attr.mattack + Value};
			mattack_ratio ->              %% 魔攻值伤害率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{mattack_ratio = BattleAttr#battle_attr.mattack_ratio + Value};
			dattack ->                    %% 妖攻值
				ReturnVal1 = [],
				BattleAttr#battle_attr{dattack = BattleAttr#battle_attr.dattack + Value};
			dattack_ratio ->              %% 妖攻值伤害率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{dattack_ratio = BattleAttr#battle_attr.dattack_ratio + Value};
			fdefense ->                   %% 仙防值
				ReturnVal1 = [],
				BattleAttr#battle_attr{fdefense = BattleAttr#battle_attr.fdefense + Value};
			fdefense_ratio ->             %% 仙防值防御率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{fdefense_ratio = BattleAttr#battle_attr.fdefense_ratio + Value};
			mdefense ->                   %% 魔防值
				ReturnVal1 = [],
				BattleAttr#battle_attr{mdefense = BattleAttr#battle_attr.mdefense + Value};
			mdefense_ratio ->             %% 魔防值防御率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{mdefense_ratio = BattleAttr#battle_attr.mdefense_ratio + Value};
			ddefense ->                   %% 妖防值
				ReturnVal1 = [],
				BattleAttr#battle_attr{ddefense = BattleAttr#battle_attr.ddefense + Value};
			ddefense_ratio ->             %% 妖防值防御率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{ddefense_ratio = BattleAttr#battle_attr.ddefense_ratio + Value};
			hit_ratio ->                  %% 命中率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{hit_ratio = BattleAttr#battle_attr.hit_ratio + Value};
			dodge_ratio ->                %% 闪避率(Buff附加值)	
				ReturnVal1 = [],
				BattleAttr#battle_attr{dodge_ratio = BattleAttr#battle_attr.dodge_ratio + Value};
			crit_ratio ->                 %% 暴击率(Buff附加值)
				ReturnVal1 = [],
				NewAbsCrit = BattleAttr#battle_attr.abs_crit_ratio + Value, 
				BattleAttr#battle_attr{crit_ratio = min(?MAX_CRIT_RATE,NewAbsCrit),abs_crit_ratio = NewAbsCrit} ;
			tough_ratio ->                %% 坚韧率(Buff附加值)
				ReturnVal1 = [],
				BattleAttr#battle_attr{tough_ratio = BattleAttr#battle_attr.tough_ratio + Value};
			avoid_attack_ratio ->         %% 受到普攻免伤害率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_attack_ratio = BattleAttr#battle_attr.avoid_attack_ratio + Value};
			avoid_fattack_ratio ->        %% 受到仙攻免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_fattack_ratio = BattleAttr#battle_attr.avoid_fattack_ratio + Value};
			avoid_mattack_ratio ->        %% 受到魔攻免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_mattack_ratio = BattleAttr#battle_attr.avoid_mattack_ratio + Value};
			avoid_dattack_ratio ->        %% 受到妖攻免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_dattack_ratio = BattleAttr#battle_attr.avoid_dattack_ratio + Value};
			avoid_crit_attack_ratio ->    %% 受到普攻暴击免伤害率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_crit_attack_ratio = BattleAttr#battle_attr.avoid_crit_attack_ratio + Value};
			avoid_crit_fattack_ratio ->   %% 受到仙攻暴击免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_crit_fattack_ratio = BattleAttr#battle_attr.avoid_crit_fattack_ratio + Value};
			avoid_crit_mattack_ratio ->   %% 受到魔攻暴击免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_crit_mattack_ratio = BattleAttr#battle_attr.avoid_crit_mattack_ratio + Value};
			avoid_crit_dattack_ratio ->   %% 受到妖攻暴击免伤率
				ReturnVal1 = [],
				BattleAttr#battle_attr{avoid_crit_dattack_ratio = BattleAttr#battle_attr.avoid_crit_dattack_ratio + Value};
			ignore_defense ->             %% 攻方忽略防方普防值(武魂引入)
				ReturnVal1 = [],
				BattleAttr#battle_attr{ignore_defense = BattleAttr#battle_attr.ignore_defense + Value};
			ignore_fdefense ->            %% 攻方忽略防方仙防值(武魂引入)
				ReturnVal1 = [],
				BattleAttr#battle_attr{ignore_fdefense = BattleAttr#battle_attr.ignore_fdefense + Value};
			ignore_mdefense ->            %% 攻方忽略防方魔防值(武魂引入)
				ReturnVal1 = [],
				BattleAttr#battle_attr{ignore_mdefense = BattleAttr#battle_attr.ignore_mdefense + Value};
			ignore_ddefense ->            %% 攻方忽略防方妖防值(武魂引入)
				ReturnVal1 = [],
				BattleAttr#battle_attr{ignore_ddefense = BattleAttr#battle_attr.ignore_ddefense + Value};
			hurted_energy_cover -> 	      %% 受击回复能量值
				ReturnVal1 = [],
				NewEnergy = BattleAttr#battle_attr.energy#energy{injured_rate =BattleAttr#battle_attr.energy#energy.injured_rate + Value},
				BattleAttr#battle_attr{energy = NewEnergy};
			freeze_energy_cover ->   %%停止能量值回复
				ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_FREEZE_ENERGY,Value2}],
				if Value1 >0 ->
					   NewEnergy = BattleAttr#battle_attr.energy#energy{freeze_second =BattleAttr#battle_attr.energy#energy.freeze_second+ Value1};
				   true ->
					   NewEnergy = BattleAttr#battle_attr.energy
				end,
				BattleAttr#battle_attr{energy = NewEnergy};
			%%--------------------------------------------------------------------------------------------------
			demage when BattleAttr#battle_attr.hit_point >0 -> %%buff伤害
				ReturnVal1 = [],
				BattleAttr#battle_attr{
									   demage_buff_list = [BuffEffectElement|BattleAttr#battle_attr.demage_buff_list]
									  } ;		 			
			%----------------------------------------------------------------------------------------------------
			status_stop ->                %%定身 Value1为+-1,-1时候表示解除石化,Value2表示持续时间 
			
				if Value1 > 0 ->%%添加束缚效果 
					   if BattleAttr#battle_attr.status_unstoptable > 0 -> %如果身上有免疫控制buff,定身buff失效 
							  ReturnVal1  =[],
							  BattleAttr;
						  true ->  
						 	  ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_FREEZE,Value2}],
							  BattleAttr#battle_attr{status_stop =  max(BattleAttr#battle_attr.status_stop + Value1,0)}
					   end;
				   true ->
					   ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_FREEZE,Value2}],
					   BattleAttr#battle_attr{status_stop =  max(BattleAttr#battle_attr.status_stop + Value1,0)}
				end;
			status_silent ->              %%沉默 Value1为+-1 ，-1时候表示沉默石化,Value2表示持续时间
				if Value1 > 0 ->
					   if BattleAttr#battle_attr.status_unstoptable > 0 -> %如果身上有免疫控制buff,沉默buff失效
							  ReturnVal1  =[],
							  BattleAttr;
						  true ->
							  ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_SILENT,Value2}],
							  BattleAttr#battle_attr{status_silent =  max(BattleAttr#battle_attr.status_silent + Value1,0)}
					   end;
				   true ->
					   ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_SILENT,Value2}],
					   BattleAttr#battle_attr{status_silent =  max(BattleAttr#battle_attr.status_silent + Value1,0)}
				end;  
			unattrackable ->  %%禁止攻击
				ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_UNATTRACKABLE,0}],
				BattleAttr#battle_attr{status_unattrackable =  max(BattleAttr#battle_attr.status_unattrackable + Value1,0)} ; 
			unstoptable ->				 %%免疫控制 Value1为+-1 ，-1时候表示解除免疫控制,Value2表示持续时间
				ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_UNSTOPTABLE,Value2}], 
				BattleAttr#battle_attr{status_unstoptable = max(BattleAttr#battle_attr.status_unstoptable + Value1,0) };
			%%--------------------------------------------------------------------------------------------------
			hit_point ->                  %% 血量	   
				NewAddVal = Value*(100+BattleAttr#battle_attr.hp_cover_callback)/100,
				NewHitPoint = util:ceil(min(BattleAttr#battle_attr.hit_point_max, max(0, BattleAttr#battle_attr.hit_point + NewAddVal))),
				ReturnVal0 = [{?BUFF_TYPE_HP,?BUFF_EFFECT_HP,{Value,NewHitPoint}}], 
				?TRACE("%%% pre Hp ~p ,New hp ~p ,add hp ~p ~n",[BattleAttr#battle_attr.hit_point,NewHitPoint,Value]),
				{PassBuff,PassiveBattleAttr} = lib_skill:passive_skill_call_back(BattleAttr#battle_attr{hit_point = NewHitPoint}),
				ReturnVal1 = PassBuff++ReturnVal0,
				PassiveBattleAttr; 
			hit_point_max ->              %% 血量上限	 
				{ReturnVal1,PassiveBattleAttr} = lib_skill:passive_skill_call_back(BattleAttr#battle_attr{hit_point_max = BattleAttr#battle_attr.hit_point_max + Value}),
				PassiveBattleAttr;
			energy_val ->                     %%能量值  
				NewBattleAttr0  = energy_util:cover_percent_energy(BattleAttr, Value),
				if Value > 0 ->
					   Flag = 1;
				   true ->
					   Flag = 2
				end,
				ReturnVal1 = [{?BUFF_TYPE_CRICLE,?BUFF_EFFECT_ENERGY,{Value,Flag}}],
				NewBattleAttr0; 
			%%--------------------------------------------------------------------------------------------------
			change_appearance ->          %%改变外观 Value1外观资源号 Value2持续时间
				ReturnVal1 = [{?BUFF_TYPE_APPRENCE,Value1,Value2}],
				if Value2 < 0 ->
					   NewAppearance = 0;
				   true ->
					   NewAppearance = Value1
				end,  
				BattleAttr#battle_attr{change_appearance = NewAppearance}; 
			attack_speed ->               %% 攻击速度	Value1为攻速   Value2为持续时间   
				NewAttrSpeed =  BattleAttr#battle_attr.attack_speed  + ?COMMON_ATTR_SPEED*Value1 div 100,
				ReturnVal1 = [{?BUFF_TYPE_PROPERTY,?BUFF_EFFECT_ATTR_SPEED,NewAttrSpeed}], 
				BattleAttr#battle_attr{attack_speed = NewAttrSpeed}; 
			add_speed ->                      %% 增加移动速度 
				{TmpBattleAttr,ReturnVal1} = reflesh_player_speed(BattleAttr,Value1,Value2), 
				TmpBattleAttr; 
			reduce_speed ->                      %% 减少移动速度    
				if Value1 < 0 -> 
					   if BattleAttr#battle_attr.status_unstoptable > 0 -> %如果身上有免疫控制buff,buff失效  
							  ReturnVal1  =[],
							  BattleAttr;
						  true ->  
							  {ReturnVal1,TmpBattleAttr} = reflesh_player_speed(BattleAttr,Value1,Value2), 
							   TmpBattleAttr
					   end;
				   true ->
					   {ReturnVal1,TmpBattleAttr} = reflesh_player_speed(BattleAttr,Value1,Value2), 
					    TmpBattleAttr
				end; 
			hurt_call_back ->		%%反伤百分比  
				NewHurtCallBack = BattleAttr#battle_attr.hurt_call_back+Value1 ,
				ReturnVal1 = [],
				BattleAttr#battle_attr{hurt_call_back = NewHurtCallBack};
			damage_reduction ->	    %%吸收伤害  
				{_,_,_,Effect} = BuffEffectElement,
				{NewDamageReduction,NewDamageReductionQueue} = 
					reflesh_damage_reduction(BattleAttr#battle_attr.damage_reduction_queue,BattleAttr#battle_attr.damage_reduction,Value1,Value2,Effect),
				{_,_,_,NewEffect} = NewDamageReduction, 
				ReturnVal1 = [{?BUFF_TYPE_REDUCTION,?BUFF_EFFECT_DAMGE_REDUNCTION,NewEffect}],
			 		BattleAttr#battle_attr{damage_reduction_queue = NewDamageReductionQueue,damage_reduction = NewDamageReduction};
			attack_callback_rate ->	%%能量值回复倍数
				NewEnergy = BattleAttr#battle_attr.energy#energy{attack_callback_rate = BattleAttr#battle_attr.energy#energy.attack_callback_rate + Value},
				ReturnVal1 = [],
				BattleAttr#battle_attr{energy = NewEnergy};
			change_body_color ->	%%身体变色 101 红 102 蓝 103 绿
				ReturnVal1 = [{?BUFF_TYPE_STATUS,abs(Value1),Value2}],
				BattleAttr;
			dot_damage -> %%dot伤害  
				if BattleAttr#battle_attr.reduce_dot_damage > 0 ->
					   NewAddVal = -Value2;
				   true ->
					   NewAddVal = -(Value1*BattleAttr#battle_attr.hit_point_max/1000 + Value2)
				end,
				NewHitPoint = util:ceil(min(BattleAttr#battle_attr.hit_point_max, max(0, BattleAttr#battle_attr.hit_point + NewAddVal))),
				ReturnVal0 = [{?BUFF_TYPE_HP,?BUFF_EFFECT_HP,{NewAddVal,NewHitPoint}}],  
				{PassBuff,PassiveBattleAttr} = lib_skill:passive_skill_call_back(BattleAttr#battle_attr{hit_point = NewHitPoint}),
				ReturnVal1 = PassBuff++ReturnVal0,
				PassiveBattleAttr; 
			remove_buff -> %%移除buff
				ReturnVal1 = [],
				BattleAttr#battle_attr{remove_buff_list = [Value2|BattleAttr#battle_attr.remove_buff_list]}; 
			invincible ->%%无敌 
				ReturnVal1 = [],
				BattleAttr#battle_attr{invincible =  max(BattleAttr#battle_attr.invincible + Value,0)}; 
			remove_stop_status ->%%移除定身状态
				ReturnVal1 = [{?BUFF_TYPE_STATUS,?BUFF_EFFECT_FREEZE,-1}],
				BattleAttr#battle_attr{status_stop =  0};
			reduce_dot -> %%忽略dot千分比伤害
				ReturnVal1 = [ ],
				BattleAttr#battle_attr{reduce_dot_damage =  max(BattleAttr#battle_attr.invincible + Value1,0)}; 
			real_real_defense -> %%真实防御力
				ReturnVal1 = [ ],
				NewAddRealDefense = util:ceil(BattleAttr#battle_attr.defense*Value1/1000+Value2),
			 	BattleAttr#battle_attr{real_defense = BattleAttr#battle_attr.real_defense+NewAddRealDefense}; 
			_Other ->
				%?WARNING_MSG("apply_effect: Unknown Key: ~p Value: ~p~n", [Key, Value]),
				ReturnVal1 = [],
				BattleAttr
		end,  
	if ReturnVal1 =:= [] ->
		   update_battle_attr(NewBattleAttr, ReturnInfo,SkillLevel,BuffType, T);
	   true -> 
		   update_battle_attr(NewBattleAttr, ReturnVal1++ReturnInfo,SkillLevel,BuffType, T)
	end;
update_battle_attr(Other, _KeyVList,_,_,_)  ->
	%?WARNING_MSG("update_battle_attr: Unknown record: ~p,  Value: ~p~n", [Other, _KeyVList]),
	{Other,[]} .

%%更新玩家的帮派信息
update_guild(Status) ->
    db_agent_player:save_player_table(
        Status#player.id, 
        [guild_id, guild_name, guild_post],
        [Status#player.guild_id, Status#player.guild_name, Status#player.guild_post]
    ).

%% 发送提示语
send_tips(TipsId,ParamList,PidSend) ->
    {ok,DataBin} = pt_11:write(11021,[TipsId,ParamList]) ,
    lib_send:send_to_sid(PidSend, DataBin) .

handle_charge_order(Status) ->
    case db_agent_charge:get_charge_order(Status#player.account_id, ?UNHANDLE_CHARGE_ORDER) of
        [] -> Status;
        List -> 
            F = fun([OrderId, Gold, OrderStatus, Amount, CreateTime, DimLev, PayWay], Status1) ->
                    if OrderStatus =:= ?CHARGE_ORDER_STATUS_SUCCESSFUL -> 
                            db_agent_log:insert_charge_log(Status1#player.id, Status1#player.account_id, DimLev, Gold, PayWay, OrderId, Amount, CreateTime),
                            NewStatus2 = lib_money:give_role_money(Gold, Status1, ?MONEY_T_GOLD, ?LOG_MONEY_CHARGE),
                            NewStatus = lib_vip:chargeVip(NewStatus2,Gold);
                        true ->
                            NewStatus = Status1
                    end,
                    db_agent_charge:update_charge_order(OrderId, ?HANDLE_CHARGE_ORDER),
                    NewStatus
            end,
            lists:foldl(F, Status, List)
    end.
    %lib_vip:check_charge_vip(Status). %%检查通过充值获得VIP情况

%----------------------
%-	伤害吸收接口
%----------------------

battle_call_back_defend_reduction(Status,RemoveVal) ->
	{DamageReduction,NewDamageReductionQueue} = 
		lib_player:reflesh_damage_reduction(Status#player.battle_attr#battle_attr.damage_reduction_queue,Status#player.battle_attr#battle_attr.damage_reduction,RemoveVal),
	NewBattleAttr = Status#player.battle_attr#battle_attr{damage_reduction = DamageReduction,damage_reduction_queue = NewDamageReductionQueue},
	Status#player{battle_attr = NewBattleAttr}.

reflesh_damage_reduction(DamageReductionQueue,DamageReduction,DefensePercent,NewVal,Effect)->
	if NewVal >0 ->
		   apply_damage_reduction(add,DamageReductionQueue,DamageReduction,DefensePercent,NewVal,Effect);
	   true ->
		   apply_damage_reduction(remove,DamageReductionQueue,DamageReduction,DefensePercent,NewVal,Effect)
	end.  

apply_damage_reduction(add,DamageReductionQueue,DamageReduction,DefensePercent,NewVal,Effect)->
	{_,LastVal,_,_} = DamageReduction,
	NewDamageReductionQueue =lists:reverse( lists:sort([{NewVal,DefensePercent,Effect}|DamageReductionQueue])),
	if LastVal =< NewVal ->
		   {{NewVal,NewVal,DefensePercent,Effect},NewDamageReductionQueue};
	   true ->
		   {DamageReduction,NewDamageReductionQueue}
	end;  
apply_damage_reduction(remove,DamageReductionQueue,DamageReduction,_,RemoveVal,_) ->
	NewRemoveVal = -RemoveVal,
	{_,LastVal,_,_} = DamageReduction,
	NewDamageReductionQueue =lists:keydelete(NewRemoveVal,1, DamageReductionQueue),
	if LastVal =:= NewRemoveVal ->
		   if NewDamageReductionQueue =:= [] -> 
				  {{0,0,0,""},[]};
			  true ->
				  [{NewVal,DefensePercent,NewEffect}|_] = NewDamageReductionQueue, 
				  {{NewVal,NewVal,DefensePercent,NewEffect},NewDamageReductionQueue}
		   end;
	   true ->
		   {DamageReduction,NewDamageReductionQueue}
	end.
%%---------------------
%- 玩家攻速移速相关接口
%----------------------
%攻速移速buff效果
reflesh_common_speed(Flag,CommonSpeedQueue,NewVal,CommonSpeed,TplVal)-> 
	case Flag >0 of
		true -> 
			apply_common_speed(add,CommonSpeedQueue,NewVal,CommonSpeed,TplVal);
		false -> 
			apply_common_speed(remove,CommonSpeedQueue,NewVal,CommonSpeed,TplVal)
	end.
%%------------------
%-	攻速移速内部接口
%-------------------
apply_common_speed(add,{ActiveQueue,PassiveQueue},NewVal,CommonSpeed,TplVal)->
	if NewVal > 0 ->
		   {NewMoveSpeed,NewActiveQueue} =  add_active_common_speed(ActiveQueue,NewVal,CommonSpeed,TplVal),
		   {NewMoveSpeed,{NewActiveQueue,PassiveQueue}};
	   true ->
		   {NewMoveSpeed,NewPassiveQueue} =  add_passive_common_speed(PassiveQueue,NewVal,CommonSpeed,TplVal),
		   {NewMoveSpeed,{ActiveQueue,NewPassiveQueue}}
	end;
apply_common_speed(remove,{ActiveQueue,PassiveQueue},NewVal,CommonSpeed,TplVal) ->
	if NewVal > 0->
		   {NewMoveSpeed,NewPassiveQueue} =  remove_common_speed(PassiveQueue,NewVal,CommonSpeed,TplVal),
		   {NewMoveSpeed,{ActiveQueue,NewPassiveQueue}};
	   true ->
		   {NewMoveSpeed,NewActiveQueue} =  remove_common_speed(ActiveQueue,NewVal,CommonSpeed,TplVal),
		   {NewMoveSpeed,{NewActiveQueue,PassiveQueue}}
	end. 
%%移除效果
remove_common_speed({LastVal,List},RemoveVal,MoveSpeed,TplVal)->
	TrueRemoveVal = -RemoveVal,
	NewLists = lists:delete(TrueRemoveVal, List),
	if LastVal =:= TrueRemoveVal ->
		   case  NewLists of
			   [] ->
				   NewMoveSpeed = MoveSpeed + TplVal*RemoveVal div 100  ,
				   {NewMoveSpeed,{0,[]}};
			   _->
				   [MaxVal|_] = NewLists,
				   NewMoveSpeed = MoveSpeed + TplVal*RemoveVal div 100  + TplVal*MaxVal div 100,
				   {NewMoveSpeed,{MaxVal,NewLists}}
		   end;
	   true ->
		   {MoveSpeed,{LastVal,NewLists}}
	end.
%%应用加速类逻辑接口
add_active_common_speed({LastVal,List},NewVal,CommonSpeed,TplVal)->
	if LastVal < NewVal ->
		   NewCommonSpeed = CommonSpeed -  TplVal*LastVal div 100 + TplVal*NewVal div 100,
		   {NewCommonSpeed,{NewVal,lists:reverse(lists:sort([NewVal|List]))}};
	   true ->
		   {CommonSpeed,{LastVal,lists:sort([NewVal|List])}}
	end.
%%应用减速类逻辑接口
add_passive_common_speed({LastVal,List},NewVal,CommonSpeed,TplVal)->  
	if LastVal > NewVal ->
		   NewCommonSpeed = CommonSpeed -  TplVal*LastVal div 100 + TplVal*NewVal div 100,
		   {NewCommonSpeed,{NewVal,lists:sort([NewVal|List])}};
	   true ->
		   {CommonSpeed,{LastVal,lists:sort([NewVal|List])}}
	end.
%%刷新玩家移动速度
reflesh_player_speed(BattleAttr,Value1,Value2)->
		{NewMoveSpeed,NewSpeedQueue} = 
					reflesh_common_speed(Value2,BattleAttr#battle_attr.move_speed_queue,Value1,BattleAttr#battle_attr.speed,?COMMON_MOVE_SPEED),  
				if BattleAttr#battle_attr.speed =/= NewMoveSpeed ->
					   ReturnVal1 = [{?BUFF_TYPE_PROPERTY,?BUFF_EFFECT_MOVE_SPEED,NewMoveSpeed}];
				   true ->
					   ReturnVal1 = []
				end,
				{ReturnVal1,BattleAttr#battle_attr{speed = NewMoveSpeed,move_speed_queue = NewSpeedQueue}}.

