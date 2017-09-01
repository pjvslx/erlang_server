%% Author: Administrator
%% Created: 2011-10-14
%% Description: TODO: Add description to db_agent_business_activity
-module(db_agent_business_activity).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%插入一个新的CdKey
insert_cdkey(CdKey,ServerId,ProviderId,AwardId) ->
    ?DB_MODULE:insert(cd_key,[{cdkey,CdKey},{server_id,ServerId},{provider_id,ProviderId}]).

%%检查领取CdKey的有效性(1:可领取 0:该CdKey不存在 -1:该CdKey已被使用 -2:该玩家已领取过CdKey奖励)
check_cdkey_award(Status,CdKey) ->
    case ?DB_MODULE:select_row(cd_key,"cdkey,used_uid",[{cdkey,CdKey}],[],[1]) of
        [] ->
            0;
        Data ->
            [Key,UsedUid] = Data,
            if
                UsedUid > 0 ->
                    -1;%% -1:该CdKey已被使用
                true ->
                    case ?DB_MODULE:select_row(cd_key,"cdkey,used_uid",[{used_uid,Status#player.id}],[],[1]) of
                        [] ->
                            1;
                        Data2 ->
                            -2%%该玩家已领取过CdKey奖励 
                    end
            end
    end.

%%更新CDKey的使用状态
update_cd_key_status(Uid,CdKey) ->
    ?DB_MODULE:update(cd_key,[{used_uid,Uid}],[{cdkey,CdKey}]).

%%新注册玩家,插入该玩家的邀请码信息
insertInviteKey(Uid,InviteKey) ->
    ?DB_MODULE:insert(invite_info,[{uid,Uid},{invite_key,InviteKey}]).

%%获取玩家的邀请码
getInviteKey(Uid) ->
    ?DB_MODULE:select_one(invite_info,"invite_key",[{uid,Uid}]).

%%获取玩家邀请其他玩家的个数
getInviteNum(Uid) ->
    Data = ?DB_LOG_MODULE:select_all(invited_award_log, "*", [{inviter_id, Uid}]),
    length(Data).

%%查询可领取【被邀请】奖励( >0 : 可领取 0:已领取过该奖励 -1:不存在此邀请码 -2:不可使用自己的邀请码)
checkInvitedAwardStatus(Uid,InviteKey) ->
    Data = ?DB_LOG_MODULE:select_all(invited_award_log,"*",[{invited_id,Uid}]),
    case length(Data) of
        Len when Len > 0 ->
            0;%%已领取过
        _ ->
            case ?DB_MODULE:select_one(invite_info,"uid",[{invite_key,InviteKey}],[],[1]) of
                [] ->
                    -1;%%不存在此邀请码
                Uid2 ->
                    if
                        Uid =:= Uid2 ->
                            -2;%%不可以使用自己的邀请码
                        true->
                            Uid2
                    end
        end
    end.

%%查询是否领取过某项【邀请】奖励 1:可领取 0:已领取过，不可领取 -1:未达到领取条件
checkInviteAwardStatus(Uid,AwardIndex) ->
    Data = ?DB_LOG_MODULE:select_all(inviter_award_log,"*",[{uid,Uid},{award_index,AwardIndex}]),
    case length(Data) of
        Len when Len> 0 ->
            0;%%已领取过,不可领取
        _ ->
            Data2 = ?DB_LOG_MODULE:select_all(invited_award_log,"*",[{inviter_id,Uid}]),
            case AwardIndex of
                1 ->
                    if
                        length(Data2) >= 1 ->

                            1;%%达到领取条件，可领取奖励
                        true ->
                            -1%%未达到领取条件，不可领取
                    end;
                2 ->
                    if
                        length(Data2) >= 3 ->
                            1;
                        true ->
                            -1
                    end;
                3 ->
                    if
                        length(Data2) >= 5 ->
                            1;
                        true ->
                            -1
                    end;
                4 ->
                    if
                        length(Data2) >= 10 ->
                            1;
                        true ->
                            -1
                    end
            end
    end.

%%插入领取【被邀请】奖励数据
insert_invited_award_log(InviterId,InvitedId,NowTime) ->
    ?DB_LOG_MODULE:insert(invited_award_log,[{inviter_id,InviterId},{invited_id,InvitedId},{create_time,NowTime}]).

insert_inviter_award_log(PlayerId,AwardIndex,NowTime) ->
    ?DB_LOG_MODULE:insert(inviter_award_log,[{uid,PlayerId},{award_index,AwardIndex},{create_time,NowTime}]).
