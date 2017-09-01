%%%-------------------------------------- 
%%% @Module: lib_drop
%%% @Author: jack
%%% @Created: 
%%% @Description: 掉落
%%%-------------------------------------- 
-module(lib_drop).

-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").  

-define(MAX_RAND_NUM, 10000).   % 随机基数

-export([
        	get_drop_goods/1
         ]).

%% DropId 掉落id
%% 根据掉落id获取掉落铜钱和掉落物品id列表
%% return: [{物品id, 数量}]
get_drop_goods(DropId) ->
	case tpl_drop_main:get(DropId) of
		DropInfo when is_record(DropInfo, temp_drop_main) ->
			DropIdList = get_drop_sid_list(DropInfo#temp_drop_main.dropitem),
			get_drop_goods_list(DropIdList);
		_ -> []
	end.

%% 获取掉落实例Id列表
get_drop_sid_list(DropItemList) ->
	F = fun({Sid, Rate}, SidList) ->
		 Rand = util:rand(1, ?MAX_RAND_NUM),
		 case Rate >= Rand of
			 true -> [Sid | SidList];
			 false -> SidList
		 end
      end,
  lists:foldl(F, [], DropItemList).

%% DropIdList 掉落实例列表
%% 获取掉落物品Id列表
get_drop_goods_list(DropIdList) ->
	F = fun(Sid, GoodsList) ->
		 case tpl_drop_sub:get(Sid) of
			 DropInfo when is_record(DropInfo, temp_drop_sub) ->
				 Total = lists:sum([Rate||{_, _, Rate} <- DropInfo#temp_drop_sub.dropitem]),
				 Rand = util:rand(1, Total),
				 [get_rand_item(DropInfo#temp_drop_sub.dropitem, Rand) | GoodsList];
			 _-> GoodsList
		 end
      end,
  lists:foldl(F, [], DropIdList).

%% 获取随机id
get_rand_item([], _Rand) ->
	[];
get_rand_item([H|T], Rand) ->
  {Id, Num, Rate} = H,
  case Rate >=  Rand of
  	true -> {Id, Num};
  	false -> get_rand_item(T, Rand - Rate)
  end.
