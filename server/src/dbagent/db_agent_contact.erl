%%--------------------------------------
%% @Module  : db_agent_contact
%% @Author  : ly
%% @Created : 2013.10.29
%% @Description: 联系人
%%--------------------------------------
-module(db_agent_contact).

-include("common.hrl").
-include("record.hrl").

-compile(export_all).

get_contact(PlayerId) ->
	case ?DB_MODULE:select_row(contact, "*", [{uid, PlayerId}], [], [1]) of
		[] ->
			[];
		R ->
			Contact = list_to_tuple([contact|R]),
			Contact#contact{
							  	contact_list = util:bitstring_to_term(Contact#contact.contact_list)
							 }
	end.

insert_contact(Contact) ->
	ContactForDB = Contact#contact{
						contact_list = util:term_to_string(Contact#contact.contact_list)
					},
	ValueList = lists:nthtail(1, tuple_to_list(ContactForDB)),
    FieldList = record_info(fields, contact),
    ?DB_MODULE:insert(contact, FieldList, ValueList).


update_activity(Contact) ->
	ContactForDB = Contact#contact{
						contact_list = util:term_to_string(Contact#contact.contact_list)
					},
	ValueList = lists:nthtail(1, tuple_to_list(ContactForDB)),
	FieldList = record_info(fields, contact),
	?DB_MODULE:update(contact, FieldList, ValueList, uid, Contact#contact.uid).