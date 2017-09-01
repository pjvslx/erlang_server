%%-----------------------------------
%% @Module  	: lib_misc
%% @Author  	: water
%% @Created 	: 2013.02.05
%% @Description: 你妹妹的杂项管理
%%-----------------------------------
-module(lib_misc).

-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-define(MIN_ACCOUNCE_IVL, 3).  %% 最小播送间隔（单位，秒）测试

load_announce() ->
	Nowtime = util:unixtime(),	
	lists:foreach(
	  fun(Item) ->
			  ItemRcd = list_to_tuple([?ETS_SYS_ANNONUCE] ++ Item) ,
			  if 
				  0 =:= ItemRcd#?ETS_SYS_ANNONUCE.end_time orelse Nowtime < ItemRcd#?ETS_SYS_ANNONUCE.end_time->
					  NewItemRcd = ItemRcd#?ETS_SYS_ANNONUCE{next_time = 0} ,
					  ets:insert(?ETS_SYS_ANNONUCE,NewItemRcd) ;
				  true ->
					  ok
			  end
	  end,db_agent:get_all_announce(Nowtime) ) . 
	

load_announce(AnnId) ->
	case db_agent:get_announce(AnnId) of
		[] ->
			skip ;
		DataList ->
			AnnRcd = list_to_tuple([?ETS_SYS_ANNONUCE] ++ DataList) ,
			Nowtime = util:unixtime(),
			if 
				AnnRcd#?ETS_SYS_ANNONUCE.times < 0 ->		%%发送次数小于0的删除(0为不限次数,不能删)
					ets:delete(?ETS_SYS_ANNONUCE,AnnId);
				AnnRcd#?ETS_SYS_ANNONUCE.interval =< 0 ->			%%发送间隔(分计), 小于等于0的删除
					spawn(fun() -> db_agent:update_announce(AnnRcd#?ETS_SYS_ANNONUCE.id, AnnRcd#?ETS_SYS_ANNONUCE.interval, 0, -1) end),%%写数据库让它停用
					ets:delete(?ETS_SYS_ANNONUCE,AnnId);
				AnnRcd#?ETS_SYS_ANNONUCE.end_time > 0 andalso AnnRcd#?ETS_SYS_ANNONUCE.end_time =< Nowtime ->	%%到期时间小于等于当前时间的删除
					ets:delete(?ETS_SYS_ANNONUCE,AnnId);
				true ->
					NewAnnRcd = AnnRcd#?ETS_SYS_ANNONUCE{next_time=0} ,
					ets:insert(?ETS_SYS_ANNONUCE,NewAnnRcd) 
			end
	end .


get_current_announce(AnnRcd,Nowtime) ->
	if
		is_record(AnnRcd,?ETS_SYS_ANNONUCE) ->
			NewAnnRcd = AnnRcd ;
		true ->
			NewAnnRcd = get_standby_announce(Nowtime)
	end ,
	NewAnnRcd .



update_annonuce(AnnRcd,NowTime) ->
	NewTimes =
		case AnnRcd#?ETS_SYS_ANNONUCE.times of
			1 -> -1;
			0 -> 0;
			Times -> Times - 1
		end,
	Interval = AnnRcd#?ETS_SYS_ANNONUCE.interval ,
	
	if 
		NewTimes < 0  orelse AnnRcd#?ETS_SYS_ANNONUCE.end_time > 0 andalso AnnRcd#?ETS_SYS_ANNONUCE.end_time =< NowTime->
			spawn(fun() -> db_agent:update_announce(AnnRcd#?ETS_SYS_ANNONUCE.id, AnnRcd#?ETS_SYS_ANNONUCE.interval, NowTime, -1) end),%%写数据库让它停用
			ets:delete(?ETS_SYS_ANNONUCE,AnnRcd#?ETS_SYS_ANNONUCE.id) ;
		true ->
			NewAnnRcd = AnnRcd#?ETS_SYS_ANNONUCE{
							   next_time = NowTime + Interval*60 ,
							   times = NewTimes 
							   } ,
			ets:insert(?ETS_SYS_ANNONUCE,NewAnnRcd) 
	end .

get_standby_announce(NowTime) ->
	MS = ets:fun2ms(fun(A)  when A#?ETS_SYS_ANNONUCE.begin_time =< NowTime 
									   andalso A#?ETS_SYS_ANNONUCE.end_time > NowTime 
													 andalso A#?ETS_SYS_ANNONUCE.times >= 0 -> A end) ,
	case ets:select(?ETS_SYS_ANNONUCE, MS) of
		[] ->
			NewAnnRcd = [] ;
		DataList ->
			[NewAnnRcd|_] = lists:keysort(#?ETS_SYS_ANNONUCE.next_time, DataList) 
	end ,
	NewAnnRcd .
	
%% 获取下一个需要播报的公告
 get_next_announce(NowTime) ->
	case get_standby_announce(NowTime) of
		AnnRcd when is_record(AnnRcd,?ETS_SYS_ANNONUCE) ->
			NextTime = AnnRcd#?ETS_SYS_ANNONUCE.next_time ,
			NextInteval = NextTime - NowTime ,
			case NextTime > 0  andalso NextInteval > 0 of
				true ->
					NewNextInteval = NextInteval ;
				false ->
					NewNextInteval = ?MIN_ACCOUNCE_IVL
			end ,
			{AnnRcd,NewNextInteval} ;
		_ ->
			{[],?MIN_ACCOUNCE_IVL*6}
	end .
		
	


test() ->
	#?ETS_SYS_ANNONUCE.begin_time .




