-module(pt_41).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 41001 查询拍卖
%%--------------------------------------
read(41001,<<QueryType:8>>) ->
    {ok, [QueryType]};

%%--------------------------------------
%%Protocol: 41002 市场购买
%%--------------------------------------
read(41002,<<SaleId:64>>) ->
    {ok, [SaleId]};

%%--------------------------------------
%%Protocol: 41003 市场挂售
%%--------------------------------------
read(41003,<<GoodsUId:64,Num:32,Price:32>>) ->
    {ok, [GoodsUId,Num,Price]};

%%--------------------------------------
%%Protocol: 41004 取消挂售
%%--------------------------------------
read(41004,<<SaleId:64>>) ->
    {ok, [SaleId]};

%%--------------------------------------
%%Protocol: 41005 查询我的拍卖
%%--------------------------------------
read(41005,_) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 41006 按关键字搜索拍卖 
%%--------------------------------------
read(41006,<<BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Content]};

%%--------------------------------------
%%Protocol: 41011 按关键字搜索求购
%%--------------------------------------
read(41011,<<BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Content]};

%%--------------------------------------
%%Protocol: 41012 查询求购 
%%--------------------------------------
read(41012,<<QueryType:8>>) ->
    {ok, [QueryType]};

%%--------------------------------------
%%Protocol: 41013 查询我的求购 
%%--------------------------------------
read(41013,_) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 41014 求购出售
%%--------------------------------------
read(41014,<<RequestId:64,Num:32>>) ->
    {ok, [RequestId,Num]};

%%--------------------------------------
%%Protocol: 41015 求购
%%--------------------------------------
read(41015,<<GoodsId:64,Num:32,Price:32>>) ->
    {ok, [GoodsId,Num,Price]};

%%--------------------------------------
%%Protocol: 41016 热卖查询
%%--------------------------------------
read(41016,_) ->
    {ok, []};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 41001 查询拍卖
%%--------------------------------------
write(41001,[SellingList]) ->
	SellingLen = length(SellingList),
	SellingList2 = case SellingLen > 20 of
		true ->
			lists:nthtail(SellingLen - 20,SellingList);
		false ->
			SellingList
	end,
	SellingBin = tool:to_binary([pack_selling(S) || S <- SellingList2]),
	{ok,pt:pack(41001,<<SellingLen:8,SellingBin/binary>>)};

%%--------------------------------------
%%Protocol: 41005 查询我的拍卖
%%--------------------------------------
write(41005,[SellingList]) ->
	SellingLen = length(SellingList),
	SellingBin = tool:to_binary([pack_selling(S) || S <- SellingList]),
	{ok,pt:pack(41005,<<SellingLen:8,SellingBin/binary>>)};

%%--------------------------------------
%%Protocol: 41012 查询求购返回
%%--------------------------------------
write(41012,[RequestList]) ->
	RequestLen = length(RequestList),
	RequestList2 = case RequestLen > 20 of
		true ->
			lists:nthtail(RequestLen - 20,RequestList);
		false ->
			RequestList	
	end,
	RequestBin = tool:to_binary([pack_request(S) || S <- RequestList2]),
	{ok,pt:pack(41012,<<RequestLen:8,RequestBin/binary>>)};

%%--------------------------------------
%%Protocol: 41013 查询我的求购返回
%%--------------------------------------
write(41013,[RequestList]) ->
	RequestLen = length(RequestList),
	RequestBin = tool:to_binary([pack_request(S) || S <- RequestList]),
	{ok,pt:pack(41013,<<RequestLen:8,RequestBin/binary>>)};

%--------------------------------------
%%Protocol: 41016 查询热卖返回
%%--------------------------------------
write(41016,[RequestList]) ->
	RequestLen = length(RequestList),
	RequestBin = tool:to_binary([pack_request(S) || S <- RequestList]),
	{ok,pt:pack(41016,<<RequestLen:8,RequestBin/binary>>)};


%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

pack_selling(Selling) ->
	if
		is_record(Selling,market_selling) ->
			NewSelling = Selling ;
		true ->
			NewSelling = #market_selling{}
	end ,
	SaleId = NewSelling#market_selling.id,
	GoodsUId = NewSelling#market_selling.goods_uid,
	GoodsId = NewSelling#market_selling.goods_id,
	Num = NewSelling#market_selling.num,
	NowTime = util:unixtime(),
	LeftTime = NewSelling#market_selling.end_time - NowTime,
	Price = NewSelling#market_selling.price,
	<<SaleId:64,GoodsUId:64,GoodsId:64,LeftTime:32,Num:32,Price:32>>.

pack_request(Request) ->
	if
		is_record(Request,market_request) ->
			NewRequest = Request;
		true ->
			NewRequest = #market_request{}
	end ,
	RequestId = NewRequest#market_request.id,
	PlayerId = NewRequest#market_request.player_id,
	GoodsId = NewRequest#market_request.goods_id,
	Num = NewRequest#market_request.num,
	Price = NewRequest#market_request.price,
	NowTime = util:unixtime(),
	LeftTime = NewRequest#market_request.end_time - NowTime,
	<<RequestId:64,PlayerId:64,GoodsId:64,LeftTime:32,Num:32,Price:32>>.
