%%%------------------------------------------------	
%%% File    : tpl_pet_skill_list.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_pet_skill_list生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_pet_skill_list). 	
-compile(export_all). 	
	
get(1)->
	{temp_pet_skill_list, 1, 0, 0};	
get(2)->
	{temp_pet_skill_list, 2, 0, 0};	
get(3)->
	{temp_pet_skill_list, 3, 1, 10};	
get(4)->
	{temp_pet_skill_list, 4, 1, 20};	
get(5)->
	{temp_pet_skill_list, 5, 1, 30};	
get(6)->
	{temp_pet_skill_list, 6, 1, 40};	
get(7)->
	{temp_pet_skill_list, 7, 1, 50};	
get(8)->
	{temp_pet_skill_list, 8, 2, 55};	
get(9)->
	{temp_pet_skill_list, 9, 2, 60};	
get(10)->
	{temp_pet_skill_list, 10, 2, 70};	
get(11)->
	{temp_pet_skill_list, 11, 2, 80};	
get(12)->
	{temp_pet_skill_list, 12, 2, 90};	
get(_)->	
	[].	
	
get_by_type_condition_id(0,0)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[1],[2]]);	
	
get_by_type_condition_id(1,10)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[3]]);	
	
get_by_type_condition_id(1,20)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[4]]);	
	
get_by_type_condition_id(1,30)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[5]]);	
	
get_by_type_condition_id(1,40)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[6]]);	
	
get_by_type_condition_id(1,50)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[7]]);	
	
get_by_type_condition_id(2,55)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[8]]);	
	
get_by_type_condition_id(2,60)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[9]]);	
	
get_by_type_condition_id(2,70)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[10]]);	
	
get_by_type_condition_id(2,80)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[11]]);	
	
get_by_type_condition_id(2,90)->	
	 lists:map(fun([LIST_ID])->tpl_pet_skill_list:get(LIST_ID) end,
	[[12]]);	
	
get_by_type_condition_id(_,_)->	
 [].	
