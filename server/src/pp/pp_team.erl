%%--------------------------------------
%% @Module  : pp_team
%% @Author  : water
%% @Created : 2013.03.12
%% @Description:  组队功能管理 
%%--------------------------------------
-module(pp_team).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile([export_all]).

%% API Functions
handle(Cmd, Status, Data) ->
    ?TRACE("pp_team: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 35001 查询所有队伍(分页待定)
%%--------------------------------------
handle_cmd(35001, Status, _) ->
    TeamInfoList = team_util:query_all_team(Status),
    pack_and_send(Status, 35001, [TeamInfoList]);

%%--------------------------------------
%%Protocol: 35002 查询自己队伍(队伍信息更新)
%%--------------------------------------
handle_cmd(35002, Status, _) ->
    case team_util:query_my_team(Status) of
        {true, MaxNum, MemberInfoList} ->
            pack_and_send(Status, 35002, [1, MaxNum, MemberInfoList]);
        {false, Reason} ->
            pack_and_send(Status, 35002, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35011 加入队伍
%%--------------------------------------
handle_cmd(35011, Status, [TeamId]) ->
    case team_util:join_team(Status, TeamId) of
        {true, NewStatus} ->
            pack_and_send(Status, 35011, [1]),
            {ok, NewStatus};
        {false, Reason} ->
            pack_and_send(Status, 35011, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35012 创建队伍
%%--------------------------------------
handle_cmd(35012, Status, _) ->
    case team_util:create_team(Status) of
        {true, NewStatus} ->
            pack_and_send(Status, 35012, [1]),
            {ok, NewStatus};
        {false, Reason} ->
            pack_and_send(Status, 35012, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35013 退出所在队伍
%%--------------------------------------
handle_cmd(35013, Status, _) ->
    case team_util:quit_team(Status) of
        {true, NewStatus} ->
            pack_and_send(Status, 35013, [1]),
            {ok, NewStatus};
        {false, Reason} ->
            pack_and_send(Status, 35013, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35014 解散队伍
%%--------------------------------------
handle_cmd(35014, Status, _) ->
    case team_util:disband_team(Status) of
        {true, NewStatus} ->
            pack_and_send(Status, 35014, [1]),
            {ok, NewStatus};
        {false, Reason} ->
            pack_and_send(Status, 35014, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35015 队长踢人
%%--------------------------------------
handle_cmd(35015, Status, [PlayerId]) ->
    case team_util:kickout(Status, PlayerId) of
        true ->
            pack_and_send(Status, 35015, [1]);
        {false, Reason} ->
            pack_and_send(Status, 35015, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35016 邀请玩家加入队伍
%%--------------------------------------
handle_cmd(35016, Status, [PlayerId]) ->
    case team_util:invite(Status, PlayerId) of
        true ->
            pack_and_send(Status, 35016, [1]);
        {false, Reason} ->
            pack_and_send(Status, 35016, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35017 直接可加入队伍
%%--------------------------------------
handle_cmd(35017, Status, [Join]) ->
    case team_util:set_join(Status, Join) of
        true ->
            pack_and_send(Status, 35017, [1]);
        {false, Reason} ->
            pack_and_send(Status, 35017, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35018 成员可邀请
%%--------------------------------------
handle_cmd(35018, Status, [Invite]) ->
    case team_util:set_invite(Status, Invite) of
        true ->
            pack_and_send(Status, 35018, [1]);
        {false, Reason} ->
            pack_and_send(Status, 35018, [Reason])
    end;

%%--------------------------------------
%%Protocol: 35019 转让队长
%%--------------------------------------
handle_cmd(35019, Status, [PlayerId]) ->
    case team_util:demise_leader(Status, PlayerId) of
        true ->
            pack_and_send(Status, 35019, [1]);
        {false, Reason} ->
            pack_and_send(Status, 35019, [Reason])
    end;

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, pp_team_error}.

pack_and_send(Status, Cmd, Data) ->
    ?TRACE("pp_team send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_35:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

