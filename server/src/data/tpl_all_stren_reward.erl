%%%------------------------------------------------	
%%% File    : tpl_all_stren_reward.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_all_stren_reward生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_all_stren_reward). 	
-compile(export_all). 	
	
get(55)->
	{temp_all_stren_reward, 55, [{hit_point_max,100},{attack,20}]};	
get(66)->
	{temp_all_stren_reward, 66, [{hit_point_max,200},{magic_max,50},{attack,35}]};	
get(77)->
	{temp_all_stren_reward, 77, [{hit_point_max,350},{magic_max,100},{attack,55}]};	
get(88)->
	{temp_all_stren_reward, 88, [{hit_point_max,500},{magic_max,140},{attack,70}]};	
get(99)->
	{temp_all_stren_reward, 99, [{hit_point_max,700},{magic_max,180},{attack,100}]};	
get(110)->
	{temp_all_stren_reward, 110, [{hit_point_max,1000},{magic_max,230},{attack,150}]};	
get(_)->	
	[].	
