
%%%---------------------------------------
%%% @Module  : data_dungeon
%%% @Author  : csj
%%% @Created : 2010-11-03 21:25:12
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_dungeon).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-compile(export_all).

%% 重连有效时间，单位秒
get_recon_time() ->
	60 .

%% 主动传出副本的时间，单位秒
get_leave_time() ->
	10 .

%% 玩家可以进入副本的次数
get_dungeon_times() ->
	20 .
	
get_tmpl_dunid(DunId) ->
	case DunId > 999 of
		true ->
			DunId div 100 ;
		false ->
			DunId
	end .

%% 霸主邮件内容
get_master_content(DunName) ->
	1.
%% 	io_lib:format("恭喜您获得 ~s 副本霸主，收取邮件获得奖励！", [DunName]) .


%% 副本持续时间
get_duration(DunId) ->
	case tpl_dungeon:get(DunId) of
		TplDun when is_record(TplDun,temp_dungeon) ->
			TplDun#temp_dungeon.duration ;
		_ ->
			0
	end .

get_dungeon(DunId) ->
	case tpl_dungeon:get(get_tmpl_dunid(DunId)) of
		TplDun when is_record(TplDun,temp_dungeon) ->
			TplDun ;
		_ ->
			[]
	end .

get_trigger_tmpl(DunId,Trigger) ->
	tpl_dungeon_trigger:get(get_tmpl_dunid(DunId), Trigger) .

%% 验证是否是触发器类型的坐标
check_coordinate(true,_X,_Y,_CoordList) ->
	true ;
check_coordinate(false,_X,_Y,[]) ->
	false ;
check_coordinate(false,X,Y,[CurX,CurY|LeftXY]) ->
	NewFlag =  X =:= CurX andalso Y =:= CurY ,
	case length(LeftXY) =:= 1 of
		true ->
			check_coordinate(NewFlag,X,Y,[]) ;
		false ->
			check_coordinate(NewFlag,X,Y,LeftXY)
	end .

			
