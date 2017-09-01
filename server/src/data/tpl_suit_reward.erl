%%%------------------------------------------------	
%%% File    : tpl_suit_reward.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_suit_reward生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_suit_reward). 	
-compile(export_all). 	
	
get(1003, 2)->
	{temp_suit_reward, 1003, 2, [{fdefence,25}]};	
get(1003, 4)->
	{temp_suit_reward, 1003, 4, [{fdefence,25},{mdefence,25}]};	
get(1003, 6)->
	{temp_suit_reward, 1003, 6, [{fdefence,25},{mdefence,25},{ddefence,25}]};	
get(1004, 2)->
	{temp_suit_reward, 1004, 2, [{fdefence,50}]};	
get(1004, 4)->
	{temp_suit_reward, 1004, 4, [{fdefence,50},{mdefence,50}]};	
get(1004, 6)->
	{temp_suit_reward, 1004, 6, [{fdefence,50},{mdefence,50},{ddefence,50}]};	
get(1005, 2)->
	{temp_suit_reward, 1005, 2, [{fdefence,75}]};	
get(1005, 4)->
	{temp_suit_reward, 1005, 4, [{fdefence,75},{mdefence,75}]};	
get(1005, 6)->
	{temp_suit_reward, 1005, 6, [{fdefence,75},{mdefence,75},{ddefence,75}]};	
get(1006, 2)->
	{temp_suit_reward, 1006, 2, [{fdefence,100}]};	
get(1006, 4)->
	{temp_suit_reward, 1006, 4, [{fdefence,100},{mdefence,100}]};	
get(1006, 6)->
	{temp_suit_reward, 1006, 6, [{fdefence,100},{mdefence,100},{ddefence,100}]};	
get(1007, 2)->
	{temp_suit_reward, 1007, 2, [{fdefence,125}]};	
get(1007, 4)->
	{temp_suit_reward, 1007, 4, [{fdefence,125},{mdefence,125}]};	
get(1007, 6)->
	{temp_suit_reward, 1007, 6, [{fdefence,125},{mdefence,125},{ddefence,125}]};	
get(1008, 2)->
	{temp_suit_reward, 1008, 2, [{fdefence,150}]};	
get(1008, 4)->
	{temp_suit_reward, 1008, 4, [{fdefence,150},{mdefence,150}]};	
get(1008, 6)->
	{temp_suit_reward, 1008, 6, [{fdefence,150},{mdefence,150},{ddefence,150}]};	
get(1009, 2)->
	{temp_suit_reward, 1009, 2, [{fdefence,175}]};	
get(1009, 4)->
	{temp_suit_reward, 1009, 4, [{fdefence,175},{mdefence,175}]};	
get(1009, 6)->
	{temp_suit_reward, 1009, 6, [{fdefence,175},{mdefence,175},{ddefence,175}]};	
get(1010, 2)->
	{temp_suit_reward, 1010, 2, [{fdefence,200}]};	
get(1010, 4)->
	{temp_suit_reward, 1010, 4, [{fdefence,200},{mdefence,200}]};	
get(1010, 6)->
	{temp_suit_reward, 1010, 6, [{fdefence,200},{mdefence,200},{ddefence,200}]};	
get(1103, 2)->
	{temp_suit_reward, 1103, 2, [{defence,25}]};	
get(1103, 4)->
	{temp_suit_reward, 1103, 4, [{defence,25},{hit_point_max,250}]};	
get(1103, 5)->
	{temp_suit_reward, 1103, 5, [{defence,25},{hit_point_max,250},{attack,25}]};	
get(1104, 2)->
	{temp_suit_reward, 1104, 2, [{defence,50}]};	
get(1104, 4)->
	{temp_suit_reward, 1104, 4, [{defence,50},{hit_point_max,500}]};	
get(1104, 5)->
	{temp_suit_reward, 1104, 5, [{defence,50},{hit_point_max,500},{attack,50}]};	
get(1105, 2)->
	{temp_suit_reward, 1105, 2, [{defence,75}]};	
get(1105, 4)->
	{temp_suit_reward, 1105, 4, [{defence,75},{hit_point_max,750}]};	
get(1105, 5)->
	{temp_suit_reward, 1105, 5, [{defence,75},{hit_point_max,750},{attack,75}]};	
get(1106, 2)->
	{temp_suit_reward, 1106, 2, [{defence,100}]};	
get(1106, 4)->
	{temp_suit_reward, 1106, 4, [{defence,100},{hit_point_max,1000}]};	
get(1106, 5)->
	{temp_suit_reward, 1106, 5, [{defence,100},{hit_point_max,1000},{attack,100}]};	
get(1107, 2)->
	{temp_suit_reward, 1107, 2, [{defence,125}]};	
get(1107, 4)->
	{temp_suit_reward, 1107, 4, [{defence,125},{hit_point_max,1250}]};	
get(1107, 5)->
	{temp_suit_reward, 1107, 5, [{defence,125},{hit_point_max,1250},{attack,125}]};	
get(1108, 2)->
	{temp_suit_reward, 1108, 2, [{defence,150}]};	
get(1108, 4)->
	{temp_suit_reward, 1108, 4, [{defence,150},{hit_point_max,1500}]};	
get(1108, 5)->
	{temp_suit_reward, 1108, 5, [{defence,150},{hit_point_max,1500},{attack,150}]};	
get(1109, 2)->
	{temp_suit_reward, 1109, 2, [{defence,175}]};	
get(1109, 4)->
	{temp_suit_reward, 1109, 4, [{defence,175},{hit_point_max,1750}]};	
get(1109, 5)->
	{temp_suit_reward, 1109, 5, [{defence,175},{hit_point_max,1750},{attack,175}]};	
get(1110, 2)->
	{temp_suit_reward, 1110, 2, [{defence,200}]};	
get(1110, 4)->
	{temp_suit_reward, 1110, 4, [{defence,200},{hit_point_max,2000}]};	
get(1110, 5)->
	{temp_suit_reward, 1110, 5, [{defence,200},{hit_point_max,2000},{attack,2000}]};	
get(1303, 2)->
	{temp_suit_reward, 1303, 2, [{fdefence,25}]};	
get(1303, 4)->
	{temp_suit_reward, 1303, 4, [{fdefence,25},{mdefence,25}]};	
get(1303, 6)->
	{temp_suit_reward, 1303, 6, [{fdefence,25},{mdefence,25},{ddefence,25}]};	
get(1304, 2)->
	{temp_suit_reward, 1304, 2, [{fdefence,50}]};	
get(1304, 4)->
	{temp_suit_reward, 1304, 4, [{fdefence,50},{mdefence,50}]};	
get(1304, 6)->
	{temp_suit_reward, 1304, 6, [{fdefence,50},{mdefence,50},{ddefence,50}]};	
get(1305, 2)->
	{temp_suit_reward, 1305, 2, [{fdefence,75}]};	
get(1305, 4)->
	{temp_suit_reward, 1305, 4, [{fdefence,75},{mdefence,75}]};	
get(1305, 6)->
	{temp_suit_reward, 1305, 6, [{fdefence,75},{mdefence,75},{ddefence,75}]};	
get(1306, 2)->
	{temp_suit_reward, 1306, 2, [{fdefence,100}]};	
get(1306, 4)->
	{temp_suit_reward, 1306, 4, [{fdefence,100},{mdefence,100}]};	
get(1306, 6)->
	{temp_suit_reward, 1306, 6, [{fdefence,100},{mdefence,100},{ddefence,100}]};	
get(1307, 2)->
	{temp_suit_reward, 1307, 2, [{fdefence,125}]};	
get(1307, 4)->
	{temp_suit_reward, 1307, 4, [{fdefence,125},{mdefence,125}]};	
get(1307, 6)->
	{temp_suit_reward, 1307, 6, [{fdefence,125},{mdefence,125},{ddefence,125}]};	
get(1308, 2)->
	{temp_suit_reward, 1308, 2, [{fdefence,150}]};	
get(1308, 4)->
	{temp_suit_reward, 1308, 4, [{fdefence,150},{mdefence,150}]};	
get(1308, 6)->
	{temp_suit_reward, 1308, 6, [{fdefence,150},{mdefence,150},{ddefence,150}]};	
get(1309, 2)->
	{temp_suit_reward, 1309, 2, [{fdefence,175}]};	
get(1309, 4)->
	{temp_suit_reward, 1309, 4, [{fdefence,175},{mdefence,175}]};	
get(1309, 6)->
	{temp_suit_reward, 1309, 6, [{fdefence,175},{mdefence,175},{ddefence,175}]};	
get(1310, 2)->
	{temp_suit_reward, 1310, 2, [{fdefence,200}]};	
get(1310, 4)->
	{temp_suit_reward, 1310, 4, [{fdefence,200},{mdefence,200}]};	
get(1310, 6)->
	{temp_suit_reward, 1310, 6, [{fdefence,200},{mdefence,200},{ddefence,200}]};	
get(1403, 2)->
	{temp_suit_reward, 1403, 2, [{defence,25}]};	
get(1403, 4)->
	{temp_suit_reward, 1403, 4, [{defence,25},{hit_point_max,250}]};	
get(1403, 5)->
	{temp_suit_reward, 1403, 5, [{defence,25},{hit_point_max,250},{attack,25}]};	
get(1404, 2)->
	{temp_suit_reward, 1404, 2, [{defence,50}]};	
get(1404, 4)->
	{temp_suit_reward, 1404, 4, [{defence,50},{hit_point_max,500}]};	
get(1404, 5)->
	{temp_suit_reward, 1404, 5, [{defence,50},{hit_point_max,500},{attack,50}]};	
get(1405, 2)->
	{temp_suit_reward, 1405, 2, [{defence,75}]};	
get(1405, 4)->
	{temp_suit_reward, 1405, 4, [{defence,75},{hit_point_max,750}]};	
get(1405, 5)->
	{temp_suit_reward, 1405, 5, [{defence,75},{hit_point_max,750},{attack,75}]};	
get(1406, 2)->
	{temp_suit_reward, 1406, 2, [{defence,100}]};	
get(1406, 4)->
	{temp_suit_reward, 1406, 4, [{defence,100},{hit_point_max,1000}]};	
get(1406, 5)->
	{temp_suit_reward, 1406, 5, [{defence,100},{hit_point_max,1000},{attack,100}]};	
get(1407, 2)->
	{temp_suit_reward, 1407, 2, [{defence,125}]};	
get(1407, 4)->
	{temp_suit_reward, 1407, 4, [{defence,125},{hit_point_max,1250}]};	
get(1407, 5)->
	{temp_suit_reward, 1407, 5, [{defence,125},{hit_point_max,1250},{attack,125}]};	
get(1408, 2)->
	{temp_suit_reward, 1408, 2, [{defence,150}]};	
get(1408, 4)->
	{temp_suit_reward, 1408, 4, [{defence,150},{hit_point_max,1500}]};	
get(1408, 5)->
	{temp_suit_reward, 1408, 5, [{defence,150},{hit_point_max,1500},{attack,150}]};	
get(1409, 2)->
	{temp_suit_reward, 1409, 2, [{defence,175}]};	
get(1409, 4)->
	{temp_suit_reward, 1409, 4, [{defence,175},{hit_point_max,1750}]};	
get(1409, 5)->
	{temp_suit_reward, 1409, 5, [{defence,175},{hit_point_max,1750},{attack,175}]};	
get(1410, 2)->
	{temp_suit_reward, 1410, 2, [{defence,200}]};	
get(1410, 4)->
	{temp_suit_reward, 1410, 4, [{defence,200},{hit_point_max,2000}]};	
get(1410, 5)->
	{temp_suit_reward, 1410, 5, [{defence,200},{hit_point_max,2000},{attack,2000}]};	
get(1603, 2)->
	{temp_suit_reward, 1603, 2, [{fdefence,25}]};	
get(1603, 4)->
	{temp_suit_reward, 1603, 4, [{fdefence,25},{mdefence,25}]};	
get(1603, 6)->
	{temp_suit_reward, 1603, 6, [{fdefence,25},{mdefence,25},{ddefence,25}]};	
get(1604, 2)->
	{temp_suit_reward, 1604, 2, [{fdefence,50}]};	
get(1604, 4)->
	{temp_suit_reward, 1604, 4, [{fdefence,50},{mdefence,50}]};	
get(1604, 6)->
	{temp_suit_reward, 1604, 6, [{fdefence,50},{mdefence,50},{ddefence,50}]};	
get(1605, 2)->
	{temp_suit_reward, 1605, 2, [{fdefence,75}]};	
get(1605, 4)->
	{temp_suit_reward, 1605, 4, [{fdefence,75},{mdefence,75}]};	
get(1605, 6)->
	{temp_suit_reward, 1605, 6, [{fdefence,75},{mdefence,75},{ddefence,75}]};	
get(1606, 2)->
	{temp_suit_reward, 1606, 2, [{fdefence,100}]};	
get(1606, 4)->
	{temp_suit_reward, 1606, 4, [{fdefence,100},{mdefence,100}]};	
get(1606, 6)->
	{temp_suit_reward, 1606, 6, [{fdefence,100},{mdefence,100},{ddefence,100}]};	
get(1607, 2)->
	{temp_suit_reward, 1607, 2, [{fdefence,125}]};	
get(1607, 4)->
	{temp_suit_reward, 1607, 4, [{fdefence,125},{mdefence,125}]};	
get(1607, 6)->
	{temp_suit_reward, 1607, 6, [{fdefence,125},{mdefence,125},{ddefence,125}]};	
get(1608, 2)->
	{temp_suit_reward, 1608, 2, [{fdefence,150}]};	
get(1608, 4)->
	{temp_suit_reward, 1608, 4, [{fdefence,150},{mdefence,150}]};	
get(1608, 6)->
	{temp_suit_reward, 1608, 6, [{fdefence,150},{mdefence,150},{ddefence,150}]};	
get(1609, 2)->
	{temp_suit_reward, 1609, 2, [{fdefence,175}]};	
get(1609, 4)->
	{temp_suit_reward, 1609, 4, [{fdefence,175},{mdefence,175}]};	
get(1609, 6)->
	{temp_suit_reward, 1609, 6, [{fdefence,175},{mdefence,175},{ddefence,175}]};	
get(1610, 2)->
	{temp_suit_reward, 1610, 2, [{fdefence,200}]};	
get(1610, 4)->
	{temp_suit_reward, 1610, 4, [{fdefence,200},{mdefence,200}]};	
get(1610, 6)->
	{temp_suit_reward, 1610, 6, [{fdefence,200},{mdefence,200},{ddefence,200}]};	
get(1703, 2)->
	{temp_suit_reward, 1703, 2, [{defence,25}]};	
get(1703, 4)->
	{temp_suit_reward, 1703, 4, [{defence,25},{hit_point_max,250}]};	
get(1703, 5)->
	{temp_suit_reward, 1703, 5, [{defence,25},{hit_point_max,250},{attack,25}]};	
get(1704, 2)->
	{temp_suit_reward, 1704, 2, [{defence,50}]};	
get(1704, 4)->
	{temp_suit_reward, 1704, 4, [{defence,50},{hit_point_max,500}]};	
get(1704, 5)->
	{temp_suit_reward, 1704, 5, [{defence,50},{hit_point_max,500},{attack,50}]};	
get(1705, 2)->
	{temp_suit_reward, 1705, 2, [{defence,75}]};	
get(1705, 4)->
	{temp_suit_reward, 1705, 4, [{defence,75},{hit_point_max,750}]};	
get(1705, 5)->
	{temp_suit_reward, 1705, 5, [{defence,75},{hit_point_max,750},{attack,75}]};	
get(1706, 2)->
	{temp_suit_reward, 1706, 2, [{defence,100}]};	
get(1706, 4)->
	{temp_suit_reward, 1706, 4, [{defence,100},{hit_point_max,1000}]};	
get(1706, 5)->
	{temp_suit_reward, 1706, 5, [{defence,100},{hit_point_max,1000},{attack,100}]};	
get(1707, 2)->
	{temp_suit_reward, 1707, 2, [{defence,125}]};	
get(1707, 4)->
	{temp_suit_reward, 1707, 4, [{defence,125},{hit_point_max,1250}]};	
get(1707, 5)->
	{temp_suit_reward, 1707, 5, [{defence,125},{hit_point_max,1250},{attack,125}]};	
get(1708, 2)->
	{temp_suit_reward, 1708, 2, [{defence,150}]};	
get(1708, 4)->
	{temp_suit_reward, 1708, 4, [{defence,150},{hit_point_max,1500}]};	
get(1708, 5)->
	{temp_suit_reward, 1708, 5, [{defence,150},{hit_point_max,1500},{attack,150}]};	
get(1709, 2)->
	{temp_suit_reward, 1709, 2, [{defence,175}]};	
get(1709, 4)->
	{temp_suit_reward, 1709, 4, [{defence,175},{hit_point_max,1750}]};	
get(1709, 5)->
	{temp_suit_reward, 1709, 5, [{defence,175},{hit_point_max,1750},{attack,175}]};	
get(1710, 2)->
	{temp_suit_reward, 1710, 2, [{defence,200}]};	
get(1710, 4)->
	{temp_suit_reward, 1710, 4, [{defence,200},{hit_point_max,2000}]};	
get(1710, 5)->
	{temp_suit_reward, 1710, 5, [{defence,200},{hit_point_max,2000},{attack,2000}]};	
get(_, _)->	
	[].	
