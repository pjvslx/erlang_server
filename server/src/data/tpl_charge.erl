%%%------------------------------------------------	
%%% File    : tpl_charge.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_charge生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_charge). 	
-compile(export_all). 	
	
get(10)->
	{temp_charge, 10, 100, <<"0">>};	
get(30)->
	{temp_charge, 30, 300, <<"0">>};	
get(50)->
	{temp_charge, 50, 525, <<"送5%">>};	
get(100)->
	{temp_charge, 100, 1080, <<"送8%">>};	
get(200)->
	{temp_charge, 200, 2360, <<"超值赠送18%">>};	
get(500)->
	{temp_charge, 500, 6250, <<"超值赠送25%">>};	
get(_)->	
	[].	
