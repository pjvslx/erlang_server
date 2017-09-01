%%------------------------------------
%% @Module     : pp_mail
%% @Author     : water
%% @Created    : 2013.02.06
%% @Description: GM/信件系统
%%------------------------------------
-module(pp_mail).
-export([handle/3, handle_cmd/3, pack_and_send/3]).

-include("common.hrl").
-include("record.hrl"). 
-include("debug.hrl").
-include("mail.hrl").

%% API Functions
handle(Cmd, Player, Data) ->
    ?TRACE("pp_mail: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Player#player.id, Data]),
    handle_cmd(Cmd, Player, Data).

%%--------------------------------------
%%Protocol: 19001 玩家反馈到GM
%%--------------------------------------
handle_cmd(19001, Status, [Type,Content]) ->
    {ok, {Address, _Port}} = inet:peername(Status#player.other#player_other.socket),  %%获得对方IP地址
    lib_mail:feedback(Type, Content, Address, Status#player.id, Status#player.nick),
    pack_and_send(Status, 19001, [1]);

%%--------------------------------------
%%Protocol: 19002  获取GM反馈
%%--------------------------------------
handle_cmd(19002, Status, _) ->
    Result = lib_mail:get_feedback_list(Status#player.id),
    pack_and_send(Status, 19002, [Result]);

%%--------------------------------------
%%Protocol: 19010  是否有未读邮件
%%--------------------------------------
handle_cmd(19010, Status, _) ->
    Type = lib_mail:get_mail_type(Status#player.id),
    pack_and_send(Status, 19010, [Type]);

%%--------------------------------------
%%Protocol: 19011  邮件列表
%%--------------------------------------
handle_cmd(19011, Status, _) ->
    MailList = lib_mail:get_mail(Status),
    pack_and_send(Status, 19011, [MailList]);

%%--------------------------------------
%%Protocol: 19012 收取附件并删除邮件
%%--------------------------------------
handle_cmd(19012, Status, [MailId]) ->
   case lib_mail:get_attachment(Status, MailId) of
        {false, Reason} ->
             pack_and_send(Status, 19012, [Reason, MailId]);
        {true, NewStatus} ->
             %%刷新背包(略)
             pack_and_send(Status, 19012, [1, MailId]),
             {ok, NewStatus}
   end;

%%--------------------------------------
%%Protocol: 19013 删除邮件
%%--------------------------------------
handle_cmd(19013, Status, [MailId]) ->
   lib_mail:delete_mail(Status, MailId),
   pack_and_send(Status, 19013, [1]);

%%--------------------------------------
%%Protocol: 19014 智能领取
%%--------------------------------------
handle_cmd(19014, Status, _) ->
   NewStatus = lib_mail:smart_get_all_attachment(Status),
   handle_cmd(19011, Status, 0),
   {ok, NewStatus};

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Player, Cmd, Data) ->
    ?TRACE("pp_mail:pack_and_send Cmd:~p, Player:~p, Data:~p~n", [Cmd, Player#player.id, Data]),
    {ok, BinData} = pt_19:write(Cmd, Data),
    lib_send:send_to_sid(Player#player.other#player_other.pid_send, BinData).

