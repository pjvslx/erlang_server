%%%-----------------------------------
%%% @Module  : pt_29
%%% @Author  : smxx
%%% @Created : 2013.1.15
%%% @Description: 29防沉迷
%%%-----------------------------------
-module(pt_29).
-export([read/2, write/2]).
-include("common.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%填写防沉迷信息
read(29000, <<Idcard_status:8, Bin/binary>>) ->
    {Idcardnum, _} = pt:read_string(Bin),
    {ok, [Idcard_status, Idcardnum]};

%%累计游戏时间查询
read(29002, _) ->
    {ok, []};

%%我未成年（暂时不填身份证 信息）
read(29003, _) ->
    {ok, infant}.

%%服务端  -> 客户端 ----------------------------
%%填写防沉迷信息返回
write(29000, Code) ->
    Data = <<Code:8>>,
    {ok, pt:pack(29000, Data)};

%%防沉迷5分钟离线通知
write(29001, Info) ->
    {ok, pt:pack(29001, <<Info:8>>)};
    
%%累计游戏时间查询返回
write(29002, [Idcard_status, Gametime]) ->
    if Gametime < 0 ->
           Gt = 0;
       true ->
           Gt = Gametime
    end,
    Data = <<Idcard_status:8, Gt:32>>,
    {ok, pt:pack(29002, Data)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s pt29 error cmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.
