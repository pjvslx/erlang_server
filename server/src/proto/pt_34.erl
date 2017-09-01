%%%--------------------------------------
%%% @Module  : pp_system_config
%%% @Author  : water
%%% @Created : 2013.01.25
%%% @Description:  玩家游戏系统配置
%%%--------------------------------------
-module(pt_34).

-include("common.hrl").
-include("record.hrl").

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([write/2, read/2]).

%%
%% API Functions
%%

%% -----------------------------------------------------------------
%% 34001 读取设置信息
%% -----------------------------------------------------------------
read(34001, _) ->
	{ok, []};

read(34002, <<FlagBin:1/binary-unit:8, Music:8, SoundEffect:8, _Bin/binary>>) ->
    <<ShieldRole:1, ShieldSkill:1, ShieldRela:1, ShieldTeam:1, ShieldChat:1, Fasheffect:1, _Bin2/binary>> = FlagBin,
    {ok, [ShieldRole, ShieldSkill, ShieldRela, ShieldTeam, ShieldChat, Fasheffect, Music, SoundEffect]};

read(34010, _) ->
	{ok, []};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%% -----------------------------------------------------------------
%% 34000 读取设置信息
%% -----------------------------------------------------------------
write(34001, [ShieldRole, ShieldSkill, ShieldRela, ShieldTeam, ShieldChat, Fasheffect, Music, SoundEffect]) -> 
	BinData = <<ShieldRole:1, ShieldSkill:1, ShieldRela:1, ShieldTeam:1, ShieldChat:1,  Fasheffect:1, 0:2, Music:8, SoundEffect:8, Fasheffect:8>>,
	{ok, pt:pack(34001, BinData)};

write(34010, [State, WorldLv, MinLv, MaxLv, Exp]) -> 
	BinData = <<State:8, WorldLv:16, MinLv:16, MaxLv:16, Exp:16>>,
	{ok, pt:pack(34010, BinData)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.


