%%%------------------------------------
%%% @Module     : mod_misc
%%% @Author     : 
%%% @Created    :
%%% @Description: 杂项处理进程
%%%------------------------------------
-module(mod_misc).
-behaviour(gen_server).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-define(INIT_ACCOUNCE,2).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 定时器间隔时间(每24小时,单位 秒)
-define(TIMER, 24*3600).

%% 定时器2间隔时间(每24小时,单位 毫秒) 
-define(DAY_TIMER, 24*3600*1000).

%% 杂项处理进程信息表    
-record(state, {}).

start_link() -> %%启动服务
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->   
	process_flag(trap_exit, true),	
	misc:write_monitor_pid(self(),?MODULE, {}),
	misc:write_system_info(self(), mod_misc, {}),  

	%% 系统公告 ，不需要游戏实现，只需要实现跟平台对接的接口
	%%ets:new(?ETS_SYS_ANNONUCE, [named_table, public, set, {keypos,#sys_announce.id}]),
	%%lib_misc:load_announce() ,
	%%AnnounceTimer = erlang:send_after(?INIT_ACCOUNCE * 1000, self(), {next_sys_annonuce,[]}),
	%%put(annonuce_timer, AnnounceTimer) ,
	
	State = #state{},
	% 开启在线日志定时器
	erlang:send_after(60 * 1000, self(), 'REFRESH_ONLINE_LOG'),    % 延迟1分钟
	% 开启每天1次统计日志定时器
	erlang:send_after(3*60 * 1000, self(), 'REFRESH_DAY_LOG'),    % 延迟3分钟

	Now = util:unixtime(),
	{Todaymidnight,_} = util:get_midnight_seconds(Now),								%得到今天零时时间
	CostSec = Now - Todaymidnight,													%%今天已过时间
 	%% 半夜十二点通知客户端
	erlang:send_after(?DAY_TIMER - CostSec*1000, self(), midnight),
	erlang:send_after(?DAY_TIMER - CostSec*1000-1000, self(), reflesh_rank),	%%刷新排行榜
	{ok, State}.

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
	F  =fun(ErrMsg)->
				 ?WARNING_MSG("mod_misc__apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, ErrMsg])
				 end,
    Reply  = 	?APPLY(Module, Method, Args,F),
%%     case (catch apply(Module, Method, Args)) of
%%          {'EXIT', Info} ->    
%%              ?WARNING_MSG("mod_misc__apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
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
	F = fun(ErrMsg)->
				?WARNING_MSG("mod_misc__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, ErrMsg])
		end,
		?APPLY(Module, Method, Args,F),
%%     case (catch apply(Module, Method, Args)) of
%%          {'EXIT', Info} ->    
%%              ?WARNING_MSG("mod_misc__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%%              error;
%%          _ -> ok
%%     end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 半夜十二点处理  
handle_info(midnight, State) -> 
    erlang:send_after(?DAY_TIMER, self(), midnight), 
	  erlang:send_after(?DAY_TIMER-1000, self(), reflesh_rank), 
    spawn(fun() -> notice_midnight() end),  
    {noreply, State};
handle_info(reflesh_rank, State) ->   
	gen_server:cast(rank_util:get_rank_pid(), restart), 
    {noreply, State}; 
handle_info('REFRESH_ONLINE_LOG', State) ->
	erlang:send_after(60 * 1000*5 , self(), 'REFRESH_ONLINE_LOG'),
	OnlineNum =
		case ets:info(?ETS_ONLINE, size) of
			undefined -> 0;
			Num -> Num
		end,  
	spawn(fun()->db_agent_log:insert_log_online(OnlineNum) end),
	{noreply, State};

handle_info('REFRESH_DAY_LOG', State) ->
    NexTime = util:get_now_to_next_hour(),
    erlang:send_after((NexTime + 60) * 1000, self(), 'REFRESH_DAY_LOG'),    % 延迟1分钟
    {H, _, _} = time(),
    if        
        H =:= 3 ->
			start_log_level(),
			start_log_activity();			
        true ->
            skip
    end,
    {noreply, State};


%% system announcement
handle_info({next_sys_annonuce, AnnRcd}, State) ->
	misc:cancel_timer(annonuce_timer),
	NowTime = util:unixtime() ,
	case lib_misc:get_current_announce(AnnRcd,NowTime) of
		NewAnnRcd when is_record(NewAnnRcd,?ETS_SYS_ANNONUCE) andalso NewAnnRcd#?ETS_SYS_ANNONUCE.type > 0 ->
			lib_misc:update_annonuce(NewAnnRcd,NowTime) ,
			{ok, BinData} = pt_11:write(11010, [NewAnnRcd#?ETS_SYS_ANNONUCE.type,NewAnnRcd#?ETS_SYS_ANNONUCE.content]) ,
			lib_send:send_to_all(BinData) ,
			{NextAnnRcd, NextTime} = lib_misc:get_next_announce(NowTime) ;
		_ ->
			NextAnnRcd = [] ,
			NextTime = ?INIT_ACCOUNCE * 5   %% 延迟2分钟
	end ,
	AnnounceTimer = erlang:send_after(NextTime*1000, self(), {next_sys_annonuce, NextAnnRcd}) ,
	put(annonuce_timer, AnnounceTimer) ,
	{noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    misc:delete_monitor_pid(self()),
    misc:delete_system_info(self()),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


get_mod_misc_pid() ->
  misc:whereis_name({local,mod_misc}).

%%=========================================================================
%% 业务处理函数
%%=========================================================================
notice_midnight() -> 
    UserList = ets:tab2list(?ETS_ONLINE),
    F = fun(User) ->
         case misc:is_process_alive(User#player.other#player_other.pid) of
             true  ->
                 gen_server:cast(User#player.other#player_other.pid, midnight);
             false -> skip
         end
    end,
    lists:foreach(F, UserList).

%% 等级日志
start_log_level() ->
	case db_agent_player:get_player_level_info() of
		[] -> skip;
		InfoList ->
			F = fun([Lv, Num]) ->				
				spawn(fun()->db_agent_log:insert_log_level(Num, Lv) end)
			end,
			lists:foreach(F, InfoList)
	end.

load_sys_announce(AnnId) ->
	try
		gen_server:cast(get_mod_misc_pid(), {apply_cast, lib_misc, load_announce, [AnnId]})
	catch
		_:_Reason ->
			skip
	end.

%% 功能参与度日志
start_log_activity() ->
	ok.
