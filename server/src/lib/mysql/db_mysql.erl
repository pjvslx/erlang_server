%%%--------------------------------------
%%% @Module  : db
%%% @Author  : 
%%% @Created : 2012.5.29
%%% @Description: mysql 数据库操作  
%%%--------------------------------------
-module(db_mysql).
-include("common.hrl").
-include("record.hrl").
-export(
    [	insert_get_id/3,
	 	insert/3,
		insert/2,
		replace/2,
		replace_get_id/2,
		update/5,
		update/3,  
		update/2,
		select_one/5,  
		select_one/3,
		select_row/5,
		select_row/3,
		select_row/2,
		select_count/2,
		select_all/5,
		select_all/3,
		select_all/2,
		delete/2,
        stat_table_op_count/3
      ]
).
-define(RECORD_CUR_TIME, Now = erlang:now(),).
%-define(STAT_DB_ACCESS(Table_name, Operation), stat_db_access(Table_name, Operation, Now),).
-define(STAT_DB_ACCESS(Table_name, Operation),skip,).

%% 插入数据表，获得id
insert_get_id(Table_name, FieldList, ValueList) ->
  ?RECORD_CUR_TIME
  Sql = db_esql:make_insert_sql(Table_name, FieldList, ValueList),
  Result = db_esql:update_get_id(?DB_SERVER, Sql),
  ?STAT_DB_ACCESS(Table_name, insert_get_id)
  Result.

%% 插入数据表
insert(Table_name, FieldList, ValueList) ->
  ?RECORD_CUR_TIME
  Sql = db_esql:make_insert_sql(Table_name, FieldList, ValueList),
  Result = db_esql:execute(?DB_SERVER, Sql),
  ?STAT_DB_ACCESS(Table_name, insert)
  Result.
insert(Table_name, Field_Value_List) ->
  ?RECORD_CUR_TIME
  Sql = db_esql:make_insert_sql(Table_name, Field_Value_List),
  Result = db_esql:execute(?DB_SERVER, Sql),
  ?STAT_DB_ACCESS(Table_name, insert)
  Result.

%% 修改数据表(replace方式)
replace(Table_name, Field_Value_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_replace_sql(Table_name, Field_Value_List),
	Result = db_esql:execute(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, replace)
	Result.

%% 修改数据表，获得id
replace_get_id(Table_name, Field_Value_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_replace_sql(Table_name, Field_Value_List),
	Result = db_esql:update_get_id(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, replace_get_id)
	Result.

%% 修改数据表(update方式)
update(Table_name, Field, Data, Key, Value) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_update_sql(Table_name, Field, Data, Key, Value),
	Result = db_esql:execute(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, update)
	Result.
update(Table_name, Field_Value_List, Where_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_update_sql(Table_name, Field_Value_List, Where_List),
	Result = db_esql:execute(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, update)
	Result.

%% 警告：只用于特殊复杂的sql语句，其他禁用！！！
%% 注意：Sql是完整的sql语句，而Table_name是用来标识是哪个表的，Table_name和Sql语句里的表名要一样
update(Table_name, Sql) ->
	?RECORD_CUR_TIME
	Result = db_esql:execute(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, update)
	Result.

%% 获取一个数据字段
select_one(Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
 	Result = db_esql:get_one(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.
select_one(Table_name, Fields_sql, Where_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List),
	Result = db_esql:get_one(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.

%% 获取一条数据记录
select_row(Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
 	Result = db_esql:get_row(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.
select_row(Table_name, Fields_sql, Where_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List),
	Result = db_esql:get_row(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.

%% 警告：只用于特殊复杂的sql语句，其他禁用！！！
%% 注意：Sql是完整的sql语句，而Table_name是用来标识是哪个表的，Table_name和Sql语句里的表名要一样
select_row(Table_name, Sql) ->
	?RECORD_CUR_TIME
	Result = db_esql:get_row(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.

%% 获取记录个数 
select_count(Table_name, Where_List) ->
	select_row(Table_name, "count(1)", Where_List).

%% 获取所有数据
select_all(Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num),
	Result = db_esql:get_all(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.
select_all(Table_name, Fields_sql, Where_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_select_sql(Table_name, Fields_sql, Where_List),
	Result = db_esql:get_all(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.

%% 警告：只用于特殊复杂的sql语句，其他禁用！！！
%% 注意：Sql是完整的sql语句，而Table_name是用来标识是哪个表的，Table_name和Sql语句里的表名要一样
select_all(Table_name, Sql) ->
	?RECORD_CUR_TIME
	Result = db_esql:get_all(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, select)
	Result.

%% 删除数据
delete(Table_name, Where_List) ->
	?RECORD_CUR_TIME
	Sql = db_esql:make_delete_sql(Table_name, Where_List),
	Result = db_esql:execute(?DB_SERVER, Sql),
	?STAT_DB_ACCESS(Table_name, delete)
	Result.

%% 事务处理
%% transaction(Fun) ->
%% 	db_esql:transaction(Fun).

%% --------------------------------------------------------------------------
%%统计数据表操作次数和频率
stat_db_access(Table_name, Operation, Begin_sql_time) ->
	try
		Now = erlang:now(),
		SqlTime = timer:now_diff(Now, Begin_sql_time),
		Key = lists:concat([Table_name, "/", Operation]),
		[NowBeginTime, NowCount, NowSqlTime] = 
		case ets:match(?ETS_STAT_DB,{Key, Table_name, Operation , '$4', '$5', '$6'}) of
			[[OldBeginTime, OldCount, OldSqlTime]] ->
				[OldBeginTime, OldCount+1, erlang:max(SqlTime, OldSqlTime)];
			_ ->
				[Now,1,SqlTime]
		end,	
		ets:insert(?ETS_STAT_DB, {Key, Table_name, Operation, NowBeginTime, NowCount, NowSqlTime}),
		ok
	catch
		_:_ -> no_stat
	end.
%% --------------------------------------------------------------------------
%%统计某个表的各操作的次数
%%使用示例：stat_table_op_count(Table_name, player, Field_Value_List)
stat_table_op_count(Table_name, Stat_table_name, Op) ->
	if 
		Table_name == Stat_table_name ->
			case ets:info(ets_stat_sql_table_op) of
				undefined ->
					ets:new(ets_stat_sql_table_op, [set, public, named_table]);
				_ ->
					skip
			end,
			case ets:lookup(ets_stat_sql_table_op, Op) of
				[] ->
					ets:insert(ets_stat_sql_table_op,{Op, 1});
				[{_, Count}] ->
					ets:insert(ets_stat_sql_table_op,{Op, Count+1})
			end;
		true ->
			skip
	end.
