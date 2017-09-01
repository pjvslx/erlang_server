%%%------------------------------------------------	
%%% File    : tpl_task_factor.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_task_factor生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_task_factor). 	
-compile(export_all). 	
	
get(2, 0)->
	{temp_task_factor, 2, 0, 1.5, 10, 10, 100, {3849,4148},3};	
get(4, 1)->
	{temp_task_factor, 4, 1, 1.5, 5, 10, 100, {2349,2648},3};	
get(4, 2)->
	{temp_task_factor, 4, 2, 1.8, 10, 10, 200, {2349,2648},3};	
get(4, 3)->
	{temp_task_factor, 4, 3, 2, 15, 10, 300, {2349,2648},3};	
get(4, 4)->
	{temp_task_factor, 4, 4, 2.5, 20, 10, 400, {2349,2648},3};	
get(5, 0)->
	{temp_task_factor, 5, 0, 1.5, 10, 10, 100, {2649,2948},3};	
get(6, 0)->
	{temp_task_factor, 6, 0, 1.5, 10, 10, 100, {2949,3248},3};	
get(7, 0)->
	{temp_task_factor, 7, 0, 1.5, 10, 10, 100, {3249,3548},3};	
get(8, 0)->
	{temp_task_factor, 8, 0, 1.5, 10, 10, 100, {3549,3848},3};	
get(9, 1)->
	{temp_task_factor, 9, 1, 1, 2, 10, 50, {2049,2348},3};	
get(9, 2)->
	{temp_task_factor, 9, 2, 1.5, 5, 10, 100, {2049,2348},3};	
get(9, 3)->
	{temp_task_factor, 9, 3, 1.8, 10, 10, 200, {2049,2348},3};	
get(9, 4)->
	{temp_task_factor, 9, 4, 2, 15, 10, 300, {2049,2348},3};	
get(9, 5)->
	{temp_task_factor, 9, 5, 2.5, 20, 10, 400, {2049,2348},3};	
get(_, _)->	
	[].	
