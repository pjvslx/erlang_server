%%%------------------------------------------------	
%%% File    : temp_guild_level.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_guild_level生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(temp_guild_level). 	
-compile(export_all). 	
	
get(1)->
	{temp_guild_level, 1, 15, 150};	
get(2)->
	{temp_guild_level, 2, 20, 200};	
get(3)->
	{temp_guild_level, 3, 25, 250};	
get(4)->
	{temp_guild_level, 4, 30, 300};	
get(5)->
	{temp_guild_level, 5, 35, 350};	
get(6)->
	{temp_guild_level, 6, 40, 400};	
get(7)->
	{temp_guild_level, 7, 45, 450};	
get(8)->
	{temp_guild_level, 8, 50, 500};	
get(9)->
	{temp_guild_level, 9, 60, 600};	
get(10)->
	{temp_guild_level, 10, 100, 1000};	
get(_)->	
	[].	
