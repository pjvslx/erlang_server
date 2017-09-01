%% @author Johnathe_Yip
%% @doc @todo Add description to data_meridian.
-include("meridian.hrl").

-module(data_meridian).

%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).

%%获取经脉最大类型
get_mer_max_type(?MER_TYPE_1)->
	7;
get_mer_max_type(?MER_TYPE_2)->
	7.

%%获取经脉句柄
get_mer_handle(?MER_TYPE_1)->
	mer_detail_1;
get_mer_handle(?MER_TYPE_2)->
	mer_detail_2.

