%%%------------------------------------------------	
%%% File    : tpl_guild_level.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_guild_level生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_guild_level). 	
-compile(export_all). 	
	
get(1)->
	{temp_guild_level, 1, 15, 7500};	
get(2)->
	{temp_guild_level, 2, 20, 10000};	
get(3)->
	{temp_guild_level, 3, 20, 10000};	
get(4)->
	{temp_guild_level, 4, 23, 11500};	
get(5)->
	{temp_guild_level, 5, 23, 11500};	
get(6)->
	{temp_guild_level, 6, 26, 13000};	
get(7)->
	{temp_guild_level, 7, 26, 13000};	
get(8)->
	{temp_guild_level, 8, 30, 15000};	
get(9)->
	{temp_guild_level, 9, 30, 15000};	
get(10)->
	{temp_guild_level, 10, 35, 16500};	
get(_)->	
	[].	
