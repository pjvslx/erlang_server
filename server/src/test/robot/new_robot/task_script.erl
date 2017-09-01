%% @author Administrator
%% @doc @todo Add description to task_script.


-module(task_script).
-define(HEADER_LENGTH, 4). %
%% ====================================================================
%% API functions
%% ====================================================================
-export([call/3]).

%% ====================================================================
%% Internal functions
%% ====================================================================

call(30003,TaskId,Socket)->
	  gen_tcp:send(Socket, pack(30003, <<TaskId:16>>));
call(30004,TaskId,Socket)->
	gen_tcp:send(Socket, pack(30004, <<TaskId:16>>));
call(30007,TaskId,Socket)->
	gen_tcp:send(Socket, pack(30007, <<TaskId:16>>));
call(30005,NpcList,Socket)->
	gen_tcp:send(Socket, pack(30005, NpcList));
call(30006,Size,Socket)->
	  gen_tcp:send(Socket, pack(30006, <<Size:8>>)).
	
	%%打包数据
pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
