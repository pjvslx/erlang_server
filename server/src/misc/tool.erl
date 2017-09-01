-module(tool).

-compile(export_all).



-define(IOFILE(Str, Args),(fun()->
								Command = io_lib:format(Str, Args),   
								file:write_file("../logs/data/proto_data.log", Command, [append])
								   end)()).
%%导出协议统计结果 
stat_proto_data()->
	List = ets:tab2list(proto_stat),
	NewList = lists:map(fun({Cmd,ProtoNum})->
								{ProtoNum,Cmd}
						end , List),
	lists:foreach(fun({ProtoNum,Cmd})->
						  ?IOFILE("协议->~p使用次数为->~p ~n",[Cmd,ProtoNum])
				  end
				  , lists:sort(NewList)).
%%打印函数调用测试结果
trace_profile_result()->
	eprof:stop_profiling(),
	eprof:analyze(total).


%% 分割列表的函数
split(N,SrcList) ->
	case length(SrcList) > N of
		true ->
			lists:split(N,SrcList) ;
		false ->
			{SrcList,[]}
	end.



%% @doc get IP address string from Socket
ip(Socket) ->
  	{ok, {IP, _Port}} = inet:peername(Socket),
  	{Ip0,Ip1,Ip2,Ip3} = IP,
	list_to_binary(integer_to_list(Ip0)++"."++integer_to_list(Ip1)++"."++integer_to_list(Ip2)++"."++integer_to_list(Ip3)).


%% @doc quick sort
sort([]) ->
	[];
sort([H|T]) -> 
	sort([X||X<-T,X<H]) ++ [H] ++ sort([X||X<-T,X>=H]).

%% for
for(Max,Max,F)->[F(Max)];
for(I,Max,F)->[F(I)|for(I+1,Max,F)].

%%---------------------------------------------------
%%给列表中元素加下标  by chenzm 
%%@spec for(n,m,fun()) -> [] 
%%---------------------------------------------------
add_index([]) ->
	[] ;
add_index(List) ->
	for(1,length(List),fun(I) ->
							   Elem = lists:nth(I,List),
							   if
								   is_tuple(Elem) ->
									   list_to_tuple([I] ++ tuple_to_list(Elem)) ;
								   true ->
									   {I,Elem} 
							   end 
		  				end).
add_index_to_record(List) ->
	case List of
		[] ->
			[] ;
		_ ->
			for(1,length(List),fun(I) ->
							   Elem = lists:nth(I,List),
							   {I,Elem}
		  				end)
	end.


%% @doc convert float to string,  f2s(1.5678) -> 1.57
f2s(N) when is_integer(N) ->
    integer_to_list(N) ++ ".00";
f2s(F) when is_float(F) ->
    [A] = io_lib:format("~.2f", [F]),
	A.


%% @doc convert other type to atom
to_atom(Msg) when is_atom(Msg) -> 
	Msg;  
to_atom(Msg) when is_binary(Msg) -> 
	tool:list_to_atom2(binary_to_list(Msg));
to_atom(Msg) when is_list(Msg) -> 
    tool:list_to_atom2(Msg);
to_atom(_) -> 
    throw(other_value).  %%list_to_atom("").

%% @doc convert other type to list
to_list(Msg) when is_list(Msg) -> 
    Msg;
to_list(Msg) when is_atom(Msg) -> 
    atom_to_list(Msg);
to_list(Msg) when is_binary(Msg) -> 
    binary_to_list(Msg);
to_list(Msg) when is_integer(Msg) -> 
    integer_to_list(Msg);
to_list(Msg) when is_float(Msg) -> 
    f2s(Msg);
to_list(_) ->
    throw(other_value).

%% @doc convert other type to binary
to_binary(Msg) when is_binary(Msg) -> 
    Msg;
to_binary(Msg) when is_atom(Msg) ->
	list_to_binary(atom_to_list(Msg));
	%%atom_to_binary(Msg, utf8);
to_binary(Msg) when is_list(Msg) -> 
	list_to_binary(Msg);
to_binary(Msg) when is_integer(Msg) -> 
	list_to_binary(integer_to_list(Msg));
to_binary(Msg) when is_float(Msg) -> 
	list_to_binary(f2s(Msg));
to_binary(_Msg) ->
    throw(other_value).

%% @doc convert other type to float
to_float(Msg)->
	Msg2 = to_list(Msg),
	list_to_float(Msg2).

%% @doc convert other type to integer
%% -spec to_integer(Msg :: any()) -> integer().       %%liujing 2012-8-9 cancel
to_integer(Msg) when is_integer(Msg) -> 
    Msg;
to_integer(Msg) when is_binary(Msg) ->
	Msg2 = binary_to_list(Msg),
    list_to_integer(Msg2);
to_integer(Msg) when is_list(Msg) -> 
    list_to_integer(Msg);
to_integer(Msg) when is_float(Msg) -> 
    round(Msg);
to_integer(_Msg) ->
    throw(other_value).

to_bool(D) when is_integer(D) ->
	D =/= 0;
to_bool(D) when is_list(D) ->
	length(D) =/= 0;
to_bool(D) when is_binary(D) ->
	to_bool(binary_to_list(D));
to_bool(D) when is_boolean(D) ->
	D;
to_bool(_D) ->
	throw(other_value).

%% @doc convert other type to tuple
to_tuple(T) when is_tuple(T) -> T;
to_tuple(T) -> {T}.

%% @doc get data type {0=integer,1=list,2=atom,3=binary}
get_type(DataValue,DataType)->
	case DataType of
		0 ->
			DataValue2 = binary_to_list(DataValue),
			list_to_integer(DataValue2);
		1 ->
			binary_to_list(DataValue);
		2 ->
			DataValue2 = binary_to_list(DataValue),
			list_to_atom(DataValue2);
		3 -> 
			DataValue
	end.

%% @spec is_string(List)-> yes|no|unicode  
is_string([]) -> yes;
is_string(List) -> is_string(List, non_unicode).

is_string([C|Rest], non_unicode) when C >= 0, C =< 255 -> is_string(Rest, non_unicode);
is_string([C|Rest], _) when C =< 65000 -> is_string(Rest, unicode);
is_string([], non_unicode) -> yes;
is_string([], unicode) -> unicode;
is_string(_, _) -> no.



%% @doc get random list
list_random(List)->
	case List of
		[] ->
			{};
		_ ->
			RS			=	lists:nth(random:uniform(length(List)), List),
			ListTail	= 	lists:delete(RS,List),
			{RS,ListTail}
	end.

%% @doc get a random integer between Min and Max
random(Min,Max)->
	Min2 = Min-1,
	random:uniform(Max-Min2)+Min2.

%% @doc 掷骰子
random_dice(Face,Times)->
	if
		Times == 1 ->
			random(1,Face);
		true ->
			lists:sum(for(1,Times, fun(_)-> random(1,Face) end))
	end.

%% @doc 机率
odds(Numerator, Denominator)->
	Odds = random:uniform(Denominator),
	if
		Odds =< Numerator -> 
			true;
		true ->
			false
	end.

odds_list(List)->
	Sum = odds_list_sum(List),
	odds_list(List,Sum).
odds_list([{Id,Odds}|List],Sum)->
	case odds(Odds,Sum) of
		true ->
			Id;
		false ->
			odds_list(List,Sum-Odds)
	end.
odds_list_sum(List)->
	{_List1,List2} = lists:unzip(List),
	lists:sum(List2).


%% @doc 取整 大于X的最小整数
ceil(X) ->
    T = trunc(X),
	if 
		X - T == 0 ->
			T;
		true ->
			if
				X > 0 ->
					T + 1;
				true ->
					T
			end			
	end.


%% @doc 取整 小于X的最大整数
floor(X) ->
    T = trunc(X),
	if 
		X - T == 0 ->
			T;
		true ->
			if
				X > 0 ->
					T;
				true ->
					T-1
			end
	end.
%% 4舍5入
%% round(X)

%% subatom
subatom(Atom,Len)->	
	list_to_atom(lists:sublist(atom_to_list(Atom),Len)).

%% @doc 暂停多少毫秒
sleep(Msec) ->
	receive
		after Msec ->
			true
	end.

md5(S) ->        
	Md5_bin =  erlang:md5(S), 
    Md5_list = binary_to_list(Md5_bin), 
    lists:flatten(list_to_hex(Md5_list)). 
 
list_to_hex(L) -> 
	lists:map(fun(X) -> int_to_hex(X) end, L). 
 
int_to_hex(N) when N < 256 -> 
    [hex(N div 16), hex(N rem 16)]. 
hex(N) when N < 10 -> 
       $0+N; 
hex(N) when N >= 10, N < 16 ->      
	$a + (N-10).

list_to_atom2(List) when is_list(List) ->
	case catch(list_to_existing_atom(List)) of
		{'EXIT', _} -> erlang:list_to_atom(List);
		Atom when is_atom(Atom) -> Atom
	end.
	
combine_lists(L1, L2) ->
	Rtn = 
	lists:foldl(
		fun(T, Acc) ->
			case lists:member(T, Acc) of
				true ->
					Acc;
				false ->
					[T|Acc]
			end
		end, lists:reverse(L1), L2),
	lists:reverse(Rtn).


get_process_info_and_zero_value(InfoName) ->
	PList = erlang:processes(),
	ZList = lists:filter( 
		fun(T) -> 
			case erlang:process_info(T, InfoName) of 
				{InfoName, 0} -> false; 
				_ -> true 	
			end
		end, PList ),
	ZZList = lists:map( 
		fun(T) -> {T, erlang:process_info(T, InfoName), erlang:process_info(T, registered_name)} 
		end, ZList ),
	[ length(PList), InfoName, length(ZZList), ZZList ].

get_process_info_and_large_than_value(InfoName, Value) ->
	PList = erlang:processes(),
	ZList = lists:filter( 
		fun(T) -> 
			case erlang:process_info(T, InfoName) of 
				{InfoName, VV} -> 
					if VV >  Value -> true;
						true -> false
					end;
				_ -> true 	
			end
		end, PList ),
	ZZList = lists:map( 
		fun(T) -> {T, erlang:process_info(T, InfoName), erlang:process_info(T, registered_name)} 
		end, ZList ),
	[ length(PList), InfoName, Value, length(ZZList), ZZList ].

get_msg_queue() ->
	io:fwrite("process count:~p~n~p value is not 0 count:~p~nLists:~p~n", 
				get_process_info_and_zero_value(message_queue_len) ).

get_memory() ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
				get_process_info_and_large_than_value(memory, 1048576) ).

get_memory(Value) ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
				get_process_info_and_large_than_value(memory, Value) ).

get_heap() ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
				get_process_info_and_large_than_value(heap_size, 1048576) ).

get_heap(Value) ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
				get_process_info_and_large_than_value(heap_size, Value) ).

get_processes() ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
	get_process_info_and_large_than_value(memory, 0) ).


list_to_term(String) ->
	{ok, T, _} = erl_scan:string(String++"."),
	case erl_parse:parse_term(T) of
		{ok, Term} ->
			Term;
		{error, Error} ->
			Error
	end.


substr_utf8(Utf8EncodedString, Length) ->
	substr_utf8(Utf8EncodedString, 1, Length).
substr_utf8(Utf8EncodedString, Start, Length) ->
	ByteLength = 2*Length,
	Ucs = xmerl_ucs:from_utf8(Utf8EncodedString),
	Utf16Bytes = xmerl_ucs:to_utf16be(Ucs),
	SubStringUtf16 = lists:sublist(Utf16Bytes, Start, ByteLength),
	Ucs1 = xmerl_ucs:from_utf16be(SubStringUtf16),
	xmerl_ucs:to_utf8(Ucs1).

ip_str(IP) ->
	case IP of
		{A, B, C, D} ->
			lists:concat([A, ".", B, ".", C, ".", D]);
		{A, B, C, D, E, F, G, H} ->
			lists:concat([A, ":", B, ":", C, ":", D, ":", E, ":", F, ":", G, ":", H]);
		Str when is_list(Str) ->
			Str;
		_ ->
			[]
	end.

%%对正负进行调整：负数变为0，正数保持不变
int_format(Num) ->
	if Num >= 0 ->
		   Num;
	   true ->
		   0
	end.

%%去掉字符串空格
remove_string_black(L) ->
	F = fun(S) ->
				if S == 32 -> [];
				   true -> S
				end
		end,
	Result = [F(lists:nth(I,L)) || I <- lists:seq(1,length(L))],
	lists:filter(fun(T) -> T =/= [] end,Result).
	

%%获取协议操作的时间戳，true->允许；false -> 直接丢弃该条数据
%%spec is_operate_ok/1 param: Type -> 添加的协议类型(atom); return: true->允许；false -> 直接丢弃该条数据
is_operate_ok(Type, TimeStamp) ->
	NowTime = util:longunixtime(),
	case get(Type) of
		undefined ->
			put(Type, NowTime),
    		true;
		Value ->
			case (NowTime - Value) >= TimeStamp of
				true ->
					put(Type, NowTime),
					true;
				false ->
					false
			end
	end.

%%打包字符串数据
pack_string(Str) ->
	StrBin = tool:to_binary(Str),
	Len = byte_size(StrBin),
	{Len, StrBin}.

%%对[{GetName, Rate},..]结构类型的单项随机获取的通用处理,空列表返回undefined
get_rand_single(RateList) ->
	Fun = fun({_Tmp, R}, RNum) ->
				  RNum + R
		  end,
	AllR = lists:foldl(Fun, 0, RateList),
	GetRNum = util:rand(1, AllR),
	Fun1 = fun({Atom, Rat}, [BGet, Ra, FirstNum, GetAtom1]) ->
				   EndNum = FirstNum + Rat,
				   if BGet =:= 0 andalso Ra =< EndNum ->
						  [1, Ra, EndNum, Atom];
					  true ->
						  [BGet, Ra, EndNum, GetAtom1]
				   end
		   end,
	[_NewBGet, _NewRa, _FirstNum, GetAtom] = lists:foldl(Fun1, [0, GetRNum, 0, undefined], RateList),
	GetAtom.

%%对[{GetName, Rate, MinNum, MaxNum},..]结构类型的单项随机获取的通用处理,空列表返回undefined
get_rand_single2(RateList) ->
	Fun = fun({_Tmp, R, _Mn, _Mx}, RNum) ->
				  RNum + R
		  end,
	AllR = lists:foldl(Fun, 0, RateList),
	GetRNum = util:rand(1, AllR),
	Fun1 = fun({Atom, Rat, MinNum, MaxNum}, [BGet, Ra, FirstNum, GetAtom1]) ->
				   EndNum = FirstNum + Rat,
				   if BGet =:= 0 andalso Ra =< EndNum ->
						  [1, Ra, EndNum, {Atom, MinNum, MaxNum}];
					  true ->
						  [BGet, Ra, EndNum, GetAtom1]
				   end
		   end,
	[_NewBGet, _NewRa, _FirstNum, GetAtom] = lists:foldl(Fun1, [0, GetRNum, 0, undefined], RateList),
	GetAtom.


%%对单个玩家数据回档的操作函数======2012-9-17 from liujing======

%%获取需要处理的表名(返回字符串结构的表名)
get_handle_table_name() ->
	TableList = lib_player_rw:get_all_tables(),
	F = fun(TableName, GetList) ->
				TableName1 = util:term_to_string(TableName),
				case TableName1 =/= "cards"  andalso TableName1 =/= "sys_acm"  andalso string:str(TableName1,"admin") =/= 1 
					andalso TableName1 =/= "auto_ids" andalso TableName1 =/= "shop" andalso string:str(TableName1,"base") =/= 1 
					andalso TableName1 =/= "slaves" andalso TableName1 =/= "battle_cache_data" andalso string:str(TableName1,"arena") =/= 1 
					andalso string:str(TableName1,"log_") =/= 1 andalso string:str(TableName1,"th") =/= 1 
					andalso TableName1 =/= "rela"  of
					false -> GetList;
					true ->
						GetList ++ [util:string_to_term(tool:to_list(TableName1))]
				end
		end,
	lists:foldl(F, [], TableList).

ini_faraway_mongo_db(PoolId, Num) ->
	Host = 
		case Num of
			1 ->
				"113.105.250.125" ;
			2 ->
				"113.105.251.123" ;
			4 ->
				"183.61.130.69" ;
			_ ->
				%%连接内部192.168.51.174服务器
				"192.168.51.174"
		end,
%% 	Host = io:get_line("remote database ip:") ,
	Port = 27017,
	case Num of
		0 ->
			DB = "csj_dev_S1";
		_ ->
			DB = lists:concat(["csj_dev_S",Num])
	end,
	io:format("====dest db:~p~n",[[Host,DB]]) ,
	
	EmongoSize = 1,
	emongo_sup:start_link(),
	emongo_app:initialize_pools([PoolId, Host, Port, DB, EmongoSize]).

ini_local_mongo_db(PoolId, Num) ->
 	Host = "192.168.51.174",
%%  	Host = io:get_line("sorce database ip:") ,
	Port = 27017,
	case Num of
		0 ->
			DB = "csj_dev_src_S1";
		_ ->
			DB = lists:concat(["csj_dev_src_S",Num])
	end,
	io:format("====src db:~p~n",[DB]) ,
	EmongoSize = 1,
	emongo_sup:start_link(),
	emongo_app:initialize_pools([PoolId, Host, Port, DB, EmongoSize]).

get_mongo_to_mysql(UidList, ServerNum) ->
%% 	CONFIG_FILE = "../config/gateway.config",
	FarPoolId = lists:concat(["master_mongo_tmp", ServerNum]),
	LocalPoolId = "master_mongo_l",
	TableList = get_handle_table_name(),
	ini_faraway_mongo_db(FarPoolId, ServerNum),
	ini_local_mongo_db(LocalPoolId, ServerNum),
	Fun1 = fun(TableName, GetUid) ->
				   case TableName of
					   player ->
						   io:format("========_1_~n"),
						   [WhereOpertion,FieldOpertion] = db_mongoutil:make_select_opertion(db_mongo:transfer_fields(TableName, "*"), [{id, GetUid}], [], []),
						   L = emongo:find_all(LocalPoolId,tool:to_list(TableName),WhereOpertion,FieldOpertion),
						   io:format("========_1_~p~n",[L]),
						   RList = db_mongo:handle_all_result(TableName,db_mongo:transfer_fields(TableName,"*"), L),
						   [DelOpertion] = db_mongoutil:make_delete_opertion([{id, GetUid}]),
						   emongo:delete(FarPoolId, tool:to_list(TableName), DelOpertion),
						   case RList of
							   [] ->
								   GetUid;
							   _ ->
								   FieldList = db_mongo:get_all_fields(TableName),
								   Fun2 = fun(RL) ->
												  FullKeyValuelist = db_mongo:fullKeyValue(TableName,lists:zip(FieldList,RL)),
												  FullKeyValuelist1 = checkF(FullKeyValuelist),
												  Opertion = db_mongoutil:make_insert_opertion(FullKeyValuelist1),
  												  emongo:insert(FarPoolId,tool:to_list(TableName),Opertion)
										  end,
								   lists:foreach(Fun2, RList),
								   GetUid
						   end;
					   _ ->
						   io:format("========_3_[~p]~n", [TableName]),
						   FieldList = db_mongo:get_all_fields(TableName),
						   case FieldList of
							   undefined ->
								   GetUid;
							   [] ->
								   GetUid;
							   _ ->
								   [WhereOpertion,FieldOpertion] = db_mongoutil:make_select_opertion(db_mongo:transfer_fields(TableName, "*"), [{uid, GetUid}], [], []),
								   L = emongo:find_all(LocalPoolId,tool:to_list(TableName),WhereOpertion,FieldOpertion),
								  
								   RList = db_mongo:handle_all_result(TableName,db_mongo:transfer_fields(TableName,"*"), L),
								   [DelOpertion] = db_mongoutil:make_delete_opertion([{uid, GetUid}]),
								   emongo:delete(FarPoolId, tool:to_list(TableName), DelOpertion),
								   case RList of
									   [] ->
										   GetUid;
									   _ ->
										   Fun2 = fun(RL) ->
														  FullKeyValuelist = db_mongo:fullKeyValue(TableName,lists:zip(FieldList,RL)),
														  FullKeyValuelist1 = checkF(FullKeyValuelist),
														  Opertion = db_mongoutil:make_insert_opertion(FullKeyValuelist1),
														  emongo:insert(FarPoolId,tool:to_list(TableName),Opertion)
												  end,
										   lists:foreach(Fun2, RList),
										   GetUid
								   end
						   end
				   end
		   end,
	Fun = fun(Uid) ->
				  lists:foldl(Fun1, Uid, TableList)
		  end,
	lists:foreach(Fun, UidList).

checkF(KeyVList) ->
	Fun= fun({Key, Val}) ->
				 case Val of
					 [] ->
						 {Key, <<"[]">>};
					 undefined ->
						 {Key, <<"[]">>};
					 _ ->
						 {Key, Val}
				 end
		 end,
	
	lists:map(Fun, KeyVList).

%%打印结构体,哥只能做到这样的
%%dynamic_compile死活编译不过
recinfo(FieldList,  Rec) ->
     RecordName = lists:nth(1, tuple_to_list(Rec)),
     ValueList = lists:nthtail(1, tuple_to_list(Rec)),
     Length = min(length(FieldList), length(ValueList)),
     OutStr = "#" ++ tool:to_list(RecordName) ++ "{\r\n",
     OutStr1 = lists:foldl(fun(Idx, Str) ->    
                              Str ++ io_lib:format("    ~p = ~p,~n", [lists:nth(Idx, FieldList), lists:nth(Idx, ValueList)])
                          end,  OutStr, lists:seq(1, Length-1)),
     OutStr1 ++ io_lib:format("    ~p = ~p}~n", [lists:nth(Length, FieldList), lists:nth(Length, ValueList)]).

gcd(A,0)->
        A;
gcd(A,B) when A>=B ->
        gcd(A rem B, B);
gcd(A,B)->
        gcd(B, A).
%%求最小公约数
hcd([H|T])->
        gcd(H, hcd(T));
hcd([])->
        0.

