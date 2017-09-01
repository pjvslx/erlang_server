%%%----------------------------------------
%%% @Module  : data_agent
%%% @Author  : csj
%%% @Created : 2010.09.16
%%% @Description: 数据转换常用函数
%%%----------------------------------------
-module(data_agent).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
		
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convert_requirement(D) ->
	try
	{ok, D1, []}  = rfc4627:decode(D), 
	[{obj, Obj1},
     {obj, Obj2},
     {obj, Obj3}] = D1,
	{value,{"type", P1}} =  lists:keysearch("type",1, Obj1),
	{value,{"attr", V1}} =  lists:keysearch("attr",1, Obj1),
	{value,{"type", P2}} =  lists:keysearch("type",1, Obj2),
	{value,{"attr", V2}} =  lists:keysearch("attr",1, Obj2),
	{value,{"type", P3}} =  lists:keysearch("type",1, Obj3),
	{value,{"attr", V3}} =  lists:keysearch("attr",1, Obj3),
	[{util:string_to_term(tool:to_list(P1)), util:string_to_term(tool:to_list(V1))}, 
	 {util:string_to_term(tool:to_list(P2)), util:string_to_term(tool:to_list(V2))},
	 {util:string_to_term(tool:to_list(P3)), util:string_to_term(tool:to_list(V3))}]
	catch
		_:_ -> []
	end.

convert_elem(D) ->
	try
	{ok, D1, []}  = rfc4627:decode(D), 
	lists:map(fun(D2) ->
			   {obj,L} = D2,
			   {value,{"id", Id}} =  lists:keysearch("id",1, L),
			   {value,{"x", X}} =  lists:keysearch("x",1, L),
			   {value,{"y", Y}} =  lists:keysearch("y",1, L),
			   {value,{"name", Name}} =  lists:keysearch("name",1, L),			   
			    [util:string_to_term(tool:to_list(Id)), 
				 Name, 
				 util:string_to_term(tool:to_list(X)), 
				 util:string_to_term(tool:to_list(Y))
				 ]
			end, 
			D1)
	catch
		_:_ -> []
	end.	

convert_npc(D) ->
	try
	{ok, D1, []}  = rfc4627:decode(D), 
	lists:map(fun(D2) ->
			   {obj,L} = D2,
			   {value,{"id", Id}} =  lists:keysearch("id",1, L),
			   {value,{"x", X}} =  lists:keysearch("x",1, L),
			   {value,{"y", Y}} =  lists:keysearch("y",1, L),
			    [util:string_to_term(tool:to_list(Id)), 
				 util:string_to_term(tool:to_list(X)), 
				 util:string_to_term(tool:to_list(Y))
				]
			end, 
			D1)
	catch
		_:_ -> []
	end.	

convert_mon(D) ->
	try
	{ok, D1, []}  = rfc4627:decode(D), 
	lists:map(fun(D2) ->
			   {obj,L} = D2,
			   {value,{"id", Id}} =  lists:keysearch("id",1, L),
			   {value,{"x", X}} =  lists:keysearch("x",1, L),
			   {value,{"y", Y}} =  lists:keysearch("y",1, L),
			   {value,{"lv", Lv}} =  lists:keysearch("lv",1, L),
			    [util:string_to_term(tool:to_list(Id)), 
				 util:string_to_term(tool:to_list(X)), 
				 util:string_to_term(tool:to_list(Y)),
				 util:string_to_term(tool:to_list(Lv))
				]
			end, 
			D1)
	catch
		_:_ -> []
	end.	

convert_talk(D) ->
	try
	{ok, D1, []}  = rfc4627:decode(D), 
	lists:foldr(fun(D2, AccList) ->
				[get_talk_childs(D2) | AccList]
				end, 
				[],D1)
	catch
		_:_ -> []
	end.

get_talk_childs(D) ->
	try
	lists:foldr(fun(D2, AccList) ->
				Ret = 		
			   		case D2 of
						[A1, A2] -> 
							{util:string_to_term(tool:to_list(A1)),A2, []};
						[A1,A2,A3] -> 
							{util:string_to_term(tool:to_list(A1)),A2, [util:string_to_term(tool:to_list(A3))]}
					end,
				[Ret | AccList]
			end, 
			[],D)
	catch
		_:_ -> []
	end.


task_getItemCode(Item)-> 
	try
	case rfc4627:decode(Item) of
		{ok, null,[]} -> [];
		{ok, D1, []} -> 
			lists:foldr(fun(D2, AccList) ->
				  R1 =
					lists:foldr(fun(D3, AccList1) ->
							[util:string_to_term(tool:to_list(D3)) | AccList1]
						end, 
						[],D2),	
				[list_to_tuple(R1) | AccList]
				end, 
				[],D1)
	end
	catch
		_:_ -> []
	end.

task_getItemCodes(Item, Content) ->
	try
	ItemCode = task_getItemCode(Item),
	ContentCode = 
	case rfc4627:decode(Content) of
		{ok, null,[]} -> [];
		{ok, [D1], []} -> 
			lists:foldr(fun(D2, AccList) ->
				  [A0, A1, A2 | _] = D2,
				  case tool:to_list(A0) of
					  "item" -> [{util:string_to_term(tool:to_list(A1)), util:string_to_term(tool:to_list(A2))}| AccList];
					  _->  AccList
				  end
				end, 
				[],D1)
	end,
	ItemCode ++ ContentCode
	catch
		_:_ -> []
	end.
  
task_getTagCode(Str) ->
	case util:string_to_term(tool:to_list(Str)) of
		null -> [];
		I1 -> I1
	end.	
 

task_valToTagCode(Val) ->	
	try
		util:string_to_term(tool:to_list(Val))
	catch
		_:_ -> 0
	end.
 

task_getConditionCode(Codition) ->
	try
	case rfc4627:decode(Codition) of
		{ok, null,[]} -> [];
		{ok, D1, []} -> 
			lists:foldr(fun(D2, AccList) ->
				  R1 =
					lists:foldr(fun(D3, AccList1) ->
							[util:string_to_term(tool:to_list(D3)) | AccList1]
						end, 
						[],D2),	
				[list_to_tuple(R1) | AccList]
				end, 
				[],D1)
	end
	catch
		_:_ -> []
	end.	
 
 
 