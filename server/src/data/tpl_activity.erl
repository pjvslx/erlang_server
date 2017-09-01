%%%------------------------------------------------	
%%% File    : tpl_activity.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_activity生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_activity). 	
-compile(export_all). 	
	
get(1)->
	{temp_activity, 1, 1, <<"单人修炼">>, 1, <<"发布天道令任务">>, 1, 1, 5, [2000,2]};	
get(2)->
	{temp_activity, 2, 1, <<"单人修炼">>, 2, <<"领取师门令任务">>, 1, 1, 5, [2000,2]};	
get(3)->
	{temp_activity, 3, 1, <<"单人修炼">>, 3, <<"完成聚宝阁任务">>, 1, 1, 5, [2000,2]};	
get(4)->
	{temp_activity, 4, 1, <<"单人修炼">>, 4, <<"完成自强不息任务">>, 1, 1, 5, [2000,2]};	
get(5)->
	{temp_activity, 5, 1, <<"单人修炼">>, 5, <<"完成试炼之路">>, 1, 1, 5, [2000,2]};	
get(6)->
	{temp_activity, 6, 2, <<"互通有无">>, 1, <<"阵营任务">>, 1, 1, 5, [2000,2]};	
get(7)->
	{temp_activity, 7, 2, <<"互通有无">>, 2, <<"赠送鲜花">>, 1, 1, 5, [2000,2]};	
get(8)->
	{temp_activity, 8, 3, <<"提升战力">>, 1, <<"完成强化">>, 1, 1, 5, [2000,2]};	
get(9)->
	{temp_activity, 9, 3, <<"提升战力">>, 2, <<"完成洗炼">>, 1, 1, 5, [2000,2]};	
get(10)->
	{temp_activity, 10, 3, <<"提升战力">>, 3, <<"完成镶嵌">>, 1, 1, 5, [2000,2]};	
get(11)->
	{temp_activity, 11, 3, <<"提升战力">>, 4, <<"完成合成">>, 1, 1, 5, [2000,2]};	
get(12)->
	{temp_activity, 12, 3, <<"提升战力">>, 5, <<"宠物升星">>, 1, 1, 5, [2000,2]};	
get(13)->
	{temp_activity, 13, 3, <<"提升战力">>, 6, <<"坐骑升星">>, 1, 1, 5, [2000,2]};	
get(14)->
	{temp_activity, 14, 3, <<"提升战力">>, 7, <<"星脉">>, 1, 1, 5, [2000,2]};	
get(15)->
	{temp_activity, 15, 3, <<"提升战力">>, 8, <<"月脉">>, 1, 1, 5, [2000,2]};	
get(16)->
	{temp_activity, 16, 4, <<"修仙之路">>, 1, <<"在线15分钟">>, 2, 15, 5, [2000,2]};	
get(17)->
	{temp_activity, 17, 4, <<"修仙之路">>, 2, <<"在线半小时">>, 2, 30, 5, [2000,2]};	
get(18)->
	{temp_activity, 18, 4, <<"修仙之路">>, 3, <<"商城刷新">>, 1, 1, 5, [2000,2]};	
get(19)->
	{temp_activity, 19, 4, <<"修仙之路">>, 4, <<"商城购物">>, 1, 1, 5, [2000,2]};	
get(_)->	
	[].	
	
get_by_btype_stype(1,1)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[1]]);	
	
get_by_btype_stype(1,2)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[2]]);	
	
get_by_btype_stype(1,3)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[3]]);	
	
get_by_btype_stype(1,4)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[4]]);	
	
get_by_btype_stype(1,5)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[5]]);	
	
get_by_btype_stype(2,1)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[6]]);	
	
get_by_btype_stype(2,2)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[7]]);	
	
get_by_btype_stype(3,1)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[8]]);	
	
get_by_btype_stype(3,2)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[9]]);	
	
get_by_btype_stype(3,3)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[10]]);	
	
get_by_btype_stype(3,4)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[11]]);	
	
get_by_btype_stype(3,5)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[12]]);	
	
get_by_btype_stype(3,6)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[13]]);	
	
get_by_btype_stype(3,7)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[14]]);	
	
get_by_btype_stype(3,8)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[15]]);	
	
get_by_btype_stype(4,1)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[16]]);	
	
get_by_btype_stype(4,2)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[17]]);	
	
get_by_btype_stype(4,3)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[18]]);	
	
get_by_btype_stype(4,4)->	
	 lists:map(fun([ID])->tpl_activity:get(ID) end,
	[[19]]);	
	
get_by_btype_stype(_,_)->	
 [].	
