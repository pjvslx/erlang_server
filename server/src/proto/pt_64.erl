%% Author: zxb 
%% Created: 2012-10-10
%% Description: TODO: 
-module(pt_64).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%
%% 客户端 >> 服务器
%%#################查询自宅#################
%%协议号:64001
read(64001, _) ->
    {ok, []};

%#################补充体力#################
%协议号:64002
read(64002, _) ->
    {ok, []};

%#################升级家具#################
%协议号:64004 
read(64004, <<Pos:8>>) ->
    {ok, Pos};

%%#################升级配件#################
%%协议号:64005 
read(64005, <<Pos:8>>) ->
    {ok, Pos};

%#################扩建宅院#################
%协议号:64006 
read(64006, _) ->
    {ok, []};

%#################获取好友等宅院列表#################
%协议号:64010
read(64010, _) ->
    {ok, []};

%#################参观（按门牌号)#################
%协议号:64011
read(64011, <<HouseId:32>>) ->
    {ok, HouseId};

%#################参观2(按角色名)#################
%协议号:64012
read(64012, <<_Len:16, NameStr/binary>>) ->
    {ok, NameStr};

read(_Cmd, _R) ->
    {error, no_match}.

%%服务器 >> 客户端
%%#################查询自宅#################
%%协议号:64001
write(64001, [Result, HouseId, HouseType, Times, TotalTimes, SceneId, FurnitureList]) ->
    BinData = pack_my_house_info([HouseId, HouseType, Times, TotalTimes, SceneId, FurnitureList]),
    {ok, pt:pack(64001, <<Result:8, BinData/binary>>)};

%%#################补充体力#################
%%协议号:64002
write(64002, [Result, Times, TotalTimes]) ->
    {ok, pt:pack(64002, <<Result:8, Times:16, TotalTimes:16>>)};

%%#################升级家具#################
%%协议号:64004 
write(64004, [Result, Pos]) ->
    {ok, pt:pack(64004, <<Result:8, Pos:8>>)};

%%#################升级配件#################
%%协议号:64005 
write(64005, [Result, Pos]) ->
    {ok, pt:pack(64005, <<Result:8, Pos:8>>)};

%%#################扩建宅院#################
%%协议号:64006 
write(64006, [Result]) ->
    {ok, pt:pack(64006, <<Result:8>>)};


%%#################获取好友等宅院列表#################
%%协议号:64010
write(64010, [Result, HouseList]) ->
    F = fun([HouseId, HouseType, SceneId, RoleName]) ->
         RoleNameBin = pack_string(RoleName),
         <<HouseId:32, HouseType:8, SceneId:16, RoleNameBin/binary>>
    end,
    Len = length(HouseList),
    BinData = tool:to_binary([F(D) || D <- HouseList]),
    {ok, pt:pack(64010, <<Result:8, Len:16, BinData/binary>>)};


%%#################参观（按门牌号)#################
%%协议号:64011
write(64011, [Result, HouseId, HouseType, SceneId, RoleName, FurnitureList]) ->
    BinData = pack_house_info([HouseId, HouseType, SceneId, RoleName, FurnitureList]),
    {ok, pt:pack(64011, <<Result:8, BinData/binary>>)};


%%#################参观2(按角色名)#################
%%协议号:64012
write(64012, [Result, HouseId, HouseType, SceneId, RoleName, FurnitureList]) ->
    BinData = pack_house_info([HouseId, HouseType, SceneId, RoleName, FurnitureList]),
    {ok, pt:pack(64012, <<Result:8, BinData/binary>>)};

write(Cmd, _R) ->
	?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%
%% Local Functions
%%
pack_my_house_info([HouseId, HouseType, Times, TotalTimes, SceneId, FurnitureList]) ->
    F = fun({Pos, FLv, DLv, _Eng}) ->
	    %EngLimit = data_house:get_fur_eng_full(Pos, FLv) + data_house:get_dot_eng_full(Pos, DLv),
	    %Full = case Eng < EngLimit of
		%		   true -> 0;
		%		   false -> 1
		%	   end,
        <<Pos:8, FLv:8, DLv:8>>
    end,
    Len = length(FurnitureList),
    FurBin = tool:to_binary([F(D) || D <- FurnitureList]),
    <<HouseId:32, HouseType:8, Times:16, TotalTimes:16, SceneId:16, Len:16,FurBin/binary>>.

pack_house_info([HouseId, HouseType, SceneId, RoleName, FurnitureList]) ->
    RoleNameBin = pack_string(RoleName),
    F = fun({Pos, FLv, DLv, _Eng}) ->			
		%EngLimit = data_house:get_fur_eng_full(Pos, FLv) + data_house:get_dot_eng_full(Pos, DLv),
	    %Full = case Eng < EngLimit of
		%		   true -> 0;
		%		   false -> 1
		%	   end,
        <<Pos:8, FLv:8, DLv:8>>
    end,
    Len = length(FurnitureList),
    FurBin = tool:to_binary([F(D) || D <- FurnitureList]),
    <<HouseId:32, HouseType:8, SceneId:16, RoleNameBin/binary, Len:16,FurBin/binary>>.

pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

