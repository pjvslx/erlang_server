%%%-----------------------------------
%%% @Module  : lib_business_activity
%%% @Author  : ly
%%% @Created : 2013.09.28
%%% @Description: 活跃度
%%%-----------------------------------
-module(lib_business_activity).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("activity.hrl").
-compile(export_all).


%%生成N个CdKey
createCdKey(0,_,_,_,_) ->
    skip;
createCdKey(N,StartBaseNum,ServerId,ProviderId,AwardId) ->
    if
        N rem 10000 =:= 0 ->
            util:sleep(1000);
        true ->
            skip
    end,
    KeyNum = StartBaseNum + util:rand(1,10000000),
    CdKey = string:to_lower(util:v10toVn(KeyNum,32,[])),
    db_agent_business_activity:insert_cdkey(CdKey,ServerId,ProviderId,AwardId),
    createCdKey(N-1,StartBaseNum+1,ServerId,ProviderId,AwardId).

%%领取CdKey奖励
getCdKeyAward(Status,CdKey) ->
    Result = db_agent_business_activity:check_cdkey_award(Status,CdKey),  
    if Result =:= 1 ->
            GoodsId= 611003006,
            db_agent_business_activity:update_cd_key_status(Status#player.id,CdKey),%%更新CdKey的使用情况
            goods_util:send_goods_to_role([{GoodsId, 1}], Status, 0);%%发送奖励
        true ->
            skip
    end,
    Result.

%%新注册玩家,插入该玩家的邀请码信息
insertInviteKey(PlayerId) ->
    if
        PlayerId > 100000000 ->
            NewNum = PlayerId - (PlayerId div 100000000)*100000000;
        true ->
            NewNum = PlayerId
    end,
    InviteKey = string:to_lower(util:v10toVn(NewNum,36,[])),
    db_agent_business_activity:insertInviteKey(PlayerId,InviteKey).


%%显示邀请界面信息
showViewInfo(Status) ->
    InviteKey = db_agent_business_activity:getInviteKey(Status#player.id),
    InvitedNum = db_agent_business_activity:getInviteNum(Status#player.id),
    Award1Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,1),
    Award2Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,2),
    Award3Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,3),
    Award4Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,4),
    {InviteKey,InvitedNum,Award1Status,Award2Status,Award3Status,Award4Status}.

%%领取【被邀请】奖励
getInvitedAward(Status,InviteKey) ->
    Result = db_agent_business_activity:checkInvitedAwardStatus(Status#player.id,InviteKey),
    case Result of
        InviterId when InviterId > 0 ->
            GoodsId= 611003005,
            NowTime = util:unixtime(),
            db_agent_business_activity:insert_invited_award_log(InviterId,Status#player.id,NowTime),%%插入被邀请记录
            goods_util:send_goods_to_role([{GoodsId, 1}], Status, 0);%%发送奖励
        _ ->
            skip
    end,
    Result.

%%领取【邀请】奖励 1:可领取 0:已领取过，不可领取 -1:未达到领取条件
getInviteAward(Status,AwardId) ->
    Result = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,AwardId),
    case Result of
        1 ->
            case AwardId of
                1 ->
                    GoodsId= 611003001;
                2 ->
                    GoodsId= 611003002;
                3 ->
                    GoodsId= 611003003;
                4 ->
                    GoodsId= 611003004
            end,

            NowTime = util:unixtime(),
            db_agent_business_activity:insert_inviter_award_log(Status#player.id,AwardId,NowTime),%%插入被邀请记录
            goods_util:send_goods_to_role([{GoodsId, 1}], Status, 0);%%发送奖励
        _ ->
            skip
    end,
    Result.

