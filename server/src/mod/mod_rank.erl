%%%------------------------------------
%%% @Module     : mod_rank
%%% @Author     : 
%%% @Email      : 
%%% @Created    :
%%% @Description: 排行榜
%%%------------------------------------
-module(mod_rank). 
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-compile(export_all).

-include("common.hrl").
-include("record.hrl").
-include("rank.hrl").
-include("debug.hrl").
-include("goods.hrl").

%%%------------------------------------
%%%             接口函数
%%%------------------------------------

start_link() ->      %% 启动服务
   gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%------------------------------------
%%%             回调函数
%%%------------------------------------
init(_) ->
    process_flag(trap_exit, true), 
    % 初始化榜单  
    do_init_rank_data(), 
	
	catch misc:unregister({local, ?RANK_PID}) ,
	
    misc:register(local, ?RANK_PID, self()),
    % 开启定时器
  %  timer_start(),
    {ok, []}.

%% desc: 刷新排行榜榜信息(每天刷新2次)
handle_info('REFRESH_RANK', State) ->  
	try
		do_init_rank_data()
	catch
		_:ErrReason->
			?ERROR_MSG("REFRESH_RANK error ~w ~n",[ErrReason]) 
	end,
	{noreply, State};

%% desc: 错误处理
handle_info(_Msg, State) ->
    {noreply, State}.

%%重新刷新排行榜
handle_call({reset_all_rank}, _From, StateData) -> 
	try
		do_init_rank_data()
	catch
		_:ErrReason->
			?ERROR_MSG("REFRESH_RANK error ~w ~n",[ErrReason]) 
	end,
    {reply, ok, StateData};
handle_call(_Event, _From, StateData) ->
    {reply, ok, StateData}.
   
%%获取排行榜信息（通用）
handle_cast({'GET_RANK_INFO',Ps,Flag,Type}, StateData) ->  
	Result =case Flag of
				?SELF_INFO_RANK -> 
					rank_util:get_self_rank_info(Type,Ps);
				?OTHER_INFO_RANK ->
					lib_rank:filter_rank_info(Type);
				_->
					[]
			end,
	pack_and_send(Ps, 50001, [Flag,Type,Result]),
	{noreply, StateData};

handle_cast(restart,StateData)-> 
  %清空yesterday_flower表的数据
  ?DB_MODULE:delete("yesterday_flower",[]),
  {stop, normal, StateData};  

handle_cast(_Event, StateData) ->
    {noreply, StateData}.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Any, _Opts) -> 
    ok. 
 
%% desc: 初始化榜单数据
do_init_rank_data() -> 
    lists:foreach(fun rank_util:refresh_rank_lists/1, [?RANK_PERSONAL_ALL, ?RANK_EQUIP_ALL, ?RANK_MOUNT_ALL, 
												 ?RANK_PET_ALL, ?RANK_SPIRIT_ALL, ?RANK_GUILD_ALL,?RANK_CHARM_ALL, 
												 ?RANK_DUNGEON_ALL, ?RANK_CHARM_ALL]).

%% desc: 开启定时器
timer_start() -> 
    self() ! 'REFRESH_RANK'.


pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_50:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).