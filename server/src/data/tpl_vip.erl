%%%------------------------------------------------	
%%% File    : tpl_vip.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_vip生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_vip). 	
-compile(export_all). 	
	
get(1)->
	{temp_vip, 1, <<"体验VIP">>, 30, 0, 0, <<"30分钟就没了">>, 30, 514004203, 236, 15, 0, <<"0">>, <<"充值多多，优惠多多！">>};	
get(2)->
	{temp_vip, 2, <<"一天VIP">>, 495014202, 0, 305, <<"享受1天的便利">>, 1440, 514004203, 237, 15, 0, <<"0">>, <<"充值多多，优惠多多！！">>};	
get(3)->
	{temp_vip, 3, <<"周VIP">>, 495014203, 98, 305, <<"<Element><color R = 0 G = 255 B = 255></color><text>1、每天免费传送15次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>2、智力答题，每天免费使用道具2次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>3、打怪额外获得经验加成10%</text><linefeed>1</linefeed></Element>">>, 10080, 514004203, 238, 15, 6, <<"0">>, <<"充值多多，优惠多多！！！">>};	
get(4)->
	{temp_vip, 4, <<"月VIP">>, 495014204, 288, 305, <<"<Element><color R = 0 G = 255 B = 255></color><text>1、每天免费传送50次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>2、智力答题，每天免费使用道具2次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>3、打怪额外获得经验加成10%</text><linefeed>1</linefeed></Element>">>, 43200, 514004204, 239, 50, 36, <<"0">>, <<"充值多多，优惠多多！！！！">>};	
get(5)->
	{temp_vip, 5, <<"年VIP">>, 495014205, 1288, 305, <<"<Element><color R = 0 G = 255 B = 255></color><text>1、每天免费传送无限次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>2、智力答题，每天免费使用道具2次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>3、打怪额外获得经验加成10%</text><linefeed>1</linefeed></Element>">>, 525600, 514004205, 240, 9999, 144, <<"997_366">>, <<"充值多多，优惠多多！！！！！">>};	
get(6)->
	{temp_vip, 6, <<"至尊VIP">>, 200000, 200000, 305, <<"<Element><color R = 0 G = 255 B = 255></color><text>1、每天免费传送无限次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>2、智力答题，每天免费使用道具5次</text><linefeed>1</linefeed></Element><Element><color R = 0 G = 255 B = 0></color><text>3、打怪额外获得经验加成10%</text><linefeed>1</linefeed></Element>">>, 0, 514004206, 241, 9999, 0, <<"997_365">>, <<"充值多多，优惠多多！！！！！！">>};	
get(_)->	
	[].	
