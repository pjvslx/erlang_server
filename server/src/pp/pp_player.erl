%%%--------------------------------------
%%% @Module  : pp_player
%%% @Author  : 
%%% @Created : 
%%% @Description: 角色功能管理  
%%%--------------------------------------
-module(pp_player).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("leader.hrl").

%% API Functions
handle(Cmd, Player, Data) ->
    ?TRACE("pp_player: Cmd:~p, Player:~p, Level:~p, Data:~p~n", [Cmd, Player#player.id, Player#player.level, Data]),
    handle_cmd(Cmd, Player, Data).

%%--------------------------------------
%%Protocol: 13000 玩家自身信息(FULL)
%%--------------------------------------
handle_cmd(13000, Status, _) ->
    ExpNextLevel = data_player:next_level_exp(Status#player.career, Status#player.level), 
    [Weapon, Armor, Fashion, WwaponAcc, Wing] = Status#player.other#player_other.equip_current, 
    IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if  IsMountOpen == true ->
            Mount = 1,
            MountInfo = lib_mount:get_mount(Status#player.id),
            if 
                MountInfo == [] ->
                    MountFashion = 0;
                true ->
                    MountFashion = MountInfo#mount.fashion
            end;
        true ->
            Mount = 0,
            MountFashion = 0
    end,

    NowTime = util:unixtime(),
    if
        Status#player.vip_expire_time < NowTime ->
            NewVipLevel = 0;
        true ->
            NewVipLevel = Status#player.vip
    end,
    pack_and_send(Status, 13000, [ Status#player.id,
            Status#player.gender,
            Status#player.level,
            Status#player.career,
            Status#player.camp,
            NewVipLevel,
            Status#player.vip_expire_time,
            Status#player.icon,
            Status#player.scene,
            Status#player.battle_attr#battle_attr.x,
            Status#player.battle_attr#battle_attr.y,
            Status#player.liveness,
            Status#player.exp,
            ExpNextLevel,
            Status#player.lilian,
            Status#player.gold,
            Status#player.bgold,
            Status#player.coin,
            Status#player.bcoin,
            Status#player.force,
            Status#player.battle_attr#battle_attr.hit_point,
            Status#player.battle_attr#battle_attr.hit_point_max,
            Status#player.battle_attr#battle_attr.combopoint,
            Status#player.battle_attr#battle_attr.combopoint_max,
            util:floor(Status#player.battle_attr#battle_attr.energy#energy.energy_val),
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
            Status#player.battle_attr#battle_attr.tough_ratio,
            Status#player.battle_attr#battle_attr.frozen_resis_ratio,
            Status#player.battle_attr#battle_attr.weak_resis_ratio,
            Status#player.battle_attr#battle_attr.flaw_resis_ratio,
            Status#player.battle_attr#battle_attr.poison_resis_ratio,
            Status#player.battle_attr#battle_attr.ignore_defense,
            Status#player.battle_attr#battle_attr.ignore_fdefense,
            Status#player.battle_attr#battle_attr.ignore_mdefense,
            Status#player.battle_attr#battle_attr.ignore_ddefense,
            Status#player.nick,
            Weapon, Armor, Fashion, WwaponAcc, Wing, Mount,
            Status#player.other#player_other.weapon_strenLv, 
            Status#player.other#player_other.armor_strenLv, 
            Status#player.other#player_other.fashion_strenLv, 
            Status#player.other#player_other.wapon_accstrenLv, 
            Status#player.other#player_other.wing_strenLv,
            Status#player.other#player_other.pet_status,
            Status#player.other#player_other.pet_quality_lv,
            Status#player.other#player_other.pet_facade,
            Status#player.other#player_other.pet_name,
            0,
            MountFashion,
            Status#player.guild_id, %%帮派id
            Status#player.guild_name %% 帮派
        ]);

%%--------------------------------------
%%Protocol: 13001 查询玩家自身信息(基本)
%%--------------------------------------
handle_cmd(13001, Status, _) ->
    ExpNextLevel = data_player:next_level_exp(Status#player.career, Status#player.level),
    pack_and_send(Status, 13001, [ Status#player.id,
            Status#player.gender,
            Status#player.level,
            Status#player.career,
            Status#player.battle_attr#battle_attr.speed,
            Status#player.scene,
            Status#player.battle_attr#battle_attr.x,
            Status#player.battle_attr#battle_attr.y,
            Status#player.battle_attr#battle_attr.hit_point,
            Status#player.battle_attr#battle_attr.hit_point_max,
            Status#player.exp,
            ExpNextLevel,
            Status#player.gold,
            Status#player.bgold,
            Status#player.coin,
            Status#player.bcoin,
            Status#player.nick
        ]);

%%--------------------------------------
%%Protocol: 13002 查看其他玩家
%%--------------------------------------
handle_cmd(13002, Status, [Uid]) ->
    case lib_player:get_user_info_by_id(Uid) of
        PlayerStatus when is_record(PlayerStatus, player) -> 
            skip;
        _Other ->
            PlayerStatus = []        
    end,
    if is_record(PlayerStatus, player) -> 
            ExpNextLevel = data_player:next_level_exp(PlayerStatus#player.career, PlayerStatus#player.level),
            pack_and_send(Status, 13002, [1,PlayerStatus#player.online_flag,
                    PlayerStatus#player.id,
                    PlayerStatus#player.gender,
                    PlayerStatus#player.level,
                    PlayerStatus#player.career,
                    PlayerStatus#player.camp,
                    PlayerStatus#player.vip,
                    PlayerStatus#player.icon,
                    PlayerStatus#player.scene,
                    PlayerStatus#player.battle_attr#battle_attr.x,
                    PlayerStatus#player.battle_attr#battle_attr.y,
                    PlayerStatus#player.liveness,
                    PlayerStatus#player.exp,
                    ExpNextLevel,
                    PlayerStatus#player.lilian,
                    PlayerStatus#player.gold,
                    PlayerStatus#player.bgold,
                    PlayerStatus#player.coin,
                    PlayerStatus#player.bcoin,
                    PlayerStatus#player.force,
                    PlayerStatus#player.battle_attr#battle_attr.hit_point,
                    PlayerStatus#player.battle_attr#battle_attr.hit_point_max,
                    PlayerStatus#player.battle_attr#battle_attr.combopoint,
                    util:floor(Status#player.battle_attr#battle_attr.energy#energy.energy_val),
                    Status#player.battle_attr#battle_attr.energy#energy.max_energy,
                    PlayerStatus#player.battle_attr#battle_attr.anger,
                    PlayerStatus#player.battle_attr#battle_attr.anger_max,
                    PlayerStatus#player.battle_attr#battle_attr.attack,
                    PlayerStatus#player.battle_attr#battle_attr.defense,
                    PlayerStatus#player.battle_attr#battle_attr.abs_damage,
                    PlayerStatus#player.battle_attr#battle_attr.fattack,
                    PlayerStatus#player.battle_attr#battle_attr.mattack,
                    PlayerStatus#player.battle_attr#battle_attr.dattack,
                    PlayerStatus#player.battle_attr#battle_attr.fdefense,
                    PlayerStatus#player.battle_attr#battle_attr.mdefense,
                    PlayerStatus#player.battle_attr#battle_attr.ddefense,
                    PlayerStatus#player.battle_attr#battle_attr.speed,
                    PlayerStatus#player.battle_attr#battle_attr.attack_speed,
                    PlayerStatus#player.battle_attr#battle_attr.hit_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.dodge_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.crit_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.tough_ratio,
                    PlayerStatus#player.nick
                ]);
        true ->
            pack_and_send(Status, 13002, [0])
    end;

%%--------------------------------------
%%Protocol: 13003 更新玩家信息
%%--------------------------------------
handle_cmd(13003, Status, _) ->
    lib_player:send_player_attribute1(Status);

%%--------------------------------------
%%Protocol: 13004 更新玩家战力信息
%%--------------------------------------
handle_cmd(13004, Status, _) ->  
    lib_player:send_player_attribute2(Status);

%%--------------------------------------
%%Protocol: 13005 更新玩家信息(金钱)
%%--------------------------------------
handle_cmd(13005, Status, _) ->
    lib_player:send_player_attribute3(Status);

%%--------------------------------------
%%Protocol: 13006 关键常用玩家信息(金钱,经验)
%%--------------------------------------
handle_cmd(13006, Status, _) ->
    lib_player:send_player_attribute4(Status);

%%--------------------------------------
%%Protocol: 13008 开通vip
%%--------------------------------------
handle_cmd(13008, Status, [VIPLevel]) ->
    NowTime = util:unixtime(),
    VipRcd = tpl_vip:get(VIPLevel),

    if
        VIPLevel =< 0 orelse VIPLevel > 5 ->
            pack_and_send(Status, 13008, [2,Status#player.vip,VIPLevel,0]),
            io:format("Parameter Error!~n");%%参数错误
        Status#player.vip =:= 6 ->
            pack_and_send(Status, 13008, [3,Status#player.vip,VIPLevel,0]),
            io:format("Is already vip, do not need to reactivite!~n");%%已为至尊VIP，不需要重复开通
        true ->
            if
                Status#player.vip > 0 andalso Status#player.vip_expire_time > NowTime ->%%玩家当前VIP属性未失效
                    CostGold = VipRcd#temp_vip.cost,%%消耗金币
                    VipExpireTime = VipRcd#temp_vip.vip_time*60 + Status#player.vip_expire_time; %%延期
                true -> %%玩家本来就不是vip或VIP已失效
                    CostGold = VipRcd#temp_vip.cost,%%消耗金币
                    VipExpireTime = VipRcd#temp_vip.vip_time*60 + NowTime %%激活
            end,
            if
                CostGold > Status#player.gold ->
                    pack_and_send(Status, 13008, [4,Status#player.vip,VIPLevel,0]),
                    io:format("Not Enough Gold!~n");%%金币不足
                true ->
                    %%开通VIP
                    lib_vip:activiteVip(Status,VIPLevel,CostGold,VipExpireTime)
            end
    end;

%%--------------------------------------
%%Protocol: 13009 领取vip每日奖励
%%--------------------------------------
handle_cmd(13009, Status, [VIPLevel]) ->
    NowTime = util:unixtime(),
    DataFirstTime = util:getDataFirstTime(),

    VipAwardLog = db_agent_vip:get_award_log_by_accountid(Status#player.account_id,Status#player.vip),
    if
        is_list(VipAwardLog) andalso length(VipAwardLog) > 0 ->
            [_,_,_,CreateTime] = VipAwardLog;
        true ->
            CreateTime = 0
    end,

    if
        VIPLevel =< 0 orelse VIPLevel > 6 ->
            pack_and_send(Status, 13009, [2,0]),
            io:format("Parameter Error!~n");%%参数错误
        Status#player.vip =/= VIPLevel ->
            pack_and_send(Status, 13009, [3,0]),
            io:format("Not Match Requirement!~n");%%很抱歉，您没达到领取条件，不可领取
        CreateTime >= DataFirstTime ->
            pack_and_send(Status, 13009, [4,0]),
            io:format("Have got award!~n");%%您已领取了奖励，不可重复领取
        Status#player.vip_expire_time < NowTime ->
            pack_and_send(Status, 13009, [5,0]),
            io:format("vip has expire!~n");%%抱歉，您的vip已过期，不可以领取奖励
        true ->
            db_agent_vip:create_award_log(Status#player.account_id,Status#player.vip,NowTime),
            VipRcd = tpl_vip:get(Status#player.vip),
            goods_util:send_goods_to_role([{VipRcd#temp_vip.vip_goods_bag, 1}], Status, 0),
            io:format("Get Award Successfully,vip_goods_bag:~p~n",[VipRcd#temp_vip.vip_goods_bag]),
            pack_and_send(Status, 13009, [1,VipRcd#temp_vip.vip_goods_bag])
    end;

%%--------------------------------------
%%Protocol: 13011 玩家已购买金币数、领取奖励状态
%%--------------------------------------
handle_cmd(13011, Status, [VIPLevel]) ->
    NowTime = util:unixtime(),
    
    TotalChargeOri = db_agent_log:get_log_charge(Status#player.account_id),
    if
        TotalChargeOri =:= undefined ->
            TotalCharge = 0;
        true ->
            TotalCharge = TotalChargeOri
    end,

    if
        Status#player.vip =:= VIPLevel ->
            VipAwardLog = db_agent_vip:get_award_log_by_accountid(Status#player.account_id,Status#player.vip),
            DataFirstTime = util:getDataFirstTime(),
            if
                is_list(VipAwardLog) andalso length(VipAwardLog) > 0 ->
                    [_,_,_,CreateTime] = VipAwardLog;
                true ->
                    CreateTime = 0
            end,

            if 
                CreateTime > DataFirstTime andalso Status#player.vip > 0 andalso Status#player.vip_expire_time >  NowTime ->
                    AwardStatus = 0;
                true ->
                    AwardStatus = 1
            end;
        true ->
            AwardStatus = 0
    end,
    pack_and_send(Status, 13011, [TotalCharge,AwardStatus]);

handle_cmd(Cmd, Player, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Id:~p, Data:~p~n", [Cmd, Player#player.id, Data]),
    {ok, error}.

pack_and_send(Player, Cmd, Data) ->
    %%     ?TRACE("pp_player:pack_and_send Cmd:~p, Player:~p, Data:~p~n", [Cmd, Player#player.id, Data]),
    {ok, BinData} = pt_13:write(Cmd, Data),
    lib_send:send_to_sid(Player#player.other#player_other.pid_send, BinData).
