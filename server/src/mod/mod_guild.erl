%%%------------------------------------
%%% @Module  : mod_guild
%%% @Author  : water
%%% @Created : 2013.02.22
%%% @Description: 帮派处理 
%%%------------------------------------
-module(mod_guild).
-behaviour(gen_server).
-include("common.hrl").
-include("record.hrl").
-include("guild.hrl").
-include("debug.hrl").

-include_lib("stdlib/include/ms_transform.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%%=========================================================================
%% 一些定义
%%=========================================================================
-record(state, {worker_id = 0}).

%% 定时器1间隔时间
-define(TIMER, 60*1000).

%%帮派进程数量, 0为主进程,　只负责重启服务进程及定时器
-define(GUILD_WORKER_NUMBER, 5).

%%刷新时间 
%-define(GUILD_REFRESH_TIME, 60).
%%刷新时间 
%-define(GUILD_REFRESH_TIME, 24*3600).
-define(GUILD_REFRESH_TIME, 24*3600).
%%=========================================================================
%% 接口函数
%%=========================================================================
%% start_link([ProcessName, WorkerId]) ->
%%     gen_server:start_link({local, ?MODULE}, ?MODULE, [ProcessName, WorkerId], []).

start_link([WorkerId]) ->
    gen_server:start_link(?MODULE, [WorkerId], []).

start([WorkerId]) ->
    gen_server:start(?MODULE, [WorkerId], []).

stop() ->
    gen_server:call(?MODULE, stop).

%%启动帮派主进程(加锁保证全局唯一)
start_mod_guild() ->
    ProcessName = misc:create_process_name(guild_p, [0]),
    global:set_lock({ProcessName, node()}),    
    ProcessPid =
        case misc:whereis_name({local, ProcessName}) of
            Pid when is_pid(Pid) ->
                case misc:is_process_alive(Pid) of
                    true -> 
                        Pid;
                    false -> 
                        start_guild()
                end;
            _ ->
                start_guild()
        end,    
    global:del_lock({ProcessName, node()}),
    ProcessPid.

%%启动帮派监控树模块
start_guild() ->
    case supervisor:start_child(
               game_server_sup, {mod_guild,
                    {mod_guild, start_link,[[0]]},
                       permanent, 10000, supervisor, [mod_guild]}) of
        {ok, Pid} ->
            Pid;
        _ ->
            undefined
    end.

%%获取帮派主进程 
get_main_guild_pid() ->
    ProcessName = misc:create_process_name(guild_p, [0]),
    case misc:whereis_name({local, ProcessName}) of
            Pid when is_pid(Pid) ->
                case misc:is_process_alive(Pid) of
                    true ->
                        Pid;
                    false -> 
                        start_guild() 
                end;
            _ ->
                start_guild()
    end.

%%获取帮派服务进程 
get_guild_pid() ->
    get_guild_pid(0).
%%根据帮派获取服务进程,帮派唯一,避免冲突
get_guild_pid(GuildId) ->
    MainProcName = misc:create_process_name(guild_p, [0]),
    case misc:whereis_name({local, MainProcName}) of
            Pid when is_pid(Pid) ->
                case misc:is_process_alive(Pid) of
                    true ->
                        if GuildId =:= 0 ->
                            WorkerId = random:uniform(?GUILD_WORKER_NUMBER);
                        true ->
                            WorkerId = (GuildId rem ?GUILD_WORKER_NUMBER) + 1
                        end,
                        ProcessName = misc:create_process_name(guild_p, [WorkerId]),
                        case misc:whereis_name({local, ProcessName}) of
                            Pid1 when is_pid(Pid1) ->
                                Pid1;
                            _ ->
                                mod_guild:start_link([WorkerId])
                        end;
                    false ->  %%主进程挂了
                        ?TRACE("get_guild_pid  fail! AAA ~n"),
                        start_mod_guild(),
                        get_guild_pid(GuildId)
                end;
            _ ->  %%主进程挂了
                ?TRACE("get_guild_pid  fail! BBBB ~n"),
                start_mod_guild(),
                get_guild_pid(GuildId)
    end.

%%停服时回写申请表 
safe_quit() ->
    gen_server:cast(get_guild_pid(), {safe_quit}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([WorkerId]) ->
    ?TRACE("mode_guild init begin"),
    process_flag(trap_exit, true),
    %eprof:start_profiling([self()]),
    ProcessName = misc:create_process_name(guild_p, [WorkerId]),
    case misc:register(local, ProcessName, self()) of  %%多节点的情况下， 仅在一个节点启用帮派处理进程
        true ->
            if WorkerId =:= 0 ->    
                   %?TRACE("WorkerId =:= 0"),
                   ets:new(?ETS_GUILD, [{keypos,#guild.id}, named_table, public, set]),                   %%帮派
                   ets:new(?ETS_GUILD_MEMBER, [{keypos,#guild_member.uid}, named_table, public, set]),     %%帮派成员
                   ets:new(?ETS_GUILD_APPLY, [{keypos,#guild_apply.uid}, named_table, public, bag]),       %%帮派申请
                  
                   %%从数据库读数据，加到ETS
                   lib_guild:load_all_guild_to_ets(),
                   ?TRACE("[debug]mod_guild init load_all_guild_to_ets success ~n"),
                   lib_guild:load_all_guild_member_to_ets(),
                   %?TRACE("[debug]mod_guild init load_all_guild_member_to_ets success ~n"),
                   lib_guild:load_all_guild_apply_to_ets(),
                    %?TRACE("[debug]mod_guild init load_all_guild_apply_to_ets success ~n"),
                   %% 定时处理
                   %%erlang:send_after(?TIMER, self(), timer),
				   
				   %%开启定时器，到时间时刷新帮派状态
				   TimeLeft = 24*60*60 - util:get_today_current_second() ,

 				   %TimeLeft = ?GUILD_REFRESH_TIME ,%test 10min refresh

			       ClearTimer = erlang:send_after(TimeLeft * 1000, self(), {'refresh_guild'}) ,

			       put(refresh_guild_timer,ClearTimer) ,

                   misc:write_monitor_pid(self(), ?MODULE, {0}),
                   misc:write_system_info(self(), ?MODULE, {0}),

                   %% 启动帮派的服务进程, 间接由监控树管理
                   lists:foreach(fun(WkerId) -> mod_guild:start_link([WkerId]) end, lists:seq(1, ?GUILD_WORKER_NUMBER));            
               true -> 
                     misc:write_monitor_pid(self(), mod_guild, {WorkerId})
            end,
            State= #state{worker_id = WorkerId},
            ?TRACE("mode_guild init CCCCCCCCCCCC ~p ~n",[State]),
            {ok, State};
        _ ->
            ?ERROR_MSG("guild register failed: ~p~n", [WorkerId]),
            {stop,normal,#state{}}
    end.
        
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, State) ->

    Reply  = ?APPLY(Module, Method, Args,[]),
%%     case (catch apply(Module, Method, Args)) of
%%          {'EXIT', Info} ->    
%%              ?ERROR_MSG("mod_guild apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method,Info]),
%%              error;
%%          DataRet -> DataRet
%%     end,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, State, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 统一模块+过程调用(cast)
handle_cast({apply_cast, Module, Method, Args}, State) ->
%%     case (catch apply(Module, Method, Args)) of
%%          {'EXIT', Info} ->    
%%              ?WARNING_MSG("mod_guild apply_cast error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
%%              error;
%%          _ -> ok
%%     end,
	F = fun(ErrMsg)->
				?WARNING_MSG("mod_guild apply_cast error: Module=~p, Method=~p, Reason=~p",[Module, Method, ErrMsg])
		end,
	?APPLY(Module, Method, Args,F),
    {noreply, State};

%%停服时操作
handle_cast({safe_quit}, State) ->
    spawn(fun() -> safe_quit() end),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({'refresh_guild'}, State) ->
   	%%先清除定时器

	?TRACE("handle_info refresh_guild = ~p ~n",[util:get_today_current_second()]),%%log

    misc:cancel_timer(refresh_guild_timer) ,
    handle_timer_action(),
    
    Time = ?GUILD_REFRESH_TIME,
    %%Time = 24*60*60,
    ClearTimer = erlang:send_after(Time * 1000, self(), {'refresh_guild'}) ,
   %%ClearTimer = erlang:send_after(5 * 1000, self(), {'refresh_guild'}) , %% test: 5s refresh

	put(refresh_guild_timer,ClearTimer) ,

    {noreply, State};


handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
    misc:delete_monitor_pid(self()),
    if State#state.worker_id =:= 0 ->
        misc:delete_system_info(self());
    true ->
        skip
    end,
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% -----------------------------------------------------------------
%% 定时处理事务
%% -----------------------------------------------------------------
handle_timer_action() ->
    %%每天0点清理帮派申请
    %%回写帮派数据
    %Now = util:unixtime(),
    %lib_guild:delete_guild_all_apply(),
    %lib_guild:delete_guild_log().
	?TRACE("handle_timer_action begin"),
	%%消耗费用
    refresh_guild_cost(),
	
	%%刷新排名和职位
	refresh_guild_members(),
	?TRACE("handle_timer_action end"),
    skip.

%%消耗费用
refresh_guild_cost() ->
?TRACE("---------------------------------------------~n"),
	F = fun(GuildInfo)->
		CostADay = data_guild:get_maintain_cost_a_day(GuildInfo#guild.level),%每日维护费用
		GuildFund= GuildInfo#guild.fund,%帮派资金
        DebtCnt  = GuildInfo#guild.debt_count,%欠费天数
		MaxDebt  = data_guild:get_guild_config(max_debt_days),%%最大欠费天数
		GuildId  = GuildInfo#guild.id,
		NewFund  = GuildFund - CostADay ,
        ?TRACE("fun(GuildInfo)   CostADay=~p Fund=~p DebtCnt=~p MaxDebt=~p GuildId=~p NewFund=~p ~n" , [CostADay, GuildFund,DebtCnt, MaxDebt, GuildId, NewFund]),
		case NewFund >= 0 of
			true -> %%帮派资金足够
                ?TRACE("new fund = ~p    GuildInfo = ~p ~n", [NewFund,GuildInfo#guild.id]),

                NewGuildInfo = GuildInfo#guild{fund = NewFund, debt_count = 0},
				db_agent_guild:update_guild_fund(NewGuildInfo,NewFund),
			    db_agent_guild:update_guild_debt_count(NewGuildInfo,0);%%欠费天数置0

			false ->%%帮派资金不够
				case DebtCnt + 1 > MaxDebt of
						true -> %%解散帮派
                            ?TRACE("disband_guild  guild_id = ~p ~n " , [GuildInfo#guild.id]),
							lib_guild:disband_guild(GuildInfo#guild.id);
						false ->
                             ?TRACE("send_mail guildId = ~p ~n" , [GuildInfo#guild.id]),
                            guild_util:send_mail(GuildInfo,DebtCnt),%%按剩余天数发邮件
							db_agent_guild:update_guild_debt_count(GuildInfo,DebtCnt +1)
               end
        end
	end,
	GuildList = db_agent_guild:get_all_guild_from_ets() ,

	lists:map(F,GuildList).
 
%% 刷新成员列表 ，刷新职位
refresh_guild_members()  -> 
    %帮派列表
    F = fun(GuildInfo) ->
        guild_util:refresh_members_position(GuildInfo)  
    end,
	GuildList = db_agent_guild:get_all_guild_from_ets() ,
    %?TRACE("[debug]refresh_guild_members GuildList=  ~p  ~n ", [GuildList]),
    lists:map(F,GuildList).




%% -----------------------------------------------------------------
%% 停服时回写申请到数据库
%% -----------------------------------------------------------------
handle_safe_quit() ->
    ApplyList = ets:tab2list(?ETS_GUILD_APPLY),
    lists:foreach(fun(X) -> db_agent_guild:insert_apply(X) end, ApplyList).

%%测试函数检查服务进程
check_proc() ->
    F = fun(WorkerId) ->
        ProcessName = misc:create_process_name(guild_p, [WorkerId]),
        case misc:whereis_name({local, ProcessName}) of
                Pid when is_pid(Pid) ->
%%                     case misc:is_process_alive(Pid) of
%%                         true ->
%% 							
%%                          _ ->
%%                     end;
						skip ;
                _Error ->
                    skip
       end
   end,
   lists:foreach(F,  [0|lists:seq(1, ?GUILD_WORKER_NUMBER)]).

%%帮会贡献
add_contribution(PlayerStatus,Gold,Coin) ->
    Gid = PlayerStatus#player.guild_id,
    NewPlayerStatus = gen_server:call(mod_guild:get_guild_pid(Gid), {apply_call, lib_guild, add_contribution, [PlayerStatus,Gid,Gold,Coin]}) ,
    {ok,NewPlayerStatus}.
