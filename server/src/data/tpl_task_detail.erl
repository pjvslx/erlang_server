%%%------------------------------------------------	
%%% File    : tpl_task_detail.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_task_detail生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_task_detail). 	
-compile(export_all). 	
	
get(0)->
	{temp_task_detail, 0, 0, 1, 1, 1, [],{},0};	
get(1)->
	{temp_task_detail, 1, 0, 1, 1, 1, [],{},0};	
get(2)->
	{temp_task_detail, 2, 1, 1, 10, 1, [],{},5};	
get(4)->
	{temp_task_detail, 4, 1, 1, 5, 5, [],{},5};	
get(5)->
	{temp_task_detail, 5, 1, 1, 10, 1, [],{},5};	
get(6)->
	{temp_task_detail, 6, 1, 1, 10, 1, [],{},5};	
get(7)->
	{temp_task_detail, 7, 1, 1, 10, 1, [],{},5};	
get(8)->
	{temp_task_detail, 8, 1, 1, 10, 1, [],{},5};	
get(9)->
	{temp_task_detail, 9, 1, 1, 10, 5, [],{},5};	
get(_)->	
	[].	
