%%--------------------------------------
%% @Module  : lib_team
%% @Author  : 
%% @Created : 
%% @Description : 组队业务处理实现
%%--------------------------------------
-module(lib_team).

-include("common.hrl").
-include("record.hrl").
-include("team.hrl").
-include("debug.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-compile(export_all).

%%
%% API Functions
%%

%%加入队伍
join_team(TeamId, Member) ->
    case get_team(TeamId) of
        [] -> {false, ?TEAM_NOT_EXIST};
        Team -> 
            if length(Team#team.member_ids) >= Team#team.max_num ->
                PlayerId = Member#team_member.uid,
                case lists:member(PlayerId, Team#team.member_ids) of
                    true -> 
                        {false, ?TEAM_ALREAD_IN_TEAM};
                    false -> 
                        NewTeam = Team#team{member_ids = [PlayerId|Team#team.member_ids]},
                        ets:insert(?ETS_TEAM, NewTeam),
                        ets:insert(?ETS_TEAM_MEMBER, Member),
                        broadcast_member_enter(Team#team.member_ids,
                                               PlayerId,
                                               Member#team_member.nick,
                                               Member#team_member.level,
                                               Member#team_member.force),
                        true
                end;
            true ->
                {false, ?TEAM_MEMBER_FULL}
            end
    end.

%%退出队伍
quit_team(TeamId, PlayerId) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
          {false, ?TEAM_NOT_EXIST};
       Team#team.leader_id =:= PlayerId ->
           disband_team(TeamId);
        Team -> 
             case lists:member(PlayerId, Team#team.member_ids) of
                 true  -> 
                     NewTeam = Team#team{member_ids = Team#team.member_ids -- [PlayerId]},
                     ets:insert(?ETS_TEAM, NewTeam),
                     del_team_member(PlayerId),
                     broadcast_member_exit(NewTeam#team.member_ids, PlayerId),
                     true;
                 false -> 
                     {false, ?TEAM_NOT_IN_TEAM}
             end
    end.

%%解散队伍
disband_team(TeamId) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           {false, ?TEAM_NOT_EXIST};
       true ->
           del_team(TeamId),
           lists:foreach(fun(Uid) ->
                            del_team_member(Uid),
                            lib_player:cast_player(Uid, {update_team, 0, 0})
                         end, Team#team.member_ids),
           broadcast_team_demiss(Team#team.member_ids, TeamId),
           mod_team:disband_team(TeamId),
           true
    end.

%%踢人出队
kickout(TeamId, PlayerId) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           {false, ?TEAM_NOT_EXIST};
       true ->
           case lists:member(PlayerId, Team#team.member_ids) of
               true  -> 
                   NewTeam = Team#team{member_ids = Team#team.member_ids -- [PlayerId]},
                   ets:insert(?ETS_TEAM, NewTeam),
                   del_team_member(PlayerId),
                   notice_kickout(PlayerId, Team#team.leader_id, Team#team.leader_nick),
                   broadcast_member_exit(NewTeam#team.member_ids, PlayerId),
                   true;
               false -> 
                   {false, ?TEAM_NOT_SAME_TEAM}
           end
    end.

%%转让队长
demise_leader(TeamId, PlayerId) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           {false, ?TEAM_NOT_EXIST};
       true ->
           if PlayerId =/= 0 ->
               NewLeaderId = PlayerId;
           true -> %%没指定新队长,随便指定一个
               [NewLeaderId|_] = lists:reverse(Team#team.member_ids -- [Team#team.leader_id])
           end,
           case lists:member(PlayerId, Team#team.member_ids) of
                false -> 
                    {false, ?TEAM_NOT_IN_TEAM};
                true ->
                    TeamMember = get_team_member(NewLeaderId),
                    ?ASSERT(is_record(TeamMember, team_member)),
                    NewTeam = Team#team{leader_id = PlayerId, 
                                        leader_level = TeamMember#team_member.level,
                                        leader_nick = TeamMember#team_member.nick
                                       },
                    ets:insert(?ETS_TEAM, NewTeam),
                    lib_player:cast_player(PlayerId, {update_team, TeamId, 1}),
                    broadcast_new_leader(NewTeam#team.member_ids, NewLeaderId),
                    true
         end
    end.

%%设置直接加入
set_join(TeamId, Join) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           {false, ?TEAM_NOT_EXIST};
       true ->
           IJoin = if Join =:= 1 -> 1; true -> 0 end,
           NewTeam = Team#team{direct_join = IJoin},
           ets:insert(?ETS_TEAM, NewTeam),
           true
    end.

%%设置邀请
set_invite(TeamId, Invite) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           {false, ?TEAM_NOT_EXIST};
       true ->
           IInvite = if Invite =:= 1 -> 1; true -> 0 end,
           NewTeam = Team#team{direct_join = IInvite},
           ets:insert(?ETS_TEAM, NewTeam),
           true
    end.

%%广播队伍内:　新加入的玩家
broadcast_member_enter(MemberIds, PlayerId, Name, Level, Force) ->
    {ok, BinData} = pt_35:write(35030, [PlayerId, Name, Level, Force]),
    lists:foreach(fun(Uid) ->
                     lib_send:send_to_uid(Uid, BinData)
                  end, MemberIds).
    
%%广播队伍内:　刚退出的玩家(踢出也算)
broadcast_member_exit(MemberIds, PlayerId) ->
    {ok, BinData} = pt_35:write(35031, [PlayerId]),
    lists:foreach(fun(Uid) ->
                     lib_send:send_to_uid(Uid, BinData)
                  end, MemberIds).

%%通知玩家:被踢
notice_kickout(PlayerId, LeaderId, LeaderName) ->
    {ok, BinData} = pt_35:write(35032, [LeaderId, LeaderName]),
    lib_send:send_to_uid(PlayerId, BinData).

%%发送邀请给玩家
notice_invite(Uid, TeamId, InviteeId, Nick, Level) ->
    {ok, BinData} = pt_35:write(35033, [InviteeId, Nick, Level, TeamId]),
    lib_send:send_to_uid(Uid, BinData).

%%通知队长变化
broadcast_new_leader(MemberIds, NewLeaderId) ->
    {ok, BinData} = pt_35:write(35034, [NewLeaderId]),
    lists:foreach(fun(Uid) ->
                     lib_send:send_to_uid(Uid, BinData)
                  end, MemberIds).

%%通知队伍解散
broadcast_team_demiss(MemberIds, TeamId) ->
    {ok, BinData} = pt_35:write(35035, [TeamId]),
    lists:foreach(fun(Uid) ->
                     lib_send:send_to_uid(Uid, BinData)
                  end, MemberIds).


%%给队伍所有成员发送信息
send_to_team(TeamId, BinData) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           false;
       true ->
           lists:foreach(fun(Uid) ->
                             lib_send:send_to_uid(Uid, BinData)
                          end,
                          Team#team.member_ids)
    end.

%%给队伍所有成员发送信息
send_to_team_except(TeamId, PlayerId, BinData) ->
    Team = get_team(TeamId),
    if Team =:= [] ->
           false;
       true ->
           lists:foreach(fun(Uid) ->
                             lib_send:send_to_uid(Uid, BinData)
                          end,
                          Team#team.member_ids -- [PlayerId])
    end.

%%获取当前最大的队伍ID
get_max_teamid() ->
    TeamList = get_all_team(),
    Tids = [T#team.tid||T<-TeamList],
    lists:max([0|Tids]).

%------------------------------------------
%-内部操作
%------------------------------------------
%%获取队伍记录
get_team(TeamId) ->
   case ets:lookup(?ETS_TEAM, TeamId) of
       [] -> [];
       [R] -> R
   end.

%%删除队伍记录
del_team(TeamId) ->
   ets:delete(?ETS_TEAM, TeamId).

%%所有队伍列表
get_all_team() ->
   ets:tab2list(?ETS_TEAM).

%%获取队伍成员记录
get_team_member(PlayerId) ->
   case ets:lookup(?ETS_TEAM_MEMBER, PlayerId) of
       [] -> [];
       [R] -> R
   end.

%%删除队伍成员
del_team_member(PlayerId) ->
    ets:delete(?ETS_TEAM_MEMBER, PlayerId).

%%获取队伍成员列表(在线)
get_member_by_team_id(TeamId) ->
 	MS = ets:fun2ms(fun(T) when T#team_member.tid =:= TeamId -> T end),
    ets:select(?ETS_TEAM_MEMBER, MS).
