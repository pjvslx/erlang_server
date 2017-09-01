-module(robot_gm).
-compile(export_all).

-include("robot.hrl").

%%断言以及打印调试信息宏
%%不需要时启用 -undefine行
%%-define(gm_debug, 1).
%-undefine(gm_debug).
-ifdef(gm_debug).
    -define(MYTRACE(Str), io:format(Str)).
    -define(MYTRACE(Str, Args), io:format(Str, Args)).
-else.
    -define(MYTRACE(Str), void).
    -define(MYTRACE(Str, Args), void).
-endif.

%%----------------------  初始帐号  ----------------------
-define(AUTO_CHAT_LIST,		[
								<<"-level 10">>,
%% 								<<"-coin 1000000">>,
%% 								<<"-bcoin 1000000">>,
%% 								<<"-gold 100000">>,
%% 								<<"-bgold 100000">>,
								<<"-exp 10000000">>
							]).

handle(State) -> 
    F = fun(Msg) ->
        {ok, BinData} = ptr_11:write(11005, [1, Msg]), 
        mysend(State#robot.socket, BinData)
    end,
    lists:foreach(F, ?AUTO_CHAT_LIST),
    State.
	
mysend(Socket, BinData) ->
    <<_:16, _Cmd:16, _/binary>>  = BinData,
    ?MYTRACE("sending: cmd: ~p~n", [_Cmd]),
    gen_tcp:send(Socket, BinData).
