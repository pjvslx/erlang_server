%%%-----------------------------------
%%% @Module  : mod_db_log
%%% @Author  : smxx
%%% @Created : 2013.01.15
%%% @Description: 数据库日志
%%%-----------------------------------
-module(mod_db_log). 
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


start_link(LogPath) ->      %% 启动服务
   gen_server:start_link({local, ?MODULE}, ?MODULE, [LogPath], []).

init([undefined]) ->
	{error,[]};
init([LogPath]) -> 
	put(log_path,LogPath),
	lib_log:init_log_sys(LogPath),       
	{ok, []}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%%写日志回调
handle_cast({do_log,Flag,LogType,TableName,Arg1,Arg2},State)->
	 lib_log:wirte_db_log(Flag,LogType,TableName,Arg1,Arg2),
	 {noreply, State};

handle_cast(_MSg,State)->
	 {noreply, State}.

%%每晚12点操作
handle_info(midnight,State)->
	lib_log:do_midnight(),
	{noreply, State};

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->   
	misc:delete_monitor_pid(self()).

code_change(_OldVsn, State, _Extra)->
    {ok, State}.
 
%%获取数据库日志模块进程id
get_db_log_pid() ->   
	case misc:whereis_name({local, ?MODULE}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;
				false ->
					DbLogPath = config:get_db_log_path(),
					?MODULE:start_link([DbLogPath])
			end ;
		_ ->
			DbLogPath = config:get_db_log_path(),
			?MODULE:start_link([DbLogPath]) 
	end .
 