%%%------------------------------------------------	
%%% File    : tpl_label.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_label生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_label). 	
-compile(export_all). 	
	
get(1)->
	{temp_label, 1, <<"背包">>, 1, 1, 3100, 1};	
get(2)->
	{temp_label, 2, <<"属性">>, 1, 1, 3100, 2};	
get(3)->
	{temp_label, 3, <<"信息">>, 1, 1, 3100, 3};	
get(4)->
	{temp_label, 4, <<"主动技能">>, 1, 1, 3200, 1};	
get(5)->
	{temp_label, 5, <<"被动技能">>, 1, 1, 3200, 2};	
get(6)->
	{temp_label, 6, <<"强化">>, 1, 20, 3300, 1};	
get(7)->
	{temp_label, 7, <<"合成">>, 1, 20, 3300, 2};	
get(8)->
	{temp_label, 8, <<"洗练">>, 1, 30, 3300, 3};	
get(9)->
	{temp_label, 9, <<"成长">>, 2, 25, 3400, 1};	
get(10)->
	{temp_label, 10, <<"幻化">>, 2, 88, 3400, 3};	
get(11)->
	{temp_label, 11, <<"技能">>, 2, 88, 3400, 2};	
get(12)->
	{temp_label, 12, <<"资质">>, 1, 45, 3400, 4};	
get(13)->
	{temp_label, 13, <<"升星">>, 2, 25, 3500, 1};	
get(14)->
	{temp_label, 14, <<"幻化">>, 2, 25, 3500, 2};	
get(15)->
	{temp_label, 15, <<"技能">>, 2, 25, 3500, 3};	
get(16)->
	{temp_label, 16, <<"星脉">>, 2, 25, 3600, 1};	
get(17)->
	{temp_label, 17, <<"月脉">>, 1, 44, 3600, 2};	
get(18)->
	{temp_label, 18, <<"邮件">>, 1, 1, 4200, 1};	
get(19)->
	{temp_label, 19, <<"好友">>, 1, 1, 4100, 1};	
get(20)->
	{temp_label, 20, <<"仇人">>, 1, 25, 4100, 2};	
get(21)->
	{temp_label, 21, <<"黑名单">>, 1, 25, 4100, 3};	
get(22)->
	{temp_label, 22, <<"查找玩家">>, 1, 25, 4100, 4};	
get(23)->
	{temp_label, 23, <<"阵营">>, 1, 32, 4400, 1};	
get(24)->
	{temp_label, 24, <<"帮派列表">>, 1, 33, 4300, 1};	
get(25)->
	{temp_label, 25, <<"战力">>, 1, 1, 5100, 1};	
get(26)->
	{temp_label, 26, <<"等级">>, 1, 1, 5100, 2};	
get(27)->
	{temp_label, 27, <<"武器">>, 1, 35, 5200, 1};	
get(28)->
	{temp_label, 28, <<"坐骑战力">>, 1, 35, 5300, 1};	
get(29)->
	{temp_label, 29, <<"宠物战力">>, 1, 35, 5300, 2};	
get(30)->
	{temp_label, 30, <<"帮派等级">>, 1, 35, 5400, 1};	
get(31)->
	{temp_label, 31, <<"昨日鲜花">>, 1, 35, 5500, 1};	
get(32)->
	{temp_label, 32, <<"鲜花总榜">>, 1, 35, 5500, 2};	
get(33)->
	{temp_label, 33, <<"试炼之路">>, 1, 35, 5600, 1};	
get(_)->	
	[].	
	
get_by_type_condition_id(1,1)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[1],[2],[3],[4],[5],[18],[19],[25],[26]]);	
	
get_by_type_condition_id(1,20)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[6],[7]]);	
	
get_by_type_condition_id(1,30)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[8]]);	
	
get_by_type_condition_id(2,25)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[9],[13],[14],[15],[16]]);	
	
get_by_type_condition_id(2,88)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[10],[11]]);	
	
get_by_type_condition_id(1,45)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[12]]);	
	
get_by_type_condition_id(1,44)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[17]]);	
	
get_by_type_condition_id(1,25)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[20],[21],[22]]);	
	
get_by_type_condition_id(1,32)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[23]]);	
	
get_by_type_condition_id(1,33)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[24]]);	
	
get_by_type_condition_id(1,35)->	
	 lists:map(fun([LEADER_ID])->tpl_label:get(LEADER_ID) end,
	[[27],[28],[29],[30],[31],[32],[33]]);	
	
get_by_type_condition_id(_,_)->	
 [].	
