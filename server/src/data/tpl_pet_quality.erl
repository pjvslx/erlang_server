%%%------------------------------------------------	
%%% File    : tpl_pet_quality.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_pet_quality生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_pet_quality). 	
-compile(export_all). 	
	
get(1)->
	{temp_pet_quality, 1, 1, 301, 255005201, 1000, 10000, 10000, 10, 10, [{attack,0},{fattack,0},{mattack,0},{dattack,0},{hit_ratio,0},{crit_ratio,0}]};	
get(2)->
	{temp_pet_quality, 2, 1, 301, 255005201, 2000, 5000, 1000, 20, 20, [{attack,512},{fattack,464},{mattack,464},{dattack,464},{hit_ratio,26},{crit_ratio,42}]};	
get(3)->
	{temp_pet_quality, 3, 2, 301, 255005202, 3000, 2500, 500, 30, 30, [{attack,1029},{fattack,932},{mattack,932},{dattack,932},{hit_ratio,52},{crit_ratio,84}]};	
get(4)->
	{temp_pet_quality, 4, 2, 302, 255005202, 4000, 2000, 400, 40, 40, [{attack,1552},{fattack,1405},{mattack,1405},{dattack,1405},{hit_ratio,79},{crit_ratio,126}]};	
get(5)->
	{temp_pet_quality, 5, 3, 302, 255005203, 5000, 1500, 300, 50, 50, [{attack,2079},{fattack,1883},{mattack,1883},{dattack,1883},{hit_ratio,106},{crit_ratio,169}]};	
get(6)->
	{temp_pet_quality, 6, 3, 302, 255005203, 6000, 1000, 200, 60, 60, [{attack,2612},{fattack,2365},{mattack,2365},{dattack,2365},{hit_ratio,133},{crit_ratio,213}]};	
get(7)->
	{temp_pet_quality, 7, 4, 303, 255005204, 7000, 500, 100, 70, 70, [{attack,3150},{fattack,2853},{mattack,2853},{dattack,2853},{hit_ratio,160},{crit_ratio,257}]};	
get(8)->
	{temp_pet_quality, 8, 4, 303, 255005204, 8000, 300, 100, 80, 80, [{attack,3694},{fattack,3345},{mattack,3345},{dattack,3345},{hit_ratio,188},{crit_ratio,301}]};	
get(9)->
	{temp_pet_quality, 9, 5, 303, 255005205, 9000, 100, 100, 90, 90, [{attack,4243},{fattack,3842},{mattack,3842},{dattack,3842},{hit_ratio,216},{crit_ratio,346}]};	
get(10)->
	{temp_pet_quality, 10, 5, 304, 255005205, 10000, 0, 100, 100, 100, [{attack,4797},{fattack,4344},{mattack,4344},{dattack,4344},{hit_ratio,244},{crit_ratio,391}]};	
get(_)->	
	[].	
