%%--------------------------------------
%% @Module: pt_14
%% Author: Auto Generated
%% Created: Mon Apr 15 11:47:31 2013
%% Description: 
%%--------------------------------------
-module(pt_14).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 14001 好友列表
%%--------------------------------------
read(14001, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 14002 获取所有好友信息(好友,仇人,黑名单)
%%--------------------------------------
read(14002, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 14003 获取仇人列表
%%--------------------------------------
read(14003, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 14005 获取黑名单列表
%%--------------------------------------
read(14005, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 14011 加好友
%%--------------------------------------
read(14011,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14014 删除好友
%%--------------------------------------
read(14014,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14015 加到仇恨名单中
%%--------------------------------------
read(14015,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14016 从仇恨名单清除
%%--------------------------------------
read(14016,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14017 加黑名单
%%--------------------------------------
read(14017,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14018 删除黑名单
%%--------------------------------------
read(14018,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14019 赠送免费鲜花
%%--------------------------------------
read(14019,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 14020 赠送鲜花
%%--------------------------------------
read(14020,<<Uid:64,FlowerId:32,FlowerNum:16,AutoFlag:8>>) ->
    {ok, [Uid, FlowerId, FlowerNum,AutoFlag]};

%%--------------------------------------
%%Protocol: 14021 现实玩家鲜花数量
%%--------------------------------------
read(14021, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 14022 查询好友信息
%%--------------------------------------
read(14022,<<Type:8,BinData/binary>>) ->
	{Name,_} = pt:read_string(BinData),
	io:format("OOOO ~n"),
    {ok, [Type,Name]}; 

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
	 {ok, []}.
   % {error, no_match}.

%%--------------------------------------
%%Protocol: 14001 好友列表
%%--------------------------------------
write(14001,[FriendList]) ->
    Fun_FriendList = fun([Uid,Name,PlayerPic,FriendShip,FlowerNum]) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8,FriendShip:16,FlowerNum:16>>
    end,
    FriendList_Len = length(FriendList),
    FriendList_ABin = any_to_binary(lists:map(Fun_FriendList,FriendList)),
    FriendList_ABinData = <<FriendList_Len:16, FriendList_ABin/binary>>,
    {ok, pt:pack(14001, <<FriendList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 14002 获取所有好友信息(好友,仇人,黑名单)
%%--------------------------------------
write(14002,[FriendList,FoeList,BlackList,FreeLeft]) ->
    Fun_FriendList = fun({Uid,Name,PlayerPic,FriendShip,FlowerNum}) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8,FriendShip:16,FlowerNum:16>>
    end,
    FriendList_Len = length(FriendList), 
    FriendList_ABin = any_to_binary(lists:map(Fun_FriendList,FriendList)),
    FriendList_ABinData = <<FriendList_Len:16, FriendList_ABin/binary>>,
    Fun_FoeList = fun({Uid,Name,PlayerPic,FriendShip}) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8,FriendShip:16>>
    end,
    FoeList_Len = length(FoeList),
    FoeList_ABin = any_to_binary(lists:map(Fun_FoeList,FoeList)),
    FoeList_ABinData = <<FoeList_Len:16, FoeList_ABin/binary>>,
    Fun_BlackList = fun({Uid,Name,PlayerPic}) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8>>
    end,
    BlackList_Len = length(BlackList),
    BlackList_ABin = any_to_binary(lists:map(Fun_BlackList,BlackList)),
    BlackList_ABinData = <<BlackList_Len:16, BlackList_ABin/binary>>,
    {ok, pt:pack(14002, <<FriendList_ABinData/binary,FoeList_ABinData/binary,BlackList_ABinData/binary,FreeLeft:8>>)};
%%--------------------------------------
%%Protocol: 14003 获取仇人列表
%%--------------------------------------
write(14003,[FoeList]) ->
    Fun_FoeList = fun([Uid,Name,PlayerPic,FriendShip]) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8,FriendShip:16>>
    end,
    FoeList_Len = length(FoeList),
    FoeList_ABin = any_to_binary(lists:map(Fun_FoeList,FoeList)),
    FoeList_ABinData = <<FoeList_Len:16, FoeList_ABin/binary>>,
    {ok, pt:pack(14003, <<FoeList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 14005 获取黑名单列表
%%--------------------------------------
write(14005,[BlackList]) ->
    Fun_BlackList = fun([Uid,Name,PlayerPic]) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,PlayerPic:8>>
    end,
    BlackList_Len = length(BlackList),
    BlackList_ABin = any_to_binary(lists:map(Fun_BlackList,BlackList)),
    BlackList_ABinData = <<BlackList_Len:16, BlackList_ABin/binary>>,
    {ok, pt:pack(14005, <<BlackList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 14011 加好友
%%--------------------------------------
write(14011,[Result,{UId,Nick,Pic,FriendShip,FlowerNum}]) ->
	     Name_StrBin = pack_string(Nick),
   {ok, pt:pack(14011, <<Result:8,UId:64,Name_StrBin/binary,Pic:8,FriendShip:16,FlowerNum:16>>)};

%%--------------------------------------
%%Protocol: 14014 删除好友
%%--------------------------------------
write(14014,[Result,Uid]) ->
    {ok, pt:pack(14014, <<Result:8,Uid:64>>)};

%%--------------------------------------
%%Protocol: 14015 加到仇恨名单中
%%--------------------------------------
write(14015,[Result,Uid]) ->
    {ok, pt:pack(14015, <<Result:8,Uid:64>>)};

%%--------------------------------------
%%Protocol: 14016 从仇恨名单清除
%%--------------------------------------
write(14016,[Result,Uid]) ->
    {ok, pt:pack(14016, <<Result:8,Uid:64>>)};

%%--------------------------------------
%%Protocol: 14017 加黑名单
%%--------------------------------------
write(14017,[Result]) ->
    {ok, pt:pack(14017, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 14018 删除黑名单
%%--------------------------------------
write(14018,[Result,Uid]) ->
    {ok, pt:pack(14018, <<Result:8,Uid:64>>)};

%%--------------------------------------
%%Protocol: 14019 赠送免费鲜花
%%--------------------------------------
write(14019,{Result,UId,Nick,Pic,FriendShip,FlowerNum}) ->
	 Name_StrBin = pack_string(Nick),
    {ok, pt:pack(14019,<<Result:8,UId:64,Name_StrBin/binary,Pic:8,FriendShip:16,FlowerNum:16>>)};

%%--------------------------------------
%%Protocol: 14020 赠送鲜花
%%--------------------------------------
write(14020,{Result,UId,Nick,Pic,FriendShip,FlowerNum}) ->
	 Name_StrBin = pack_string(Nick),
    {ok, pt:pack(14020,<<Result:8,UId:64,Name_StrBin/binary,Pic:8,FriendShip:16,FlowerNum:16>>)};

%%--------------------------------------
%%Protocol: 14021 现实玩家鲜花数量
%%--------------------------------------
write(14021,[Flower_1,Flower_9,Flower_99,Flower_999]) ->
    {ok, pt:pack(14021, <<Flower_1:16,Flower_9:16,Flower_99:16,Flower_999:16>>)};

%%--------------------------------------
%%Protocol: 14022 查询好友信息
%%--------------------------------------
write(14022,[Result,Type,Uid,Nick,Icon,Gender,Vip,Level,Guild_name,Camp,Career]) ->
    Nick_StrBin = pack_string(Nick),
    Guild_name_StrBin = pack_string(Guild_name),
	io:format("nono 14022 ~p ~n",[Camp]),
    {ok, pt:pack(14022, <<Result:8,Type:8,Uid:64,Nick_StrBin/binary,Icon:8,Gender:8,Vip:8,Level:8,Guild_name_StrBin/binary,Camp:8/signed,Career:8>>)};
 
%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData), 
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

