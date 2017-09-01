-module(robot_market).
-compile(export_all).

%-include("common.hrl").
-include("robot.hrl").
-record(bag_list,{
		id,
		tid,
		cell,
		num,
		stren,	
		strenPer,
		bind
	}).
-record(sale_list,{
		saleId,
		goodsUid,
		goodsId,
		leftTime,
		num,
		price
	}).
-define(ADD_GOODS,1).
-define(DO_SALE,2).
-define(DO_BUY,3).
-define(GOODS,[262035204]).
-define(ACTIONS,[?ADD_GOODS,?DO_SALE,?DO_BUY]).

handle(State) -> 
	Cmds = [41001],
	%%Chat_List = ?AUTO_CHAT_LIST,
	%%Msg = tool:to_list(lists:nth(random:uniform(length(Chat_List)), Chat_List)), 
	Rand = random:uniform(100),
	case Rand > 50 of
		true ->
			Act = ?DO_SALE;
		false ->
			case Rand > 20 of
				true ->
					Act = ?ADD_GOODS;
				false ->
					Act = ?ADD_GOODS
			end	
	end,
	%%Act = lists:nth(random:uniform(length(?ACTIONS)), ?ACTIONS),
	do_action(State,Act),
    State.

do_action(State,Act) ->
	case Act of
		?ADD_GOODS ->
			io:format("do_action:add_goods~n"),
			become_vip(State),
			sale_add_goods(State);
		?DO_SALE ->
			io:format("do_action:query_bag~n"),
			query_bag(State);
		?DO_BUY ->
			io:format("do_action:do_query~n"),
			do_buy(State);
		_ ->
			skip
	end.
	
do_parse_packet(_Socket, _Pid, Cmd, BinData) ->
    {ok, _Result} = ptr_41:read(Cmd, BinData),
	case Cmd of
		41001 ->
			case _Result of
				<<Len:8,SellingBin/binary>> ->
					case parse_sale_list(SellingBin,[]) of
						SaleList when length(SaleList) > 0 ->
							Sale = lists:nth(random:uniform(length(SaleList)), SaleList),
							io:format("SaleList~p~n",[Sale#sale_list.saleId]),
							{ok, BinData2} = ptr_41:write(41002, [Sale#sale_list.saleId]),
    						gen_tcp:send(_Socket, BinData2);
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip	
	end,
    io:format("Cmd: ~p, Result: ~p~n", [Cmd, _Result]).

do_buy(State) ->
	sale_add_gold(State),
	do_query(State).

do_query(State) ->
	{ok, BinData} = ptr_41:write(41001, [0]),
    gen_tcp:send(State#robot.socket, BinData).

do_sale(State,BagList) ->
	lists:map(fun(Data) -> 
			case lists:member(Data#bag_list.tid,?GOODS) of
				true ->
					io:format("do_sale::~p~n",[Data#bag_list.id]),
					{ok,BinData} = ptr_41:write(41003,[Data#bag_list.id,1,10]),
    				gen_tcp:send(State#robot.socket, BinData);
				false ->
					skip
			end
		end,BagList).
	
refresh_bag(State,BinData) ->
	<<Location:8,CellNum:16,ListNum:16,ListBin/binary>> = BinData,
	BagList = parse_bag_data(ListBin,[]),
	do_sale(State,BagList).

parse_sale_list(BinData,Result) ->
	case BinData of
		<<SaleId:64,GoodsUId:64,GoodsId:64,LeftTime:32,Num:32,Price:32,LeftData/binary>> ->
			Result2 = Result ++ [#sale_list{saleId=SaleId,goodsUid=GoodsUId,goodsId=GoodsId,leftTime=LeftTime,num=Num,price=Price}],
			parse_sale_list(LeftData,Result2);
		_ ->
			Result
	end.
	
parse_bag_data(BinData,Result) ->
	case BinData of
    	<<GoodsId:64, TypeId:32, Cell:16, GoodsNum:16, Stren:8, StrenPer:8, Bind:8,LeftData/binary>> ->
			Result2 = Result ++ [#bag_list{id = GoodsId,tid= TypeId,cell= Cell,num = GoodsNum,stren = Stren,strenPer = StrenPer,bind = Bind}],
			parse_bag_data(LeftData,Result2);
		_ ->
			io:format("market:parse_bag_data::~p~n",[Result]),
			Result
	end.

become_vip(State) ->
    Content = "-gold 1000010",
    ContentLen = length(Content),
    NewContent = list_to_binary(Content),
    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)).
	
sale_add_goods(State) ->
	GoodsId = lists:nth(random:uniform(length(?GOODS)),?GOODS),
    Content = string:concat("-addgoods ",util:term_to_string(GoodsId)),
    Content2 = string:concat(Content," 1"),
    ContentLen = length(Content2),
    NewContent = list_to_binary(Content2),
    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)).

sale_add_gold(State) ->
	GoodsId = lists:nth(random:uniform(length(?GOODS)),?GOODS),
    Content = "-addgold 11",
    ContentLen = length(Content),
    NewContent = list_to_binary(Content),
    gen_tcp:send(State#robot.socket, pack(11005, <<0:8,<<ContentLen:16,NewContent:ContentLen/binary-unit:8>>/binary>>)).

query_bag(State) ->
    gen_tcp:send(State#robot.socket, pack(15002, <<0:8>>)).

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
