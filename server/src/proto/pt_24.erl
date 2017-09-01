%%%------------------------------------
%%% @Module  : pt_24
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 组队协议
%%%------------------------------------

-module(pt_24).
-export([read/2, write/2]).
-include("common.hrl").
-include("record.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%创建队伍
read(24000, <<Auto:8>>) ->
%%     {TeamName, _} = pt:read_string(Bin),
    {ok, Auto};

%%加入队伍
read(24002, <<Id:32>>) ->
    {ok, Id};

%%队长处理加入队伍请求
read(24004, <<Res:16, Id:32>>) ->
    {ok, [Res, Id]};

%%离开队伍
read(24005, _R) ->
    {ok, []};

%%邀请人加入队伍
read(24006, <<Id:32>>) ->
    {ok, Id};

%%被邀请人处理邀请进队信息
read(24008, <<Id:32, Res:16>>) ->
    {ok, [Id, Res]};

%%踢出队伍
read(24009, <<Id:32>>) ->
    {ok, Id};

%%询问队伍信息
read(24010, _R) ->
    {ok, []};

%%委任队长
read(24013, <<Id:32>>) ->
    {ok, Id};

%%更改队名
read(24014, <<Bin/binary>>) ->
    {TeamName, _} = pt:read_string(Bin),
    {ok, TeamName};

%%队伍资料
read(24016, <<Id:32>>) ->
    {ok, Id};

%% 获取场景队伍信息
read(24018, _R) ->
    {ok, []};

%% 修改队伍分配方式
read(24019, <<T:8>>) ->
    {ok, T};

%% 可否传送进入副本或封神台
read(24031, <<Sid:32>>) ->
    {ok, Sid};

%%小黑板登记
read(24050, <<Cdn1:8, Cdn2:8, Cdn3:8, MinLv:8, MaxLv:8>>) ->
    {ok, [Cdn1, Cdn2, Cdn3, MinLv, MaxLv]};

%%小黑板查询
read(24051, _R) ->
    {ok, []};

%%修改队伍设置：可否自由组队
read(24052, <<T:8>>) ->
    {ok, T};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%创建队伍
write(24000, [Res, TeamName, Auto]) ->
    TeamName1 = tool:to_binary(TeamName),
    L = byte_size(TeamName1),
    Data = <<Res:16, L:16, TeamName1/binary, Auto:8>>,  %%新创建的队伍，默认自动入队
    {ok, pt:pack(24000, Data)};

%%加入队伍
write(24002, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24002, Data)};

%%向队长发送加入队伍请求
write(24003, [Id, Lv, Career, Realm, Nick]) ->
    Nick1 = tool:to_binary(Nick),
    L = byte_size(Nick1),
    Data = <<Id:32, Lv:16, Career:16, Realm:16, L:16, Nick1/binary>>,
    {ok, pt:pack(24003, Data)};

%%队长处理加入队伍请求
write(24004, Res)->
    Data = <<Res:16>>,
    {ok, pt:pack(24004, Data)};

%%离开队伍
write(24005, Res)->
    Data = <<Res:16>>,
    {ok, pt:pack(24005, Data)};

%%邀请加入队伍
write(24006, Res)->
    Data = <<Res:16>>,
%% io:format("24006__~p~n",[Res]),	
    {ok, pt:pack(24006, Data)};

%%向被邀请人发出邀请
write(24007, [Id, Nick, TeamName]) ->
    Nick1 = tool:to_binary(Nick),
    NL = byte_size(Nick1),
    TeamName1 = tool:to_binary(TeamName),
    TNL = byte_size(TeamName1),
    Data = <<Id:32, NL:16, Nick1/binary, TNL:16, TeamName1/binary>>,
    {ok, pt:pack(24007, Data)};

%%邀请人邀请进队伍
write(24008, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24008, Data)};

%%踢出队员
write(24009, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24009, Data)};

%%向队员发送队伍信息
write(24010, [TeamId, TeamName, Member]) ->
    TeamName1 = tool:to_binary(TeamName),
    TL = byte_size(TeamName1),
    N = length(Member),
    F = fun([Id, Lv, Career, Realm, Nick, Sta, Hp, HpLim, Mp, MpLim, Sex]) ->
  		NewNick = tool:to_binary(Nick),
      	Len = byte_size(NewNick),
  		<<Id:32, Lv:16, Career:16, Realm:8, Len:16, NewNick/binary, Sta:8, 
		  		Hp:32, HpLim:32, Mp:32, MpLim:32, Sex:8>>
    end,
    LN = tool:to_binary([F(X) || X <- Member]),
    Data1 = <<TeamId:32, TL:16, TeamName1/binary, N:16, LN/binary>>,
    {ok, pt:pack(24010, Data1)};

%%向队员发送有人离队的信息
write(24011, Id) ->
    Data = <<Id:32>>,
    {ok, pt:pack(24011, Data)};

%%向队员发送更换队长的信息
write(24012, [Id, Auto]) ->
    Data = <<Id:32, Auto:8>>,
    {ok, pt:pack(24012, Data)};

%%委任队长
write(24013, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24013, Data)};

%%更改队名
write(24014, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24014, Data)};

%%通知队员队名更改了
write(24015, TeamName) ->
    TeamName1 = tool:to_binary(TeamName),
    L = byte_size(TeamName1),
    Data = <<L:16, TeamName1/binary>>,
    {ok, pt:pack(24015, Data)};

%%队伍资料
write(24016, [Id, MbNum, Nick, TeamName, Auto]) ->
    Nick1 = tool:to_binary(Nick),
    NL = byte_size(Nick1),
    TeamName1 = tool:to_binary(TeamName),
    TNL = byte_size(TeamName1),
    Data = <<Id:32, MbNum:16, NL:16, Nick1/binary, TNL:16, TeamName1/binary, Auto:8>>,
    {ok, pt:pack(24016, Data)};

%%通知队员队伍解散
write(24017, []) ->
    {ok, pt:pack(24017, <<>>)};

%% 场景队伍信息
write(24018, []) ->
    NL = 0,
    Data = <<NL:16>>,
    {ok, pt:pack(24018, Data)};
write(24018, Data) ->
    NL = length(Data),
    F = fun([Id, Nick, Lv, Career, Realm, Num, Auto]) ->
            Nick1 = tool:to_binary(Nick),
            Len = byte_size(Nick1),
            <<Id:32, Len:16, Nick1/binary, Lv:16, Career:16, Realm:16, Num:16, Auto:8>>
    end,
    Data1 = tool:to_binary([F(X)||X <- Data]),
    Data2 = <<NL:16, Data1/binary>>,
    {ok, pt:pack(24018, Data2)};

%% 修改 Pk模式
write(24019, T) ->
    {ok, pt:pack(24019, <<T:8>>)};

%% 向队员发送投骰子信息
write(24020, [UserName, MaxNum, GoodsTypeId, TeamRandDropInfo]) ->
    NewUserName = tool:to_binary(UserName),
    UL = byte_size(NewUserName),
    N = length(TeamRandDropInfo),
    F = fun({Num, _Pid, _Id, Name, _Realm, _Career, _Sex, _GoodsPid}) ->
  		NewName = tool:to_binary(Name),
  		L = byte_size(NewName),
  		<<L:16, NewName/binary, Num:8>>
    end,
    LN = tool:to_binary([F(T) || T <- TeamRandDropInfo]),
    Data = <<UL:16, NewUserName/binary, MaxNum:8, GoodsTypeId:32, N:16, LN/binary>>,
    {ok, pt:pack(24020, Data)};

%% 更新队员信息
write(24021, [Id, Sta, Lv, Hp, HpLim, Mp, MpLim]) ->
    Data = <<Id:32, Sta:8, Lv:16, Hp:32, HpLim:32, Mp:32, MpLim:32>>,
    {ok, pt:pack(24021, Data)};

%% 更新队员场景位置信息
write(24022, [PlayerId, X, Y, SceneId]) ->
    Data = <<PlayerId:32, X:16, Y:16, SceneId:32>>,
    {ok, pt:pack(24022, Data)};

%%队员下线
write(24023, Id) ->
    Data = <<Id:32>>,
    {ok, pt:pack(24023, Data)};

%%发送给队伍进入副本或封神台信息
write(24030, Sid) ->
%% ?DEBUG("24030__111_~p/",[Sid]),
    {ok, pt:pack(24030, <<Sid:32>>)};

%%可否传送进入副本或封神台
write(24031, [Sid, Res]) ->
    {ok, pt:pack(24031, <<Sid:32, Res:8>>)};

%%小黑板登记信息
write(24050, Res) ->
%% ?DEBUG("24050_000000000000: [~p]", [Res]),
    {ok, pt:pack(24050, <<Res:8>>)};

%%自动入队修改
write(24052, [Res, T]) ->
    {ok, pt:pack(24052, <<Res:8, T:8>>)};

write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.
