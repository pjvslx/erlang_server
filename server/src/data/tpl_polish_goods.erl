%%%------------------------------------------------	
%%% File    : tpl_polish_goods.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_polish_goods生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_polish_goods). 	
-compile(export_all). 	
	
get(1)->
	{temp_polish_goods, 1, 0, [],0};	
get(2)->
	{temp_polish_goods, 2, 0, [],0};	
get(3)->
	{temp_polish_goods, 3, 0, [],0};	
get(4)->
	{temp_polish_goods, 4, 5, [{307004204,1}],600};	
get(5)->
	{temp_polish_goods, 5, 6, [{307004205,1}],1000};	
get(_)->	
	[].	
