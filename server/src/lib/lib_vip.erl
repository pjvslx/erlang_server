%%-----------------------------------
%% @Module  	: lib_vip
%% @Author  	: cxf
%% @Created 	: 2013.08.07
%% @Description: VIP  
%%-----------------------------------
-module(lib_vip).

-compile(export_all).
-include("common.hrl").
-include("record.hrl").


activiteVip(PlayerStatus,VIPLevel,CostGold,VipExpireTime) ->
    VipRcd = tpl_vip:get(VIPLevel),

    NewVipLevel = max(PlayerStatus#player.vip,VIPLevel),

    %%db_agent_player:save_player_table(PlayerStatus#player.id, [vip,vip_expire_time], [NewVipLevel,VipExpireTime]),

    PlayerStatus2 = PlayerStatus#player{
        vip = NewVipLevel,
        vip_expire_time = VipExpireTime,
        cell_num = PlayerStatus#player.cell_num + VipRcd#temp_vip.freebag,
        gold = PlayerStatus#player.gold - CostGold
    },

    if
        PlayerStatus#player.freefly < VipRcd#temp_vip.freefly ->
            PlayerStatusNew = PlayerStatus2#player{freefly = VipRcd#temp_vip.freefly};
        true ->
            PlayerStatusNew = PlayerStatus2
    end,

    if
        CostGold > 0 ->
            db_agent_player:save_player_table(PlayerStatusNew#player.id, [gold], [PlayerStatusNew#player.gold]);
        true ->
            skip
    end,

    %%处理Buff
    if
        VipRcd#temp_vip.vip_buff_id > 0 ->
            {Code,ReturnObj} = buff_util:add_goods_buff(PlayerStatusNew,VipRcd#temp_vip.vip_buff_id),
            if
                is_record(ReturnObj,player) ->
                    PlayerStatusNew2 = ReturnObj;
                true ->
                    PlayerStatusNew2 = PlayerStatusNew
            end;
        true ->
            PlayerStatusNew2 = PlayerStatusNew
    end,


    pp_player:pack_and_send(PlayerStatusNew2, 13008, [1,PlayerStatus#player.vip,NewVipLevel,VipExpireTime]),
    lib_player:send_player_attribute3(PlayerStatusNew2),

    NowTime = util:unixtime(),
    erlang:send_after((PlayerStatusNew2#player.vip_expire_time - NowTime)*1000,PlayerStatusNew2#player.other#player_other.pid, 'VIP_TIMER'),
    {ok,PlayerStatusNew2}.

%%完成任务获得VIP体验
check_task_vip(Task,PlayerStatus) ->
    TaskId = Task#tpl_task.tid,
    ExperienceVip = tpl_vip:get(?VIP_LV_1),
    if
        is_record(ExperienceVip,temp_vip) ->
            VipTaskId = ExperienceVip#temp_vip.condition,
            if
                VipTaskId =:= TaskId ->
                    Time = util:unixtime() + ExperienceVip#temp_vip.vip_time*60,
                    {ok,NewPlayerStatus} = lib_vip:activiteVip(PlayerStatus,?VIP_LV_1, 0,Time);
                true ->
                    NewPlayerStatus = PlayerStatus
            end;
        true ->
            NewPlayerStatus = PlayerStatus
    end,
    NewPlayerStatus.


%%使用某物品获得VIP资格
check_goods_vip(GoodsTid,PlayerStatus) ->
    NowTime = util:unixtime(),

    Vip2 = tpl_vip:get(?VIP_LV_2),
    Vip3 = tpl_vip:get(?VIP_LV_3),
    Vip4 = tpl_vip:get(?VIP_LV_4),
    Vip5 = tpl_vip:get(?VIP_LV_5),

    %%[为了方便判定绑定and非绑定卡，暂时写死触发条件]
    %%TargetGId2 = Vip2#temp_vip.condition,
    %%TargetGId3 = Vip3#temp_vip.condition,
    %%TargetGId4 = Vip4#temp_vip.condition,
    %%TargetGId5 = Vip5#temp_vip.condition,

    if
        GoodsTid =:= 495014202 orelse GoodsTid =:= 494014202->
            NewVipLevel = max(PlayerStatus#player.vip,2),
            if
                PlayerStatus#player.vip_expire_time < NowTime ->
                    VipExpireTime = Vip2#temp_vip.vip_time*60 + NowTime;
                true ->
                    VipExpireTime = PlayerStatus#player.vip_expire_time + Vip2#temp_vip.vip_time*60
            end,
            {ok,NewPlayerStatus} = lib_vip:activiteVip(PlayerStatus,NewVipLevel,0,VipExpireTime);
        GoodsTid =:= 495014203 orelse GoodsTid =:= 494014203->
            NewVipLevel = max(PlayerStatus#player.vip,3),
            if
                PlayerStatus#player.vip_expire_time < NowTime ->
                    VipExpireTime = Vip3#temp_vip.vip_time*60 + NowTime;
                true ->
                    VipExpireTime = PlayerStatus#player.vip_expire_time + Vip3#temp_vip.vip_time*60
            end,
            {ok,NewPlayerStatus} = lib_vip:activiteVip(PlayerStatus,NewVipLevel,0,VipExpireTime);
        GoodsTid =:= 495014204 orelse GoodsTid =:= 494014204->
            NewVipLevel = max(PlayerStatus#player.vip,4),
            if
                PlayerStatus#player.vip_expire_time < NowTime ->
                    VipExpireTime = Vip4#temp_vip.vip_time*60 + NowTime;
                true ->
                    VipExpireTime = PlayerStatus#player.vip_expire_time + Vip4#temp_vip.vip_time*60
            end,
            {ok,NewPlayerStatus} = lib_vip:activiteVip(PlayerStatus,NewVipLevel,0,VipExpireTime);
        GoodsTid =:= 495014205 orelse GoodsTid =:= 494014205->
            NewVipLevel = max(PlayerStatus#player.vip,5),
            if
                PlayerStatus#player.vip_expire_time < NowTime ->
                    VipExpireTime = Vip5#temp_vip.vip_time*60 + NowTime;
                true ->
                    VipExpireTime = PlayerStatus#player.vip_expire_time + Vip5#temp_vip.vip_time*60
            end,
            {ok,NewPlayerStatus} = lib_vip:activiteVip(PlayerStatus,NewVipLevel,0,VipExpireTime);
        true ->
            NewPlayerStatus = PlayerStatus 
    end,

    NewPlayerStatus.

%%充值获得VIP
check_charge_vip(Status) ->
    skip.
%if
%   is_record(Status,player) ->
%        TotalChargeNum = db_agent_log:get_log_charge(Status#player.account_id),
%        ForeverVip = tpl_vip:get(?VIP_FOREVER),
%        if
%            is_record(ForeverVip,temp_vip) ->
%                {2,NeedChargeNum} = ForeverVip#temp_vip.trigger,
%                if
%                    TotalChargeNum >= NeedChargeNum ->
%                        Time = util:unixtime() + ForeverVip#temp_vip.last_time,
%                        lib_goods:change_vip_data(PlayerStatus, ForeverVip#temp_vip.level, Time);
%                    true ->
%                        skip
%                end;
%            true ->
%                skip
%        end;
%    true ->
%        skip
%end.

%%获取VIP每日福利
get_vip_day_gift(VipType) ->
    skip.
%VipDayGiftData = tpl_vip_day_gift:get(VipType),
%GiftData = VipDayGiftData#temp_vip_day_gift.data,
%GiftData.

%%获取VIP特权（增加的数值/百分比）
get_vip_power_val(VipType,PowerName) ->
    skip.
%VipPowerData = tpl_vip_power:get(VipType),
%PowerData = VipPowerData#temp_vip_power.data,
%SinglePower = lists:keyfind(PowerName,1,PowerData),
%SinglePower.


check_vip_date_gift(PlayerStatus) ->
    VipRcd = tpl_vip:get(PlayerStatus#player.vip),
    PlayerStatus2 = PlayerStatus#player{freefly = VipRcd#temp_vip.freefly},
    PlayerStatus2.

getVipLevel(PlayerStatus) ->
    NowTime = util:unixtime(),
    if
        PlayerStatus#player.vip > 0 ->
            if
                PlayerStatus#player.vip_expire_time > NowTime ->
                    VIPLevel = PlayerStatus#player.vip;
                true ->
                    VIPLevel = 0
            end;
        true ->
            VIPLevel = 0
    end,
    VIPLevel.

%%玩家充值->>>至尊VIP
chargeVip(PlayerStatus,Num) ->
   VipRcd = tpl_vip:get(6),  
   Vip6NeedGold = VipRcd#temp_vip.cost, 
   ChargedGold = db_agent_log:get_log_charge(PlayerStatus#player.account_id),

   
   if
       ChargedGold + Num >= Vip6NeedGold ->
           NewVipLevel = 6,
           VipExpireTime = ?VIP_INFINATE_TIME,
           
           if
               PlayerStatus#player.freefly < VipRcd#temp_vip.freefly ->
                   FreeFlyNum = VipRcd#temp_vip.freefly;
               true ->
                   FreeFlyNum = PlayerStatus#player.freefly
           end,

           %%处理Buff
           {Code,ReturnObj} = buff_util:add_goods_buff(PlayerStatus,VipRcd#temp_vip.vip_buff_id),
           if
               is_record(ReturnObj,player) ->
                   PlayerStatus2 = ReturnObj;
               true ->
                   PlayerStatus2 = PlayerStatus
           end;
       true ->
           NewVipLevel = PlayerStatus#player.vip,
           VipExpireTime = PlayerStatus#player.vip_expire_time,
           FreeFlyNum = PlayerStatus#player.freefly,
           PlayerStatus2 = PlayerStatus
   end,

   PlayerStatusNew = PlayerStatus2#player{
       vip = NewVipLevel,
       vip_expire_time = VipExpireTime,
       freefly = FreeFlyNum,
       cell_num = PlayerStatus2#player.cell_num + VipRcd#temp_vip.freebag
   },

   if
       NewVipLevel > PlayerStatus2#player.vip ->
           pp_player:pack_and_send(PlayerStatusNew, 13008, [1,0,NewVipLevel,VipExpireTime]);
       true ->
           skip
   end,
   lib_player:send_player_attribute3(PlayerStatusNew),
   PlayerStatusNew.

clearVip(PlayerStatus) ->
   PlayerStatusNew = PlayerStatus#player{
       vip = 0,
       vip_expire_time = 0,
       freefly = 0
   },
   pp_player:pack_and_send(PlayerStatus, 13008, [-1,0,0,0]),%%通知前端vip失效
   PlayerStatusNew.
