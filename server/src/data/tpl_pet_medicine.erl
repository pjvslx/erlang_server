%%%------------------------------------------------	
%%% File    : tpl_pet_medicine.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_pet_medicine生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_pet_medicine). 	
-compile(export_all). 	
	
get(251005201)->
	{temp_pet_medicine, 251005201, 0, 65};	
get(251005202)->
	{temp_pet_medicine, 251005202, 0, 260};	
get(251005203)->
	{temp_pet_medicine, 251005203, 0, 1040};	
get(251005204)->
	{temp_pet_medicine, 251005204, 0, 4160};	
get(251005205)->
	{temp_pet_medicine, 251005205, 0, 16640};	
get(253005201)->
	{temp_pet_medicine, 253005201, 40, 0};	
get(253005202)->
	{temp_pet_medicine, 253005202, 160, 0};	
get(253005203)->
	{temp_pet_medicine, 253005203, 640, 0};	
get(253005204)->
	{temp_pet_medicine, 253005204, 2560, 0};	
get(253005205)->
	{temp_pet_medicine, 253005205, 10240, 0};	
get(_)->	
	[].	
