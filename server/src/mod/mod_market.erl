-module(mod_market).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile([export_all]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("market.hrl").

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%加载数据库
%%raise_save
%%挂售
%%购买
init([]) ->
	process_flag(trap_exit, true),
	misc:write_monitor_pid(self(),?MODULE, {}),
	misc:write_system_info(self(), ?MODULE, {}),	
    ets:new(?ETS_MARKET_SELLING, [{keypos,#market_selling.id}, named_table, public, set]),
    ets:new(?ETS_MARKET_REQUEST, [{keypos,#market_request.id}, named_table, public, set]),
	lib_market:init_market_from_db(),
    % 定时清理过期太久的上架物品
	lib_market:clear_expired_goods(),
    ExtraRandIntv = util:rand(0, 60 * 1000),
    erlang:send_after(?CLEAR_EXPIRED_GOODS_INTV + ExtraRandIntv, self(), 'CLEAR_EXPIRED_GOODS'),
    {ok, none}.

get_mod_market_pid() ->
	case misc:whereis_name({local, ?MODULE}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;				
				false -> 
					start_mod_market(?MODULE)
			end;
		_ ->
			start_mod_market(?MODULE)
	end.

start_mod_market(ProcessName) ->
	case misc:whereis_name({local, ProcessName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true -> 
					Pid;
				false -> 
					start_market(ProcessName)
			end;
		_ ->
			start_market(ProcessName)
	end .

start_market(_ProcessName) ->
	case supervisor:start_child(
		   game_server_sup, {mod_market,
							{mod_market, start_link,[]},
							permanent, 10000, supervisor, [mod_market]}) of
		{ok, Pid} ->
			Pid;
		_ ->
			undefined
	end.

%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, State) -> 
	Reply = ?APPLY(Module, Method, Args,[]),
    {reply, Reply, State};
	
handle_call(_Request, _From, State) ->
    {reply, State, State}.
 
%% 统一模块+过程调用(cast)
handle_cast({apply_cast, Module, Method, Args}, State) -> 
	?APPLY(Module, Method, Args,[]),
    {noreply, State}; 

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info('CLEAR_EXPIRED_GOODS',State)-> 
    ExtraRandIntv = util:rand(0, 60 * 1000),
	lib_market:clear_expired_goods(),
	NextTimer = erlang:send_after(?CLEAR_EXPIRED_GOODS_INTV + ExtraRandIntv, self(), 'CLEAR_EXPIRED_GOODS'),
	{noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

query_selling(QueryType) ->
	try 
		gen_server:cast(get_mod_market_pid(),{apply_cast,lib_market,query_selling,[QueryType]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  query_selling error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[query_selling]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

market_buy(Status,SaleId) ->
	try 
		case gen_server:call(get_mod_market_pid(),{apply_call,lib_market,market_buy,[Status,SaleId]}) of
			{ok,NewStatus} ->
				{ok,NewStatus};
			_ ->
				fail
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  market_buy error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[market_buy]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

market_sale(Status,GoodsUId,Num,Price) ->
	try 
		case gen_server:call(get_mod_market_pid(),{apply_call,lib_market,market_sale,[Status,GoodsUId,Num,Price]}) of
			{ok,NewStatus} ->
				{ok,NewStatus};
			_ ->
				fail
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  market_sale error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[market_sale]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

market_cancel_sale(Status,SaleId) ->
	try 
		case gen_server:call(get_mod_market_pid(),{apply_call,lib_market,market_cancel_sale,[Status,SaleId]}) of
			{ok,NewStatus} ->
				{ok,NewStatus};
			_ ->
				fail
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  market_cancel_sale error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[market_cancel_sale]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

market_request(Status,GoodsId,Num,Price) ->
	try 
		case gen_server:call(get_mod_market_pid(),{apply_call,lib_market,market_request,[Status,GoodsId,Num,Price]}) of
			{ok,NewStatus} ->
				{ok,NewStatus};
			_ ->
				fail
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  market_request error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[market_request]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

market_request_sale(Status,RequestId,Num) ->
	try 
		case gen_server:call(get_mod_market_pid(),{apply_call,lib_market,market_request_sale,[Status,RequestId,Num]}) of
			{ok,NewStatus} ->
				{ok,NewStatus};
			_ ->
				fail
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_market]  market_request_sale error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[market_request_sale]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

