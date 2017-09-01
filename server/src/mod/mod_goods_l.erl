%%%-------------------------------------- 
%%% @Module: mod_goods_l
%%% @Author: 
%%% @Created:
%%% @Description: 
%%%-------------------------------------- 
-module(mod_goods_l).
-behaviour(gen_server).

-include("goods.hrl").
-include("record.hrl").
-include("common.hrl").
-include("debug.hrl").

-record(state, {can_use = [], full = []}).

-export([ init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3 ]).
-export([
		 start_link/0,             
		 get_min_ets_goods_name/0,
		 sub_ets_goods_num/1,
		 goods_ets_name/1,
		 %% 			 task_log_ets_name/1,
		 goods_ets_attr_name/1,get/0,set/2,
		 goods_ets_polish_name/1
		]).

%% desc: 获取可以加入玩家物品信息的最小的ets表名，减少一个可用名额
%% returns: none | AtomName
get_min_ets_goods_name() ->
	gen_server:call(?MODULE, 'GET_MIN_ETS_GOODS_NAME').  

%% desc: 增加一个可用名额
sub_ets_goods_num(Integer) ->
	gen_server:cast(?MODULE, {'SUB_ETS_GOODS_NUM', Integer}).

%% desc: 获取玩家自己的物品ets表名
%% mod_goods_l:goods_ets_name(PS)
goods_ets_name(PS) when is_record(PS, player) ->
	misc:create_goods_ets_name(PS#player.other#player_other.goods_ets_id);
goods_ets_name(PlayerId) ->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[] -> none;
		[Player] -> misc:create_goods_ets_name(Player#player.other#player_other.goods_ets_id)
	end.


%% desc: 获取玩家自己的任务log ets表名
%% mod_goods_l:task_log_ets_name(PS)
%% task_log_ets_name(PS) when is_record(PS, player) ->
%%     misc:create_task_log_ets_name(PS#player.other#player_other.goods_ets_id);
%% task_log_ets_name(PlayerId) ->
%%     case catch lib_player:get_online_info_fields(PlayerId, [other#player_other.goods_ets_id]) of
%%         [Num] -> 
%%             misc:create_task_log_ets_name(Num);
%%         Error ->
%%             ?WARNING_MSG("get_goods_ets_name failed:~p, stack:~w", [{PlayerId, Error}, erlang:get_stacktrace()]),
%%             ?ASSERT(false),
%%             none
%%     end.
%% desc: 获取玩家自己的物品ets表属性名
%% mod_goods_l:goods_ets_name(PS)
goods_ets_attr_name(PS) when is_record(PS, player) ->
	misc:create_goos_attr_ets_name(PS#player.other#player_other.goods_ets_id);
goods_ets_attr_name(PlayerId) ->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[] -> none;
		[Player] -> misc:create_goos_attr_ets_name(Player#player.other#player_other.goods_ets_id)
	end.

%% desc: 获取玩家自己的物品ets表属性名
%% mod_goods_l:goods_ets_wash_name(PS)
goods_ets_polish_name(PS) when is_record(PS, player) ->
	misc:create_goods_polish_ets_name(PS#player.other#player_other.goods_ets_id);
goods_ets_polish_name(PlayerId) ->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[] -> none;
		[Player] -> misc:create_goods_polish_ets_name(Player#player.other#player_other.goods_ets_id)
	end.

%% ---------------------------------------------------------------------
%% LESS USE External Functions
%% ---------------------------------------------------------------------
%% desc: 开启物品ets表管理进程
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%% ---------------------------------------------------------------------
%% Internal Functions
%% ---------------------------------------------------------------------

%% desc: 初始化
init([]) ->
	F = fun(Num) -> {Num, 0} end,
	CanUse = lists:map(F, lists:seq(1, ?MAX_GOODS_ETS_NUM)),
	{ok, #state{can_use = CanUse, full = []}}.

%% desc: 获取可以加入玩家物品信息的最小的ets表id
handle_call('GET_MIN_ETS_GOODS_NAME', _From, State) ->
	case State#state.can_use == [] of
		true -> 
			?ERROR_MSG("there is no any goods_ets for role, full list:~p", [State#state.full]),
			?ASSERT(false),
			{reply, 0, State};
		false ->
			[Head, NewState] =
				try 
					Len = length(State#state.can_use),
					Rand = util:rand(1, Len),
					Head1 = lists:nth(Rand, State#state.can_use),
					NewState1 = handle_cost_one(Head1, State),
					[Head1, NewState1]
				catch 
					_:Reason -> ?ERROR_MSG("get_min_ets_goods_name failed:~p", [Reason]), ?ASSERT(false), [{0}, State]
				end,
			{reply, erlang:element(1, Head), NewState}
	end;

%% desc: 
handle_call(_msg, _from, State) ->
	{reply, ok, State}.

%% desc: 增加一个可容纳个数
handle_cast({'SUB_ETS_GOODS_NUM', Integer}, State) ->
	case is_legal(Integer) of
		true ->
			NewState = 
				try
					sub_goods_ets_num(Integer, State)
				catch 
					_:Reason -> ?ERROR_MSG("add ets goods num failed-- reason:~p", [Reason]), ?ASSERT(false), State
				end,
			{noreply, NewState};
		_ ->
			?ERROR_MSG("add ets goods num -- bad args:~p", [Integer]),
			?ASSERT(false),
			{noreply, State}
	end;

%% desc: 
handle_cast('GET', State) ->
	{noreply, State};

%% desc: 
handle_cast({'SET', Num, Num1}, State) ->
	case lists:keyfind(Num, 1, State#state.can_use) of
		false -> {noreply, State};
		{Num, C} ->
			Can = lists:keyreplace(Num, 1, State#state.can_use, {Num, C+Num1}),
			{noreply, State#state{can_use = Can}}
	end;

%% desc: 
handle_cast(_msg, State) ->
	{noreply, State}.

%% desc: 
handle_info(_msg, State) ->
	{noreply, State}.

%% desc:
terminate(_reason, _state) ->
	ok.

%% desc:
code_change(_vsn, State, _extra) ->
	{ok, State}.

%% ---------------------------------------------------------------------
%% LESS USE Internal Functions
%% ---------------------------------------------------------------------

%% desc: 可用ets表最小表减少一个容纳数
handle_cost_one({UseId, CurNum}, State) ->
	Tail = lists:keydelete(UseId, 1, State#state.can_use),
	NewNum = CurNum + 1,
	{CanUse, Full} = 
		case NewNum >= ?MAX_ROLE_NUM of
			true ->
				{
				 Tail, 
				 [{UseId, NewNum} | State#state.full]
				};
			false ->
				{
				 [{UseId, NewNum} | Tail],
				 State#state.full
				}
		end,
	State#state{can_use = CanUse, full = Full}.

%% desc: 减少一个占用
sub_goods_ets_num(Integer, State) ->
	[CanUse, Full] = 
		case lists:keyfind(Integer, 1, State#state.can_use) of
			{Integer, CurNum} ->
				Num = adjust_curnum(Integer, CurNum),
				[sub_one(Integer, Num, State), State#state.full];
			false ->
				[sub_one({Integer, ?MAX_ROLE_NUM}, State), lists:keydelete(Integer, 1, State#state.full)]
		end,
	State#state{can_use = CanUse, full = Full}.

%% desc: 增加一个
sub_one({Integer, CurNum}, State) ->
	[{Integer, CurNum - 1} | State#state.can_use].
sub_one(Integer, CurNum, State) ->
	lists:keyreplace(Integer, 1, State#state.can_use, {Integer, CurNum - 1}).

%% desc: 矫正当前数量
adjust_curnum(Integer, CurNum) ->
	case CurNum > ?MAX_ROLE_NUM  of
		true ->  
			?ERROR_MSG("bad ets_goods cur num:~p, id:~p", [CurNum, Integer]),
			?ASSERT(false),
			?MAX_ROLE_NUM;
		false ->
			case CurNum =< 0 of
				true -> 
					?ERROR_MSG("bad ets_goods cur num:~p, id:~p", [CurNum, Integer]),
					1;
				false ->
					CurNum
			end
	end.


%% test: mod_goods_l:get().
get() ->
	gen_server:cast(?MODULE, 'GET').
%% test: mod_goods_l:set().
set(Num, Num1) ->
	gen_server:cast(?MODULE, {'SET', Num, Num1}).

%% desc: 判断传入的参数是否合法
is_legal(Integer) ->
	is_integer(Integer) andalso Integer >= 1 andalso Integer =< ?MAX_GOODS_ETS_NUM.
