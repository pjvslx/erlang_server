%%--------------------------------------
%% @Module: db_agent_notice
%% Author:  luyang
%% Created: 2013/10/24
%% Description: 信息提示系统写数据库
%%--------------------------------------
-module(db_agent_notice).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%获取气泡信息数据
get_bunble(PlayerId) ->
	case ?DB_MODULE:select_row(bubble_msg,"*",[{uid,PlayerId}],[],[1]) of
		[] -> [];
		R  -> BunbleMsg = list_to_tuple([bubble_msg|R]),
			  BunbleMsg#bubble_msg{
								   msg = util:bitstring_to_term(BunbleMsg#bubble_msg.msg)
								   }
	end.

%插入气泡信息数据
insert_bunble(BunbleMsg) ->
	BunbleForDB = BunbleMsg#bubble_msg{
								   msg = util:term_to_string(BunbleMsg#bubble_msg.msg)
								   },
	ValueList = lists:nthtail(1, tuple_to_list(BunbleForDB)),
    FieldList = record_info(fields, bubble_msg),
    ?DB_MODULE:insert(bubble_msg, FieldList, ValueList).

%更新气泡信息数据
update_bunble(BunbleMsg) ->
	BunbleForDB = BunbleMsg#bubble_msg{
								   msg = util:term_to_string(BunbleMsg#bubble_msg.msg)
								   },
	[_Uid|ValueList] = lists:nthtail(1, tuple_to_list(BunbleForDB)),
    [uid|FieldList] = record_info(fields, bubble_msg),
    ?DB_MODULE:update(bubble_msg, FieldList, ValueList, uid, BunbleMsg#bubble_msg.uid).


