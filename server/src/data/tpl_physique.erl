%%%------------------------------------------------	
%%% File    : tpl_physique.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_physique生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_physique). 	
-compile(export_all). 	
	
get(1)->
	{tpl_physique, 1, <<"任脉">>, [{4,a,10}],2, 1};	
get(2)->
	{tpl_physique, 2, <<"督脉">>, [{1,b,10},{2,c,10}],-1, 1};	
get(_)->	
	[].	
