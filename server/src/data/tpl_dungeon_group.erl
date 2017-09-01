%%%------------------------------------------------	
%%% File    : tpl_dungeon_group.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_dungeon_group生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_dungeon_group). 	
-compile(export_all). 	
	
get(10001)->
	{temp_dungeon_group, 10001, <<"试炼之路">>, 10, "",10037};	
get(10002)->
	{temp_dungeon_group, 10002, <<"六道轮回">>, 10, "",10011};	
get(_)->	
	[].	
