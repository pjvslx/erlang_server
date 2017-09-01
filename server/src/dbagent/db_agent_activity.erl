%%--------------------------------------
%% @Module  : db_agent_activity
%% @Author  : ly
%% @Created : 2013.09.26
%% @Description: 活跃度
%%--------------------------------------
-module(db_agent_activity).

-include("common.hrl").
-include("record.hrl").

-compile(export_all).

get_activity(PlayerId) ->
	case ?DB_MODULE:select_row(activity, "*", [{uid, PlayerId}], [], [1]) of
		[] ->
			[];
		R ->
			Activity = list_to_tuple([activity|R]),
			Activity#activity{
							  	active_cur = util:bitstring_to_term(Activity#activity.active_cur),
								reward_cur = util:bitstring_to_term(Activity#activity.reward_cur)
							 }
	end.

insert_activity(Activity) ->
	ActivityForDB = Activity#activity{
						active_cur = util:term_to_string(Activity#activity.active_cur),
						reward_cur = util:term_to_string(Activity#activity.reward_cur)
					},
	ValueList = lists:nthtail(1, tuple_to_list(ActivityForDB)),
    FieldList = record_info(fields, activity),
    ?DB_MODULE:insert(activity, FieldList, ValueList).

update_activity(Activity) ->
	ActivityForDB = Activity#activity{
						active_cur = util:term_to_string(Activity#activity.active_cur),
						reward_cur = util:term_to_string(Activity#activity.reward_cur)
					},
	ValueList = lists:nthtail(1, tuple_to_list(ActivityForDB)),
	FieldList = record_info(fields, activity),
	?DB_MODULE:update(activity, FieldList, ValueList, uid, Activity#activity.uid).