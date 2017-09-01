%%------------------------------------
%% @Module  : team_util
%% @Author  : water
%% @Created : 2013.03.12
%% @Description: 组队处理 
%%------------------------------------
-module(team_util).
-include("common.hrl").
-include("record.hrl").
-include("team.hrl").
-include("debug.hrl").
-compile(export_all).

%%玩家进程运行的函数, gen_server:call转到组队的服务进程来处理
%%玩家对自身的记录在玩家进程操作, 队伍记录由组队的服务进程来处理

%%查询所有的队伍
query_all_team(_Status) ->
    TeamList = lib_team:get_all_team(),
    F = fun(Team) ->
            [Team#team.tid,
             length(Team#team.member_ids),
             Team#team.max_num,
             Team#team.leader_id,
             Team#team.leader_level,
             Team#team.leader_nick
            ]
    end,
    lists:map(F, TeamList).

%%查询所有的队伍
query_my_team(Status) ->
    if Status#player.other#player_other.team_id =:= 0 ->
          {false, ?TEAM_NOT_IN_TEAM};
       true ->
           Team = lib_team:get_team(Status#player.other#player_other.team_id),
           F = fun(Uid) ->
                    TeamMem = lib_team:get_team_member(Uid),
                    [
                      TeamMem#team_member.uid,
                      TeamMem#team_member.nick,
                      TeamMem#team_member.level,
                      TeamMem#team_member.camp,
                      TeamMem#team_member.force
                    ]
               end,
           %%成员ID列表,队长的ID放在最前
           MemberIds = [Team#team.leader_id|Team#team.member_ids -- [Team#team.leader_id]],
           MemberList = lists:map(F, MemberIds),
           {true, Team#team.max_num, MemberList}
    end.
  
%%加入队伍
join_team(Status, TeamId) ->
    if Status#player.other#player_other.team_id =:= 0 ->
           Member = #team_member{	
                        uid = Status#player.id, 
                        tid = TeamId,
                        level = Status#player.level,
                        nick = Status#player.nick,
                        force = 0, 
                        camp = Status#player.camp, 
                        career = Status#player.career,
                        gender = Status#player.gender 
                   },
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                    {apply_call, lib_team, join_team, [TeamId, Member]}) of
                true ->
                    {true, Status#player{other = Status#player.other#player_other{team_id = TeamId, team_leader = 0}}};
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?TEAM_ERROR}
           end;
    true ->
        {false, ?TEAM_ALREAD_IN_TEAM}
    end.

%%创建队伍
create_team(Status) ->
    TeamMember = lib_team:get_team_member(Status#player.id),
    if TeamMember =:= [] ->
        case catch gen_server:call(mod_team:get_main_team_pid(), {get_team_id}) of
            NewTeamId when is_integer(NewTeamId) ->
                 NewTeam = #team{
                                tid = NewTeamId,
                                leader_id = Status#player.id,
                                leader_nick = Status#player.nick,
                                leader_level = Status#player.level,
                                direct_join = 0,
                                invite_allow = 0,
                                max_num = 5,
                                member_ids = [Status#player.id]
                            },
                 ets:insert(?ETS_TEAM, NewTeam),
                 Member = #team_member{	
                            uid = Status#player.id, 
                            tid = NewTeamId,
                            level = Status#player.level,
                            nick = Status#player.nick,
                            force = 0, 
                            camp = Status#player.camp, 
                            career = Status#player.career,
                            gender = Status#player.gender 
                            },
                ets:insert(?ETS_TEAM_MEMBER, Member),
                NewStatus = Status#player{other = Status#player.other#player_other{team_id = NewTeamId, team_leader = 1}},
                mod_team:create_team_proc(NewTeamId),
                {true, NewStatus};
            _Other ->
                {false, ?TEAM_ERROR}
        end;
    true ->
        {false, ?TEAM_ALREAD_IN_TEAM}
    end.

%%退出队伍
quit_team(Status) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false,  ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =:= 1 ->
           disband_team(Status);
       true ->
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, quit_team, [TeamId, Status#player.id]}) of
               true ->
                   {true, Status#player{other = Status#player.other#player_other{team_id = 0, team_leader = 0}}};
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.

%%解散队伍
disband_team(Status) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false,  ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =/= 1 ->
           {false, ?TEAM_NOT_LEADER};
       true ->
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, disband_team, [TeamId]}) of
               true ->
                   {true, Status#player{other = Status#player.other#player_other{team_id = 0, team_leader = 0}}};
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.

%%踢人
kickout(Status, PlayerId) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false, ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =/= 1 ->
           {false, ?TEAM_NOT_LEADER};
       true ->
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, kickout, [TeamId, PlayerId]}) of
               true ->
                   true;
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.

%%邀请人
invite(Status, PlayerId) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false, ?TEAM_NOT_IN_TEAM};
       true ->
           Team = lib_team:get_team(TeamId),
           ?ASSERT(is_record(Team, team)),
           if Team#team.invite_allow >= 1 orelse
              Status#player.other#player_other.team_leader =:= 1 ->
                  lib_team:notice_invite(PlayerId, TeamId, Status#player.id, Status#player.nick, Status#player.level),
                  true;
              true ->
                  {false, ?TEAM_NOT_LEADER}
          end
    end.

%%设置直接加入
set_join(Status, Join) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false,  ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =/= 1 ->
           {false, ?TEAM_NOT_LEADER};
       true ->
          case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, set_join, [TeamId, Join]}) of
               true ->
                   true;
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.

%%设置邀请
set_invite(Status, Invite) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false, ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =/= 1 ->
           {false, ?TEAM_NOT_LEADER};
       true ->
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, set_invite, [TeamId, Invite]}) of
               true ->
                   true;
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.

%%转让队长
demise_leader(Status, PlayerId) ->
    TeamId = Status#player.other#player_other.team_id,
    if TeamId =:= 0 ->
           {false, ?TEAM_NOT_IN_TEAM};
       Status#player.other#player_other.team_leader =/= 1 ->
           {false, ?TEAM_NOT_LEADER};
       true ->
           case catch gen_server:call(mod_team:get_team_pid(TeamId),
                         {apply_call, lib_team, demise_leader, [TeamId, PlayerId]}) of
               true ->
                   true;
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?TEAM_ERROR}
          end
    end.



