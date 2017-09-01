%%%-----------------------------------
%%% @Module  : mod_rand
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 随机种子
%%%-----------------------------------
-module(mod_rand).
-behaviour(gen_server).
-export([
        start_link/0,
        get_seed/0,
		get_find_rannum/2,
		get_rannum/2
    ]
).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").

-record(state, {seed}).

%% --- 对外接口 ---------------------------------

%% 启动服务器
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 取得一个随机数种子
get_seed() ->
    gen_server:call(?MODULE, get_seed).

%% 获得长生阁随机数
get_find_rannum(Modle, Length) ->
	gen_server:call(?MODULE, {get_find_random, Modle, Length}).

%% 获得随机数（通用）
get_rannum(Modle, Length) ->
	gen_server:call(?MODULE, {get_random, Modle, Length}).

%% --- 服务器内部实现 ---------------------------------

init([]) ->
	misc:write_monitor_pid(self(),?MODULE, {}),
    State = #state{},
    {ok, State}.

%% 返回一个随机数组合做为其它进程的随机数种子
handle_call(get_seed, _From, State) ->
    case State#state.seed of  
        undefined -> random:seed(now());
        S -> random:seed(S)
    end,
    Seed = {random:uniform(999999), random:uniform(999999), random:uniform(999999)},
    {reply, Seed, State#state{seed = Seed}};

%%按类型获取随机数序列  
handle_call({get_find_random, Modle, Length}, _From, State) ->
	if is_integer(Length) ->
		   if Length > 0 ->
				  ModleSeed = tool:to_atom(lists:concat([random_find_seed,"_", Modle])),
				  NumList = lists:seq(1, Length),
				  Fun = fun(_Num) ->
								uniform_find(ModleSeed, 10000)
						end,
				  Res = lists:map(Fun, NumList);
			  true ->
				  Res = err
		   end;
	   true ->
		   Res = err
	end,
	{reply, Res, State};

%%按类型获取随机数序列（通用）
handle_call({get_random, Modle, Length}, _From, State) ->
	if is_integer(Length) ->
		   if Length > 0 ->
				  ModleSeed = tool:to_atom(lists:concat([random_seed,"_", Modle])),
				  NumList = lists:seq(1, Length),
				  Fun = fun(_Num) ->
								uniform_find(ModleSeed, 10000)
						end,
				  Res = lists:map(Fun, NumList);
			  true ->
				  Res = err
		   end;
	   true ->
		   Res = err
	end,
	{reply, Res, State};

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
	misc:delete_monitor_pid(self()),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

seed0_find() ->
    {random:uniform(999999), random:uniform(999999), random:uniform(999999)}.

uniform_find(ModleSeed) ->
    {A1, A2, A3} = case get(ModleSeed) of
		       undefined -> seed0_find();
		       Tuple -> Tuple
		   end,
    B1 = (A1*171) rem 30269,
    B2 = (A2*172) rem 30307,
    B3 = (A3*170) rem 30323,
    put(ModleSeed, {B1,B2,B3}),
    R = A1/30269 + A2/30307 + A3/30323,
    R - trunc(R).

uniform_find(ModleSeed, N) when is_integer(N), N >= 1 ->
    trunc(uniform_find(ModleSeed) * N) + 1.
%%===================================================
