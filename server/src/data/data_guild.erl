%%---------------------------------------
%% @Module  : data_guild
%% @Author  : water
%% @Created : 2013.02.22
%% @Description:  联盟配置
%%---------------------------------------

-module(data_guild).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
get_guild_config(Type) ->
    case Type of
		create_guild_need_level -> 35  ;     %创建帮派需要的等级
       %% create_coin        -> 100;        %创建帮派所需铜钱
		create_coin        -> 0;
        require_level      -> 1;          %创建帮派所需要等级
        accuse_time        -> 3*24*3600;  %投票持续弹劾时间 
        max_level          -> 100;        %%最大等级
        apply_max          -> 99999;          %%最大申请帮派数
        guild_apply_max    -> 99999;
		limit_members      -> 15;         %%成员数量限制

		max_debt_days      ->3;
		
		guild_hu_fa_cnt    ->2;
		guild_elite_cnt    ->6;
    guild_apply_min_level ->20; %%申请帮派的最小等级
        _                  -> undefined
    end.

%%最大帮派人数
get_max_num() ->
    20.

%%升级帮派费用
get_upgrade_cost(_Level) ->
    10.
get_position( Position) ->
  case Position of 
     1 ->  "帮主";
     2 ->  "副帮主";
     3 ->  "护法";
     4 ->  "精英";
     _ ->  "帮众"
  end.

get_maintain_cost_a_day(Level) ->
    GuildLevel = get_guild_level_info(Level),
	  case is_record(GuildLevel,temp_guild_level) of
		  true ->
	            GuildLevel#temp_guild_level.guild_contribution_cost;
		  false ->
			    150
	  end.
% get_limit_member(Guild) ->
%     GuildLevel = get_guild_level_info(Guild),
%     case is_record(GuildLevel,temp_guild_level) of
%       true ->
%               GuildLevel#temp_guild_level.guild_members_limit;
%       false ->
%           1
%     end;
get_limit_member(Level) ->
      case ets:lookup(?ETS_TEMP_GUILD_LEVEL, Level) of
         []  -> 1;
         [R] -> R#temp_guild_level.guild_members_limit
      end.

get_guild_level_info(Level) ->
     case ets:lookup(?ETS_TEMP_GUILD_LEVEL, Level) of
       [] -> [];
       [R] -> R
   end.
  


