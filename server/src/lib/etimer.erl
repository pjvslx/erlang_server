%% 模块作用:提供全局定时器
-module(etimer).
-export([
        %-------------------定时器操作函数----------------------%
        % 启动全局定时器
        start_link/2,
        % 添加定时事件,参数是timer
        % 返回值: true 成功; false 失败; finished 结束; invalid_server 非当前服务器; invalid_node 非当前结点
        add/1,
        % 删除定时事件
        del/1,

        %-------------------定时器外部插件函数------------------%
        % 返回事件列表
        tolist/0,
        % 索引查找定时器
        lookup/1,
        % 已经触发多久
        lasting/1,
        % 剩余多久时间触发
        surplus_trigger/1,
        % 剩余多久时间关闭
        surplus_close/1,

        %-------------------定时器调试函数----------------------%
        % 调试--查看友好定时器列表信息
        fine_list/0,
        % 调试--重启定时器
        restart/0,
        % 调试--更新定时器
        debug/0
    ]).

-export([
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3
    ]).

-include("etime.hrl").
-include("etimer.hrl").
-include("common.hrl").

-define(GLOBAL_ETIMER,  global_etimer).

%% 全局事件启动方式,位或运算
-define(MODE_NONE,         0).  % 不对过期事件作任何处理.
-define(MODE_TRIGGER,      1).  % 处理过了触发点,但还在触发期的事件

%% 结点
-define(NODE_SERVER,       0).  % SERVER结点
-define(NODE_WORLD,        1).  % WORLD结点

-record(state, {id = -1, type = server}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Types%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export_type([timer_type/0]).

-type type()        :: server | world.
-type ti()          :: #timer{}.
-type result()      :: boolean() | finished | invalid_server | invalid_node.
-type timer_type()  :: none | trigger | close | remove.

-spec start_link(ServerId, Type)  -> {ok, pid()} when ServerId :: integer(), Type :: type().
-spec add(Tm)       -> result() when Tm :: ti().
-spec del(Id)       -> boolean() when Id :: pos_integer().
-spec tolist()      -> [ti()].
-spec lookup(Id)    -> [ti()] when Id :: pos_integer().
-spec lasting(Id)   -> false | {value, number()} when Id :: pos_integer().
-spec surplus_trigger(Id) -> false | {value, number()} when Id :: pos_integer().
-spec surplus_close(Id) -> false | {value, number()} when Id :: pos_integer().
-spec restart()     -> no_return().
-spec debug()       -> no_return().

-spec correct_mfa(Event) -> none | mfa() when Event :: term().
-spec insert(Tm, State) -> result() when Tm :: ti(), State :: #state{}.
-spec update(Tm) -> result() when Tm :: ti().
-spec insert_internal(Tm) -> result() when Tm :: ti().
-spec update_internal(Tm, Time, {NextState, NextTs, Count}) -> true when
    Tm          :: ti(),
    Time        :: etime:seconds(),
    NextState   :: timer_type(),
    NextTs      :: etime:seconds(),
    Count       :: integer().
-spec delete(Tm) -> true when Tm :: ti().
-spec cancel_timer(Ref) -> boolean() when Ref :: reference() | none().
-spec read_timer(Ref)   -> number() when Ref :: reference() | none().
-spec event(Tm)  -> pid() | ignore when Tm :: ti().
-spec next_timestamp(PrevTs, CurTs, Tm) -> {etime:seconds(), etime:seconds(), integer()} when
    PrevTs      :: etime:seconds(),
    CurTs       :: etime:seconds(),
    Tm          :: ti().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%导出函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_link(ServerId, Type) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [ServerId, Type], []).

add(Tm) ->
    gen_server:call(?MODULE, {add, Tm}).

del(Id) ->
    gen_server:call(?MODULE, {del, Id}).

tolist() ->
    gen_server:call(?MODULE, tolist).

lookup(Id) ->
    ets:lookup(?GLOBAL_ETIMER, Id).

lasting(Id) ->
    case lookup(Id) of
        []                                          -> false;
        [Tm] when trigger =/= Tm#timer.cur_state    -> false;
        [Tm]                                        -> {value, etime:time() - (Tm#timer.mbeg - Tm#timer.interval)}
    end.

surplus_trigger(Id) ->
    case lookup(Id) of
        []                                          -> false;
        [Tm] when trigger =/= Tm#timer.next_state   -> false;
        [Tm]                                        -> {value, read_timer(Tm#timer.ref)}
    end.

surplus_close(Id) ->
    case lookup(Id) of
        []                                          -> false;
        [Tm] when close =/= Tm#timer.next_state     -> false;
        [Tm]                                        -> {value, read_timer(Tm#timer.ref)}
    end.

fine_list() ->
    L = tolist(),
    [io_lib:format("~ts, ~ts, ~ts, ~p, ~p, ~p\n", [Name, etime:strftime(Beg), etime:strftime(Ends), Count, CurState, NextState]) ||
        #timer{name = Name, mbeg = Beg, mends = Ends, mcount = Count, cur_state = CurState, next_state = NextState} <- L].

restart() ->
    gen_server:cast(?MODULE, restart).

debug() ->
    gen_server:cast(?MODULE, debug).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%回调函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init([ServerId, Type]) ->
    gen_server:cast(self(), init_data),

    ets:new(?GLOBAL_ETIMER, [{keypos, #timer.id}, named_table, set, protected]),

    {ok, #state{id = ServerId, type = Type}}.

handle_call({add, Tm}, _From, State) ->
    Res = insert(Tm, State),
    {reply, Res, State};

handle_call({del, Id}, _From, State) ->
    Res = delete(Id),
    {reply, Res, State};


handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast(init_data, State) ->
    [insert(data_timer:get(X), State) || X <- data_timer:list()],
    {noreply, State};

%% handle_cast(restart, State) ->
%%     % 优先处理WORLD节点
%%     case State#state.type of
%%         server  -> rpc:cast(node_world(), etimer, restart, []);
%%         _       -> ignore
%%     end,
%% 
%%     [delete(X) || X <- ets:tab2list(?GLOBAL_ETIMER)],
%%     [insert(data_timer:get(X), State) || X <- data_timer:list()],
%%     {noreply, State};

%% handle_cast(debug, State) ->
%%     F   = fun(S) ->
%%             cancel_timer(S#timer.ref),
%%             insert_internal(S)
%%     end,
%%     % 优先处理WORLD节点
%%     case State#state.type of
%%         server  -> rpc:cast(node_world(), etimer, debug, []);
%%         _       -> ignore
%%     end,
%% 
%%     [F(X) || X <- ets:tab2list(?GLOBAL_ETIMER)],
%%     {noreply, State};
handle_cast(_Request, State) ->
    {noreply, State}.

handle_info({event, Id}, State) ->
    case lookup(Id) of
        [] ->
            {noreply, State};
        [#timer{mbeg = Beg, next_state = NextState, count = Count} = Tm] ->
            % 定时器不精准,重新校位
            Cur   = etime:time(),
            case NextState =:= trigger andalso Cur < Beg of
                true    -> update_internal(Tm, Beg - Cur, {NextState, Beg, Count});
                false   -> update(event(Tm))
            end,
            {noreply, State}
    end;
handle_info({continue, Id}, State) ->
    case lookup(Id) of
        [] ->
            {noreply, State};
        [Tm] ->
            update(Tm),
            {noreply, State}
    end;
handle_info(_Request, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ets:delete(?GLOBAL_ETIMER).

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%私有函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
correct_mfa(Event) ->
    case not erlang:is_tuple(Event) orelse 3 =/= erlang:tuple_size(Event) of
        true ->
            none;
        false ->
            {M, F, A} = Event,
            case not erlang:function_exported(M, F, erlang:length(A)) of
                true    -> none;
                false   -> Event
            end 
    end.

insert(#timer{id = Id, server = Server, beg = Beg, afters = Afters, create = Create, ends = Ends, count = Count,
        node = Node, trigger = Trigger, close = Close, remove = Remove} = Tm, State) ->
    Flag1 = State#state.type =/= Node,
    Flag2 = [all] =/= Server andalso not lists:member(Server, State#state.id),
    Flag3 = [] =/= lookup(Id),

    if
        % 非当前结点事件
        Flag1                       ->
            invalid_node;
        % 非当前服务器事件
        Flag2                       ->
            invalid_server;
        % 已经有该事件
        Flag3                       ->
            false;
        true                        ->
            % 生成正确的起始时间
            CurTs = etime:time(),
            BegTs = etime:mktime(Beg),

            BegTs1 = if
                Create =/= 0    ->
                    CreateTs = case db:select_row(global_config, "val", [{id, 1}]) of
                        []      -> etime:time();
                        [Val]   -> erlang:list_to_integer(erlang:binary_to_list(Val))
                    end,
                    T1 = etime:localtime(BegTs),
                    T2 = etime:localtime(CreateTs + Create),
                    etime:mktime({{T2#tm.year, T2#tm.mon, T2#tm.mday}, {T1#tm.hour, T1#tm.min, T1#tm.sec}});
                Afters =/= 0    ->
                    case CurTs < BegTs of
                        true    -> BegTs + Afters - ?SECONDS_PER_DAY;
                        false   -> BegTs + Afters
                    end;
                true            ->
                    BegTs
            end,

            insert_internal(Tm#timer{
                    mbeg        = BegTs1,
                    mends       = etime:mktime(Ends),
                    mcount      = Count,
                    trigger     = correct_mfa(Trigger),
                    close       = correct_mfa(Close),
                    remove      = correct_mfa(Remove)
                })
    end.

insert_internal(#timer{mode = Mode, duration = Duration} = Tm) ->
    CurTs   = etime:time(),
    {PrevTs, _NextTs, _Count} = next_timestamp(0, CurTs, Tm),

    Tm1 = case ?MODE_TRIGGER =:= Mode andalso (CurTs - PrevTs < Duration orelse -1 =:= Duration) of
        true    -> event(Tm#timer{next_state = trigger});
        false   -> Tm
    end,
    update(Tm1).

update(#timer{duration = Duration, cur_state = CurState, close = Close} = Tm) ->
    CurTs   = etime:time(),
    {PrevTs, NextTs, Count} = next_timestamp(0, CurTs, Tm),

    if
        % 在启用触发函数并且关闭有效下启用关闭函数
        trigger =:= CurState andalso none =/= Close ->
            update_internal(Tm, erlang:max(Duration - (CurTs - PrevTs), 0), {close, NextTs, Count});
        % 启用触发函数
        0 =/= Count ->
            update_internal(Tm, NextTs - CurTs, {trigger, NextTs, Count});
        % 启用移除函数
        none =/= CurState ->
            update_internal(Tm, NextTs - CurTs, {remove, NextTs, Count});
        % 删除事件
        true ->
            delete(Tm),
            finished
    end.

update_internal(#timer{id = Id} = Tm, Time, {NextState, NextTs, Count}) ->
    case Time > ?SECONDS_30DAYS of
        true    ->
            Ref = erlang:send_after(1000 * ?SECONDS_30DAYS, self(), {continue, Id}),
            ets:insert(?GLOBAL_ETIMER, Tm#timer{ref = Ref});
        false   ->
            Ref = erlang:send_after(1000 * Time, self(), {event, Id}),
            ets:insert(?GLOBAL_ETIMER, Tm#timer{mbeg = NextTs, count = Count, next_state = NextState, ref = Ref})
    end.

delete(#timer{id = Id, ref = Ref}) ->
    case [] =:= lookup(Id) of
        true ->
            false;
        false ->
            cancel_timer(Ref),
            ets:delete(?GLOBAL_ETIMER, Id),
            true
    end.

cancel_timer(Ref) ->
    erlang:is_reference(Ref) andalso erlang:cancel_timer(Ref).

read_timer(Ref) ->
    case erlang:is_reference(Ref) andalso erlang:read_timer(Ref) of
        false       -> -1;
        Left        -> Left / 1000
    end.

event(#timer{next_state = NextState, trigger = Trigger, close = Close,
        remove = Remove} = Tm) ->
    Event = case NextState of
        trigger     -> Trigger;
        close       -> Close;
        remove      -> Remove
    end,
    erlang:spawn(fun() ->{M, F, A} = Event, erlang:apply(M, F, A) end),
    Tm#timer{cur_state = NextState}.

%% 返回值 {上次触发时间戳, 下次触发时间戳, 剩余次数(包括send_after触发在内)}
next_timestamp(PrevTs, CurTs, #timer{mbeg = BegTs, mends = EndsTs, mcount = Count}) when
CurTs > EndsTs orelse
BegTs > EndsTs orelse
Count =:= 0 ->
    {PrevTs, BegTs, 0};
next_timestamp(PrevTs, CurTs, #timer{mbeg = BegTs, interval = Interval, mcount = Count, duration = Duration} = Tm) ->
    if
        CurTs < BegTs   -> {PrevTs, BegTs, Count};
        -1 =:= Duration -> {PrevTs, 16#FFFFFFFF, Count - 1};

        -1 =:= Count    -> next_timestamp(BegTs, CurTs, Tm#timer{mbeg = BegTs + Interval});
        true            -> next_timestamp(BegTs, CurTs, Tm#timer{mbeg = BegTs + Interval, mcount = Count - 1})
    end.

%% node_world() ->
%%     [_, ServerId, _, _] = init:get_plain_arguments(),
%%     tool:to_atom(lists:concat([?WORLD_NODE, ServerId, ?NODE_HOST])).