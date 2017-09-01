%%%-------------------------------------- 
%%% @Module: lib_suit
%%% @Author:
%%% @Created:
%%% @Description: 
%%%-------------------------------------- 
-module(lib_suit).

-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").

-compile(export_all).

%% desc: 登录初始化玩家套装信息
%% returns: [{suit, num}, ......]
init_login_suit(PlayerId, GoodsEtsId) ->
    GoodsEtsName = misc:create_goods_ets_name(GoodsEtsId),
    Pattern = #goods{uid = PlayerId, location = ?LOCATION_PLAYER, _ = '_'},
    case lib_common:get_ets_list(GoodsEtsName, Pattern) of
        List when is_list(List) ->
            lists:foldl(fun count_suit/2, [], List);
        _ ->
            []
    end.

%% desc: 计算套装
count_suit(GoodsInfo, Result) ->
    case GoodsInfo#goods.suit_id > 0 of
        false ->
            Result;
        true ->
            case lists:keyfind(GoodsInfo#goods.suit_id, 1, Result) of
                false ->                 [{GoodsInfo#goods.suit_id, 1} | Result];
                {SuitId, Num} ->         lists:keyreplace(SuitId, 1, Result, {SuitId, Num + 1})
            end
    end.

%% desc: 玩家自己穿卸一件套装
%% returns: NewPlayerStatus 
%% 穿上一件装备
change_role_suit(equip, PlayerStatus, [{}, GoodsInfo]) when GoodsInfo#goods.suit_id > 0 ->
    NewSuitList = add_suit_num(GoodsInfo#goods.suit_id, PlayerStatus#player.other#player_other.role_suit),
	PlayerOther = PlayerStatus#player.other#player_other{role_suit = NewSuitList},
	PlayerStatus#player{other = PlayerOther};
%% 替换一件装备
change_role_suit(equip, PlayerStatus, [OldGoodsInfo, GoodsInfo]) when is_record(OldGoodsInfo, goods) ->
    % 改变套装件数
    NewPS = case OldGoodsInfo#goods.suit_id > 0 of
                true ->             change_role_suit(unequip, PlayerStatus, OldGoodsInfo);
                false ->            PlayerStatus
            end,
    case GoodsInfo#goods.suit_id > 0 of
        true ->    change_role_suit(equip, NewPS, [{}, GoodsInfo]);
        false ->   NewPS
    end;
%% 脱下一件装备
change_role_suit(unequip, PlayerStatus, GoodsInfo) when GoodsInfo#goods.suit_id > 0 ->
    NewSuitList = sub_suit_num(GoodsInfo#goods.suit_id, PlayerStatus#player.other#player_other.role_suit),
	PlayerOther = PlayerStatus#player.other#player_other{role_suit = NewSuitList},
	PlayerStatus#player{other = PlayerOther};

change_role_suit(_, PlayerStatus, _GoodsInfo) ->
    PlayerStatus.

get_goods_suit_num(GoodsInfo, PS) ->
	SuitId = GoodsInfo#goods.suit_id,
    case lists:keyfind(SuitId, 1, PS#player.other#player_other.role_suit) of
        {SuitId, Num} ->	Num;
        false ->	1
    end.

add_suit_num(SuitId, SuitList) ->
    case lists:keyfind(SuitId, 1, SuitList) of
        false ->               [{SuitId, 1} | SuitList];
        {SuitId, Num} ->     lists:keyreplace(SuitId, 1, SuitList, {SuitId, Num + 1})
    end.

sub_suit_num(SuitId, SuitList) ->
    case lists:keyfind(SuitId, 1, SuitList) of
        false ->               [];
        {SuitId, 1} ->       lists:delete({SuitId, 1}, SuitList);
        {SuitId, Num} ->     lists:keyreplace(SuitId, 1, SuitList, {SuitId, Num - 1})
    end.

change_pet_suit(equip, PetInfo, GoodsInfo) when GoodsInfo#goods.suit_id > 0 ->
    NewSuitList = add_suit_num(GoodsInfo#goods.suit_id, PetInfo#pet.suit_list),
    PetInfo#pet{suit_list = NewSuitList};
change_pet_suit(unequip, PetInfo, GoodsInfo) when GoodsInfo#goods.suit_id > 0 ->
    NewSuitList = sub_suit_num(GoodsInfo#goods.suit_id, PetInfo#pet.suit_list),
    PetInfo#pet{suit_list = NewSuitList};
change_pet_suit(_, PetInfo, _GoodsInfo) ->
    PetInfo.