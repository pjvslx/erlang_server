%%%------------------------------------------------	
%%% File    : tpl_cultivation.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_cultivation生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_cultivation). 	
-compile(export_all). 	
	
get(1)->
	{tpl_cultivation, 1, 10, 10, 10, <<"结丹">>, [{1,hit_point_max,100}],20};	
get(_)->	
	[].	
