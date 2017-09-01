%%%------------------------------------------------	
%%% File    : tpl_all_polish_reward.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_all_polish_reward生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_all_polish_reward). 	
-compile(export_all). 	
	
get(2)->
	{temp_all_polish_reward, 2, [{hit_point_max,200}]};	
get(4)->
	{temp_all_polish_reward, 4, [{hit_point_max,300},{attack,50}]};	
get(6)->
	{temp_all_polish_reward, 6, [{hit_point_max,400},{attack,150},{defense,50}]};	
get(8)->
	{temp_all_polish_reward, 8, [{hit_point_max,500},{attack,250},{defense,150}]};	
get(10)->
	{temp_all_polish_reward, 10, [{hit_point_max,600},{attack,400},{defense,300}]};	
get(_)->	
	[].	
