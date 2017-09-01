-module(db_agent_opera).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%% 加载玩家的剧情
select_opera(UId) ->
	case ?DB_MODULE:select_row(opera,"*", [{uid, UId}],[],[1]) of
		[] ->
			OperaRcd = #opera{uid = UId} ,
			insert_opera(OperaRcd) ,
			OperaRcd ;
		DataList ->
			OperaRcd = list_to_tuple([opera|DataList]) ,
			OperaRcd#opera{
						   operaDialogue = util:bitstring_to_term(OperaRcd#opera.operaDialogue),
						   operaAnimation = util:bitstring_to_term(OperaRcd#opera.operaAnimation)
						   } 
	end .

%% 插入玩家剧情记录
insert_opera(OperaRcd) ->
	FieldList = record_info(fields, opera) ,
	ValueList = lists:nthtail(1, tuple_to_list(OperaRcd#opera{operaDialogue = util:term_to_string(OperaRcd#opera.operaDialogue),
															  operaAnimation = util:term_to_string(OperaRcd#opera.operaAnimation)})),
	?DB_MODULE:insert(opera, FieldList, ValueList).


%% 保存玩家剧情记录
update_opera(OperaRcd) ->
	?DB_MODULE:update(opera,
					  [{operaDialogue, util:term_to_string(OperaRcd#opera.operaDialogue)},
					   {operaAnimation, util:term_to_string(OperaRcd#opera.operaAnimation)}
					  ],
					  [{uid, OperaRcd#opera.uid}]).





