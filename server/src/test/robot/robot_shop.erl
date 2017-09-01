-module(robot_shop).
-compile(export_all).

%-include("common.hrl").
-include("robot.hrl").
-define(SHOP_REFRESH,1).
-define(SHOP_BUY,2).
-define(ADD_GOLD,3).
-define(ACTIONS,[?SHOP_REFRESH,?SHOP_BUY]).

handle(State) -> 
	Rand = random:uniform(100),
	case Rand > 50 of
		true ->
			Act = ?SHOP_REFRESH;
		false ->
			Act = ?SHOP_BUY
	end,
	add_gold(State),
	do_action(State,Act),
    State.

do_action(State,Act) ->
	case Act of
		?SHOP_REFRESH->
			io:format("do_action:shop_refresh~n"),
			do_shop_refresh(State);
		?SHOP_BUY ->
			io:format("do_action:shop_buy~n"),
			do_shop_buy(State);
		_ ->
			skip
	end.
	
do_shop_refresh(State) ->
	BinData = pt:pack(15042,<<>>),
    gen_tcp:send(State#robot.socket, BinData).

do_shop_buy(State) ->
	BinData = pt:pack(15043,<<>>),
    gen_tcp:send(State#robot.socket, BinData).

add_gold(State) ->
    Content = "-addgold 111",
    ContentLen = length(Content),
    NewContent = list_to_binary(Content),
    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)).

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
