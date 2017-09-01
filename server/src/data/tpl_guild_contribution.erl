%%%------------------------------------------------	
%%% File    : tpl_guild_contribution.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_guild_contribution生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_guild_contribution). 	
-compile(export_all). 	
	
get(1)->
	{temp_guild_contribution, 1, 50, 50};	
get(2)->
	{temp_guild_contribution, 2, 1, 1};	
get(_)->	
	[].	
