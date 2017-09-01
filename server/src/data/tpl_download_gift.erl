%%%------------------------------------------------	
%%% File    : tpl_download_gift.erl	
%%% Author  : table_to_erlang	
%%% Created : 
%%% Description:从数据库表temp_download_gift生成
%%% WARNING:程序生成，请不要增加手工代码！
%%%------------------------------------------------    	
 	
-module(tpl_download_gift). 	
-compile(export_all). 	
	
get(103)->
	{temp_download_gift, 103, 501024201};	
get(104)->
	{temp_download_gift, 104, 501014201};	
get(105)->
	{temp_download_gift, 105, 501034201};	
get(106)->
	{temp_download_gift, 106, 501044201};	
get(_)->	
	[].	
