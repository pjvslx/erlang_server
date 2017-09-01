%%--------------------------------------
%% @Module: db_agent_leader
%% Author:  luyang
%% Created: 2013/08/21
%% Description: 新手引导写数据库
%%--------------------------------------
-module(db_agent_leader).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

get_leader(PlayerId) ->
	case ?DB_MODULE:select_row(leader, "*", [{uid, PlayerId}], [], [1]) of
        [] -> [];
        R  -> Leader = list_to_tuple([leader|R]),
			  Leader#leader{
                            navi_list = util:bitstring_to_term(Leader#leader.navi_list),
							open_list = util:bitstring_to_term(Leader#leader.open_list),
							start_sk_list = util:bitstring_to_term(Leader#leader.start_sk_list),
							end_sk_list = util:bitstring_to_term(Leader#leader.end_sk_list)
                         }
    end.

%%新建玩家新手引导记录
insert_leader(Leader) ->
    LeaderForDB = Leader#leader{
						navi_list = util:term_to_string(Leader#leader.navi_list),
						open_list = util:term_to_string(Leader#leader.open_list),
						start_sk_list = util:term_to_string(Leader#leader.start_sk_list),
						end_sk_list = util:term_to_string(Leader#leader.end_sk_list)
                       },
    ValueList = lists:nthtail(1, tuple_to_list(LeaderForDB)),
    FieldList = record_info(fields, leader),
    ?DB_MODULE:insert(leader, FieldList, ValueList).

%%更新座骑记录
update_leader(Leader) ->
    LeaderForDB = Leader#leader{
						navi_list = util:term_to_string(Leader#leader.navi_list),
						open_list = util:term_to_string(Leader#leader.open_list),
						start_sk_list = util:term_to_string(Leader#leader.start_sk_list),
						end_sk_list = util:term_to_string(Leader#leader.end_sk_list)	   
                       },
    [_Uid|ValueList] = lists:nthtail(1, tuple_to_list(LeaderForDB)),
    [uid|FieldList] = record_info(fields, leader),
    ?DB_MODULE:update(leader, FieldList, ValueList, uid, Leader#leader.uid).