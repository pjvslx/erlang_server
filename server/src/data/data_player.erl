%%%------------------------------------------------    
%%% File    : data_player.erl    
%%% Author  : water
%%% Desc    : 玩家配置参数
%%%------------------------------------------------        
-module(data_player).     
-compile(export_all).

-include("common.hrl").
-include("record.hrl").

%%模块开放等级配置值
get_open_level(Module) ->
    case Module of
        mount  -> 1;
        _Other -> undefined
    end.

%%最大玩家等级
max_level() ->
   99.

%%初始玩家连击点,生命力,能量值, 怒气值
%%生命力初始为最大值, 其他为0
%%更改时注意mod_player:load_player_table()
%%与mod_player:save_player_table()实现配合
get_init_battle_attr(Career) ->    
    TempAttr = tpl_combat_attr:get(1, Career),
    [0, TempAttr#temp_combat_attr.hit_point_max, 100, 0].

%%下一等级所需的经验  
next_level_exp(Career, Level) ->
	case  tpl_combat_attr:get(Level+1, Career) of
		TempAttr when is_record(TempAttr, temp_combat_attr)->
			TempAttr#temp_combat_attr.exp;
		_->
			0
	end.


%%好友最大数量
get_max_friend_num() ->
    50.

%%仇人最大数量
get_max_foe_num() ->
    50.

%%最大黑名单数量
get_max_black_list_num()->
	50.

%%每天最大祝福次数
get_max_bless_times(_) ->
    10.

%%背包大小
get_cell_num(_Level) ->
    17.
   


