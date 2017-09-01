%%%--------------------------------------
%%% @Module  : db_esql
%%% @Author  : Skyman Wu
%%% @Email   : 
%%% @Created : 2011.11.10
%%% @Description: MYSQL数据库操作 
%%%--------------------------------------
-module(db_esql).
-export(
    [
        execute/2,
        execute/3,
        select_limit/4,
        select_limit/5,
		update_get_id/2,
        execute_sql/1,
        get_one/2,
        get_one/3,
        get_row/1,
        get_row/2,
        get_row/3,
        get_all/1,
        get_all/2,
        get_all/3,
		tx/1,
		make_insert_sql/2,
        make_insert_sql/3,
		make_delete_sql/2,
		make_replace_sql/2,
        make_update_sql/3,
		make_update_sql/5,
		make_select_sql/3,
		make_select_sql/5,
		get_order_sql/1,
		get_where_sql/1,
		print_result/0
    ]
).
-include("common.hrl").


%% 执行一个SQL查询,返回影响的行数
execute(PoolId, Sql) ->
	case mysql:fetch(PoolId, Sql) of
        {updated, {_, _, _, R, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

execute(PoolId, Sql, Args) when is_atom(Sql) ->
    case mysql:execute(PoolId, Sql, Args) of
        {updated, {_, _, _, R, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end;
execute(PoolId, Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(PoolId, s, Args) of
        {updated, {_, _, _, R, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.


%% 执行分页查询返回结果中的所有行
select_limit(PoolId, Sql, Offset, Num) ->
     S = list_to_binary([Sql, <<" limit ">>, integer_to_list(Offset), <<", ">>, integer_to_list(Num)]),
    case mysql:fetch(PoolId, S) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.
select_limit(PoolId, Sql, Args, Offset, Num) ->
    S = list_to_binary([Sql, <<" limit ">>, list_to_binary(integer_to_list(Offset)), <<", ">>, list_to_binary(integer_to_list(Num))]),
    mysql:prepare(s, S),
    case mysql:execute(PoolId, s, Args) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%% 更新（insert或replace）后取得id
update_get_id(PoolId, Sql) ->
	case mysql:fetch(PoolId, Sql) of
		{updated, {_, _, _, _, Id, _, _, _}} -> Id;
        {error, Info} -> mysql_halt(Sql, Info)
    end.
	
%% 取出查询结果中的第一行第一列
%% 未找到时返回[]
get_one(PoolId, Sql) ->
	case mysql:fetch(PoolId, Sql) of
        {data, {_, _, [], _, _, _, _, _}} ->
            [];
        {data, {_, _, [[R]], _, _, _, _, _}} ->
            R;
        {error, Info} -> 
            mysql_halt(Sql, Info)
    end.
get_one(PoolId, Sql, Args) when is_atom(Sql) ->
	case mysql:execute(PoolId, Sql, Args) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [[R]], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end;
get_one(PoolId, Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(PoolId, s, Args) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [[R]], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%%执行一句SQL
execute_sql(Sql) ->
    case mysql:fetch(?DB_SERVER, Sql) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [R], _, _, _, _, _}} -> R;
        {updated, {_, _, _, R, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%% 取出查询结果中的第一行
get_row(Sql) ->
    case mysql:fetch(?DB_SERVER, Sql) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [R], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.  
get_row(PoolId, Sql) ->
    case mysql:fetch(PoolId, Sql) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [R], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.
get_row(PoolId, Sql, Args) when is_atom(Sql) ->
    case mysql:execute(PoolId, Sql, Args) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [R], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end;
get_row(PoolId, Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(PoolId, s, Args) of
        {data, {_, _, [], _, _, _, _, _}} -> [];
        {data, {_, _, [R], _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%% 取出查询结果中的所有行
get_all(Sql) ->
    case mysql:fetch(?DB_SERVER, Sql) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%% 取出查询结果中的所有行
get_all(PoolId, Sql) ->
    case mysql:fetch(PoolId, Sql) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.
get_all(PoolId, Sql, Args) when is_atom(Sql) ->
    case mysql:execute(PoolId, Sql, Args) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end;
get_all(PoolId, Sql, Args) ->
    mysql:prepare(s, Sql),
    case mysql:execute(PoolId, s, Args) of
        {data, {_, _, R, _, _, _, _, _}} -> R;
        {error, Info} -> mysql_halt(Sql, Info)
    end.

%% 事务（对外接口）
%% @return {ok, Result} | {error, Reason}
tx(Fun) ->
	Ret = Fun(),
	{ok, Ret}.
    %%case transaction(Fun) of
    %%    {atomic, Result} ->
    %%        {ok, Result};
    %%    {aborted, {Reason, {rollback_result, Result}}} ->
	%%		?TRACE("*** db transaction error: ~p, rollback result: ~p~n", [Reason, Result]),
    %%        {error, Reason}
    %%end.

%% 事务处理
%% transaction(Fun) ->
%% 	Result = mysql:execute(?DB, <<"BEGIN">>),
%%     if 
%% 		is_record(Result, error_packet) ->
%%  	    	{aborted, Result};
%%  		true ->
%% 	    	case catch Fun() of
%% 				error = Err -> rollback(Err);
%% 				{error, _} = Err -> rollback(Err);
%% 				{'EXIT', _} = Err -> rollback(Err);
%% 				Res ->
%% 					Result1 = mysql:execute(?DB, <<"COMMIT">>),
%% 		    		if 
%% 						is_record(Result1, error_packet) ->
%% 			    			rollback({commit_error, Result1});
%% 						true ->
%% 			    				case Res of
%% 									{atomic, _} -> Res;
%% 									_ -> {atomic, Res}
%% 			    				end
%% 		    		end
%% 	    	end
%%     end.

%% rollback(Err) ->
%%     Result = mysql:execute(?DB, <<"ROLLBACK">>),
%%     {aborted, {Err, {rollback_result, Result}}}.

%% @doc 显示人可以看得懂的错误信息
mysql_halt(Sql, {_, _, _, _, _, Reason, ErrCode, ErrSqlState}) ->
%% 	io:format("[db_error] Sql: ~s, ErrCode:~p, ErrState:~s, Reason:~s~n", [Sql, ErrCode, ErrSqlState, Reason]),
	?ERROR_MSG("[db_error] Sql: ~s, ErrCode:~p, ErrState:~s, Reason:~s", [Sql, ErrCode, ErrSqlState, Reason]),
    erlang:error({db_error, [Sql, ErrCode, ErrSqlState, Reason]}).

%%组合mysql insert语句
%% 使用方式db_sql:make_insert_sql(test,["row","r"],["测试",123]) 相当 insert into `test` (row,r) values('测试','123')
%%Table:表名
%%Field：字段
%%Data:数据
make_insert_sql(Table_name, FieldList, ValueList) ->
    L = make_conn_sql(FieldList, ValueList, []),
    lists:concat(["insert into `", Table_name, "` set ", L]).
    
%%组合mysql update语句
%% 使用方式db_sql:make_update_sql(test,["row","r"],["测试",123],"id",1) 相当 update `test` set row='测试', r = '123' where id = '1'
%%Table:表名
%%Field：字段
%%Data:数据
%%Key:键
%%Data:值
make_update_sql(Table_name, Field, Data, Key, Value) ->
    L = make_conn_sql(Field, Data, []),
	lists:concat(["update `", Table_name, "` set ",L," where ",Key,"= '",tool:to_list(Value),"'"]).
    
make_conn_sql([], _, L ) ->
    L ;
make_conn_sql(_, [], L ) ->
    L ;
make_conn_sql([F | T1], [D | T2], []) ->
    L  = ["`", tool:to_list(F), "`='",get_sql_val(D),"'"],
    make_conn_sql(T1, T2, L);
make_conn_sql([F | T1], [D | T2], L) ->
    L1  = L ++ [",`", tool:to_list(F),"`='",get_sql_val(D),"'"],
    make_conn_sql(T1, T2, L1).

get_sql_val(Val) ->
	case is_binary(Val) orelse is_list(Val) of 
		true -> re:replace(tool:to_list(Val),"'","''",[global,{return,list}]);
		_-> tool:to_list(Val)
	end.

make_insert_sql(Table_name, Field_Value_List) ->
	%mysql_stat(Table_name,insert),
%%  db_sql:make_insert_sql(player, 
%%                         [{status, 0}, {online_flag,1}, {hp,50}, {mp,30}]).
 	{Vsql, _Count1} =
		lists:mapfoldl(
	  		fun(Field_value, Sum) ->	
				Expr = case Field_value of
						 {Field, Val} -> 
							 case is_binary(Val) orelse is_list(Val) of 
								 true -> io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
							 	 _-> io_lib:format("`~s`='~p'",[Field, Val])
							 end
					end,
				S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s ",[Expr]);
						true -> io_lib:format("~s,",[Expr])
					 end,
 				{S1, Sum+1}
			end,
			1, Field_Value_List),
	lists:concat(["insert into `", Table_name, "` set ",
	 			  lists:flatten(Vsql)
				 ]).

make_replace_sql(Table_name, Field_Value_List) ->
	%	mysql_stat(Table_name,replace),
%%  db_sql:make_replace_sql(player, 
%%                         [{status, 0}, {online_flag,1}, {hp,50}, {mp,30}]).
 	{Vsql, _Count1} =
		lists:mapfoldl(
	  		fun(Field_value, Sum) ->	
				Expr = case Field_value of
						 {Field, Val} -> 
							 case is_binary(Val) orelse is_list(Val) of 
								 true -> io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
							 	 _-> io_lib:format("`~s`=~p",[Field, Val])
							 end
					end,
				S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s ",[Expr]);
						true -> io_lib:format("~s,",[Expr])
					 end,
 				{S1, Sum+1}
			end,
			1, Field_Value_List),
	lists:concat(["replace into `", Table_name, "` set ",
	 			  lists:flatten(Vsql)
				 ]).

make_update_sql(Table_name, Field_Value_List, Where_List) ->
	%	mysql_stat(Table_name,update),
%%  db_sql:make_update_sql(player, 
%%                         [{status, 0}, {online_flag,1}, {hp,50, add}, {mp,30,sub}],
%%                         [{id, 11}]).
 	{Vsql, _Count1} =
		lists:mapfoldl(
	  		fun(Field_value, Sum) ->	
				Expr = case Field_value of
						 {Field, Val, add} -> io_lib:format("`~s`=`~s`+~p", [Field, Field, Val]);
						 {Field, Val, sub} -> io_lib:format("`~s`=`~s`-~p", [Field, Field, Val]);						 
						 {Field, Val} -> 
							 case is_binary(Val) orelse is_list(Val) of 
								 true -> io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
							 	 _-> io_lib:format("`~s`='~p'",[Field, Val])
							 end
					end,
				S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s ",[Expr]);
						true -> io_lib:format("~s,",[Expr])
					 end,
 				{S1, Sum+1}
			end,
			1, Field_Value_List),
	{Wsql, Count2} = get_where_sql(Where_List),
	WhereSql = 
		if Count2 > 1 -> lists:concat(["where ", lists:flatten(Wsql)]);
	   			 true -> ""
		end,
	lists:concat(["update `", Table_name, "` set ",
	 			  lists:flatten(Vsql), WhereSql, ""
				 ]).

make_delete_sql(Table_name, Where_List) ->
		%mysql_stat(Table_name,delete),
%% db_sql:make_delete_sql(player, [{id, "=", 11, "and"},{status, 0}]).
	{Wsql, Count2} = get_where_sql(Where_List),
	WhereSql = 
		if Count2 > 1 -> lists:concat(["where ", lists:flatten(Wsql)]);
	   			 true -> ""
		end,
	lists:concat(["delete from `", Table_name, "` ", WhereSql, ""]).

make_select_sql(Table_name, Fields_sql, Where_List) ->
	make_select_sql(Table_name, Fields_sql, Where_List, [], []).

make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
	%	mysql_stat(Table_name,select),
%%  db_sql:make_select_sql(player, "*", [{status, 1}], [{id,desc},{status}],[]).
%%  db_sql:make_select_sql(player, "id, status", [{id, 11}], [{id,desc},{status}],[]).
	{Wsql, Count1} = get_where_sql(Where_List),
	WhereSql = 
		if Count1 > 1 -> lists:concat(["where ", lists:flatten(Wsql)]);
	   			 true -> ""
		end,
	{Osql, Count2} = get_order_sql(Order_List),
	OrderSql = 
		if Count2 > 1 -> lists:concat(["order by ", lists:flatten(Osql)]);
	   			 true -> ""
		end,
	LimitSql = case Limit_num of
				   [] -> "";
				   [Num] -> lists:concat(["limit ", Num])
			   end,
	lists:concat(["select ", Fields_sql," from `", Table_name, "` ", WhereSql, OrderSql, LimitSql]).

get_order_sql(Order_List) ->
%%  排序用列表方式：[{id, desc},{status}]
	lists:mapfoldl(
  		fun(Field_Order, Sum) ->	
			Expr = 
				case Field_Order of   
					{Field, Order} ->
							io_lib:format("~p ~p",[Field, Order]);
					{Field} ->
							io_lib:format("~p",[Field]);
					 _-> ""
				   end,
			S1 = if Sum == length(Order_List) -> io_lib:format("~s ",[Expr]);
					true ->	io_lib:format("~s,",[Expr])
				 end,
			{S1, Sum+1}
		end,
		1, Order_List).

get_where_sql(Where_List) ->
%%  条件用列表方式：[{},{},{}]
%%  每一个条件形式(一共三种)：
%%		1、{idA, "<>", 10, "or"}   	<===> {字段名, 操作符, 值，下一个条件的连接符}
%% 	    2、{idB, ">", 20}   			<===> {idB, ">", 20，"and"}
%% 	    3、{idB, 20}   				<===> {idB, "=", 20，"and"}		
	lists:mapfoldl(
  		fun(Field_Operator_Val, Sum) ->	
			[Expr, Or_And_1] = 
				case Field_Operator_Val of   
					{Field, Operator, Val, Or_And} ->
						case is_binary(Val) orelse is_list(Val) of 
						 	true -> [io_lib:format("`~s`~s'~s'",[Field, Operator, re:replace(Val,"'","''",[global,{return,binary}])]), Or_And];
							_-> [io_lib:format("`~s`~s'~p'",[Field, Operator, Val]), Or_And]
						end;
					{Field, Operator, Val} ->
						case is_binary(Val) orelse is_list(Val) of 
						 	true -> [io_lib:format("`~s`~s'~s'",[Field, Operator, re:replace(Val,"'","''",[global,{return,binary}])]), "and"];
							_-> [io_lib:format("`~s`~s'~p'",[Field, Operator, Val]),"and"]
						end;
					{Field, Val} ->  
						case is_binary(Val) orelse is_list(Val) of 
						 	true -> [io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]), "and"];
							_-> [io_lib:format("`~s`='~p'",[Field, Val]), "and"]
						end;
					 _-> ""
				   end,
			S1 = if Sum == length(Where_List) -> io_lib:format("~s ",[Expr]);
					true ->	io_lib:format("~s ~s ",[Expr, Or_And_1])
				 end,
			{S1, Sum+1}
		end,
		1, Where_List).
%%mysql数据库操作统计
mysql_stat(TableName,Opt)->
	Key = lists:concat([TableName,"_",Opt]),
	case ets:lookup(mysql_stat, Key) of
		[]->
			ets:insert(mysql_stat, {Key,1});
		[{_,Num}] ->
			ets:insert(mysql_stat, {Key,Num+1})
	end.
%%打印mysql数据库操作统计	结果	
print_result()->
	List = ets:tab2list(mysql_stat),
	NewList = lists:map(fun({Table,Num})->
					  {Num,Table}
			  end, List), 
	io:format("mysql state ~p ~n",[lists:sort(NewList)]).