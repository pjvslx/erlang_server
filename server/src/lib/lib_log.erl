%% Author: Administrator
%% Created: 2013-4-11
%% Description: TODO: Add description to lib_log
-module(lib_log).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

-define(MAX_LOG_SIZE, 150).
%%
%% Exported Functions
%%
-export([wirte_db_log/5,init_log_sys/1,do_midnight/0]).



%%初始化日志库
init_log_sys(LogPath)->
	put(log_tables,[]),
	init_log_dir(LogPath).

%%写日志
wirte_db_log(insert,?DB_LOG_NORMAL,TableName,FieldList,ValueList)->
	spawn(?DB_LOG_MODULE,insert,[TableName,FieldList,ValueList]);
wirte_db_log(insert,?DB_LOG_DELAY,TableName,FieldList,ValueList) -> 
	Sql = db_esql:make_insert_sql(TableName, FieldList, ValueList),
	do_log(TableName, Sql);
wirte_db_log(update,?DB_LOG_NORMAL,TableName,FieldValueList,WhereList)-> 
	?DB_LOG_MODULE:update(TableName,FieldValueList,WhereList);
wirte_db_log(update,?DB_LOG_DELAY,TableName,FieldValueList,WhereList) ->
	Sql = db_esql:make_update_sql(TableName, FieldValueList, WhereList),
	do_log(TableName, Sql).

%%凌晨操作
do_midnight()->
	log_all_2_file().
	
%--------------------
%-	内部函数 非请勿用
%--------------------
init_log_dir(Path)->
	case filelib:is_dir(Path) of  
		true ->  
			ok;  
		false ->
			file:make_dir(Path)
	end.

%%当某个表的缓存日志达到上限时,写文件日志,否则做缓存
do_log_by_case(?MAX_LOG_SIZE,TableName,Log)-> 
	Path  = get(log_path),
	RealLogPath = lists:concat([Path,TableName,".sql"]),
    spawn(file, write_file, [RealLogPath,Log,[append]]), 
	put({log_cache,TableName},{0,""});
do_log_by_case(Count,TableName,Log)->
	put({log_cache,TableName},{Count,Log}).

%%操作缓存日志
do_log(TableName,Log)-> 
	TmpLog = lists:concat([Log,";\n"]),
	case get({log_cache,TableName}) of
		undefined ->
			put({log_cache,TableName},{1,TmpLog});
		{Count,OldLog} -> 
			NewLog = lists:concat([OldLog,TmpLog]),
			do_log_by_case(Count+1,TableName,NewLog)
	end.
%%获取所有缓存表名
get_all_log_tables()->
	case get(log_tables) of
		undefined ->
			put(log_tables,[]),
			[];
		List -> 
			List
	end.
%%每晚12点统一将当天所有缓存日志写文件
log_all_2_file()->
	TablesList = get_all_log_tables(),
	lists:foreach(fun(TableName) ->
						  case get({log_cache,TableName}) of
							  undefined ->
								  skip;
							  {0,_}->
								  skip;
							  {_,Log}->
								  do_log_by_case(?MAX_LOG_SIZE,TableName,Log)
						  end
				  end
				  , TablesList).
