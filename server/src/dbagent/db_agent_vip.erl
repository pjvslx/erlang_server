%%%--------------------------------------
%%% @Module  : db_agent_vip
%%% @Author  : water
%%% @Created : 2013.01.15
%%% @Description: 玩家数据处理模块
%%%--------------------------------------
-module(db_agent_vip).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).

%% 插入领奖记录
create_award_log(AccountId,VipLevel,CreateTime) ->    
    Ret = ?DB_LOG_MODULE:insert(vip_award_log, [account_id,vip_level,create_time],[AccountId,VipLevel,CreateTime]).

%% 通过帐号ID取得玩家最近一次领奖记录
get_award_log_by_accountid(AccId,VipLevel) ->
    ?DB_LOG_MODULE:select_row(vip_award_log, "*", [{account_id, AccId},{vip_level,VipLevel}], [{create_time,desc}],[1]).
 
