%%%-----------------------------------
%%% @Module  : game_server
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 游戏服务器
%%%-----------------------------------
-module(game_server).
-export([start/1]).
-compile([export_all]).

-include("common.hrl").

%% -define(INFO_MSG(Str), error_logger:info_msg(Str)).
%% -define(INFO_MSG(Str, Args), error_logger:info_msg(Str, Args)).

start([Ip, Port, ServerId, Gateways, LogPath, LogLevel,DbLogPath]) ->
	%% 开启系统日志  
	start_sys_log(LogPath, LogLevel),
	?INFO_MSG("~s start initing server ~p...\n", [misc:time_format(now()), ServerId]),
	
    misc:write_system_info(self(), tcp_listener, {Ip, Port, now()}),
    inets:start(),
    ok = start_kernel(),                        %%开启核心服务
    ok = start_rand(),                            %%随机种子
    
    %% ok = start_npc(),                        %%开启npc监控树
    %%ok = start_npc(),                         %%开启npc监控树
    ok = start_client(),                        %%开启客户端连接监控树
    ok = start_mail(),                          %%开启邮件监控树
    ok = start_tcp(Port),                       %%开启tcp listener监控树
    ok = start_scene(),                         %%开启本节点场景(按照配置文件)        
    ok = start_scene_agent(),                   %%开启场景代理监控树
    %%     ok = start_mon(),                    %%开启怪物监控树
    ok = start_db_log(DbLogPath),					%%开启数据库日志监控树
    ok = start_world_level(),                   %%World Level
    ok = start_goods(),
    ok = start_shop(),
    ok = start_market(),
	ok = start_rank(),							%% 开启排行榜监控树
    ok = start_disperse([Ip, Port, ServerId, Gateways]),    %%开启服务器路由，连接其他节点    
    timer:sleep(1000),
    
    %%开启杂项监控树
    ok = start_misc(),
    %%开启帮派监控树    
    ok = start_guild(),
	ok = start_boss(),

	ok = start_dungeon_master(), 

    %%开启组队主进程
    ok = start_team(),
	
	%%天道令模块进程
	ok = start_heaven(),

	?INFO_MSG("~s initing end server ~p...\n", [misc:time_format(now()), ServerId]),
    ok. 

%%开启核心服务
start_kernel() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_kernel,
                {mod_kernel, start_link,[]},
                permanent, 10000, supervisor, [mod_kernel]}),
    ok.

%%随机种子
start_rand() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_rand,
                {mod_rand, start_link,[]},
                permanent, 10000, supervisor, [mod_rand]}),
    ok.


%%开启怪物监控树
start_mon() ->
    {ok, _} = supervisor:start_child(
                game_server_sup,
                {mod_mon_create,
                 {mod_mon_create, start_link,[]},
                 permanent, 10000, supervisor, [mod_mon_create]}),
    ok.

%%开启npc监控树
%% start_npc() ->
%%     {ok,_} = supervisor:start_child(
%%                game_server_sup,
%%                {mod_npc_create,
%%                 {mod_npc_create, start_link,[]},
%%                 permanent, 10000, supervisor, [mod_npc_create]}),
%%     ok.

%%开启任务监控树
start_task() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_task_cache,
                {mod_task_cache, start_link,[]},
                permanent, 10000, supervisor, [mod_task_cache]}),
    ok.

%%开启联盟监控树
start_guild() ->
    Pid = mod_guild:start_mod_guild(),
    ?INFO_MSG("~s mod_guild is started, pid: ~p...\n", [misc:time_format(now()), Pid]),
    ok.

%%开启邮件监控树
start_mail() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_mail,
                {mod_mail, start_link,[]},
                permanent, 10000, supervisor, [mod_mail]}),
    ok.

start_notice() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_notice,
                {mod_notice, start_link,[]},
                permanent, 10000, supervisor, [start_notice]}),
    ok.

%%开启杂项监控树
start_misc() ->
    {ok, _} = supervisor:start_child(
           		game_server_sup, {mod_misc,
                    {mod_misc, start_link,[]},
                       permanent, 10000, supervisor, [mod_misc]}),
	ok.

%%
start_world_level() ->
    lib_world_level:startup(),
    ok.

%% %%开启在线统计监控树
%% start_online_count()->
%%     _Pid = mod_online_count:get_mod_online_count_pid(),
%%     ok.
start_db_log(LogPath) -> 
    {ok, _} = supervisor:start_child(
           		game_server_sup, {mod_db_log,
                    {mod_db_log, start_link,[LogPath]},
                       permanent, 10000, supervisor, [mod_db_log]}),
	ok.

%% 开启本节点场景(按照配置文件，以及节点ID)
start_scene() ->
    lists:foreach(fun(SId)->
                          mod_scene:start_scene_by_baseId(SId, 0)
                  end, 
                  config:get_scene_here(server)),
    ok.

%%开启场景代理监控树
start_scene_agent() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_scene_agent,
                {mod_scene_agent, start_link, [{mod_scene_agent, 0}]},
                permanent, 10000, supervisor, [mod_scene_agent]}),
    ok.



%% %% 开启副本掉落统计控制树
%% start_dungeon_analytics() ->
%%     _Pid = mod_dungeon_analytics:get_mod_dungeon_analytics_pid(),
%%     ok.

%% %%开启VIP监控树
%% start_vip()->
%%     _Pid = mod_vip:get_mod_vip_pid(),
%%     ok.

%%开启客户端监控树
start_client() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {game_tcp_client_sup,
                {game_tcp_client_sup, start_link,[]},
                transient, infinity, supervisor, [game_tcp_client_sup]}),
    ok.

%%开启tcp listener监控树
start_tcp(Port) ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {game_tcp_listener_sup,
                {game_tcp_listener_sup, start_link, [Port]},
                transient, infinity, supervisor, [game_tcp_listener_sup]}),
    ok.

%%开启多线
start_disperse([Ip, Port, ServId,Gateways]) ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_disperse,
                {mod_disperse, start_link,[Ip, Port, ServId, Gateways]},
                permanent, 10000, supervisor, [mod_disperse]}),
    ok.

%%开启组队功能
start_team() ->
    {ok, Pid} = mod_team:start_team(),
    ?INFO_MSG("~s mod_team is started, pid: ~p...\n", [misc:time_format(now()), Pid]),
    ok.

%%世界BOSS
start_boss() ->
    %% boss 主进程
    _Pid = mod_boss:get_mod_boss_pid(),
    ok.

start_dungeon_master() ->
	_Pid = mod_dungeon_master:get_mod_dungeon_master_pid(),
    ok.
 

start_statistics() ->
    {ok, _Pid} = mod_statistics:start(),
    ok.

%% 开启排行榜监控树
start_rank() ->
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {mod_rank,
                {mod_rank, start_link,[]},
                permanent, 10000, supervisor, [mod_rank]}),
    ok.

%% desc: 物品ets表管理
start_goods() ->
    {ok, _} = supervisor:start_child(
                game_server_sup, 
                {mod_goods_l,
                 {mod_goods_l, start_link, []},
                 permanent, 10000, supervisor, [mod_goods_l]}),
    ok.

%% 开启商城监控树
start_shop() ->
    {ok, _} = supervisor:start_child(
                game_server_sup, 
                {  mod_shop,
                   {mod_shop, start_link, []},
                   permanent, 10000, supervisor, [mod_shop]}),
    ok.

%% 开启市场交易系统监控树
start_market() ->
	_Pid = mod_market:get_mod_market_pid(),
    ok. 

%%开启天道令模块
start_heaven()->
	mod_heaven:start_all_heaven(),
    %?INFO_MSG("~s mod_heaven is started, pid: ~p...\n", [misc:time_format(now()), Pid]),
    ok.

%% 开启系统日志
%% start_sys_log(Log_file, Log_level) ->
%% 	LogDir = lists:concat(["logs/log_", ServerId]),
%% 	file:make_dir(LogDir),
%% 	util:set_error_logger_mf_dir(ServerId),
%% 	sm_logger_sup:start_link([lists:concat([LogDir, "/log"]), config:get_log_level()]).
start_sys_log(LogPath, LogLevel) ->
	case filelib:is_dir(LogPath) of
		true -> skip;
		false ->	file:make_dir(LogPath)
	end,
	
    {ok,_} = supervisor:start_child(
               game_server_sup,
               {?LOGMODULE,
                {logger_h, start_link, [lists:concat([LogPath, "/log"]), LogLevel]},
                permanent, 5000, worker, dynamic}),
    ok.
