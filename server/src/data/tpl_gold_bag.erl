%%%------------------------------------------------	
%%% File    : tpl_gold_bag.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_gold_bag生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_gold_bag). 	
-compile(export_all). 	
	
get(1)->
	{temp_gold_bag, 1, 5};	
get(_)->	
	[].	
