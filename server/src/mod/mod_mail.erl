%%------------------------------------
%% @Module     : mod_mail
%% @Author     : 
%% @Created    : 2013.02.07
%% @Description: 信件服务
%%------------------------------------
-module(mod_mail).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, stop/0, send_sys_mail/4]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

%% 定时器1间隔时间: 邮件清理 (每4小时检查一次，如果检查时的时间为2:00~6:00，则执行信件清理)
-define(TIMER_1, 4*60*60*1000).

%% 定时器1间隔时间: 邮件清理 (清理一次之后，间隔24小时再清理)
-define(TIMER_2, 24*60*60*1000).

%%%------------------------------------
%%%  接口函数
%%%------------------------------------
%%启动邮件服务
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%发系统邮件
send_sys_mail(NameList, Title, Content, GoodsList) ->
    gen_server:cast(?MODULE, {'send_sys_mail', [NameList, Title, Content, GoodsList]}).

stop() ->
    gen_server:call(?MODULE, stop).

%%------------------------------------
%%             回调函数
%%------------------------------------
init([]) ->
    process_flag(trap_exit, true),    
    misc:write_monitor_pid(self(),?MODULE, {}),
    erlang:send_after(5*1000, self(), clean_overdure_mail), %%5秒钟后执行信件清理检查
    {ok, []}.

%%发系统信件
%%成功: true, 全部成功
%%      {false, Reason/错误名字列表}
handle_call({'send_mail', [NameList,Content, GoodsList]}, _From, State) ->
    Reply = lib_mail:send_mail(NameList, Content, GoodsList),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%% 发系统信件，不返回处理结果
handle_cast({'send_sys_mail', [NameList, Title, Content, GoodsList]}, State) ->
    lib_mail:send_sys_mail(NameList, Title, Content, GoodsList),
    {noreply, State};

handle_cast({'clean_mail'}, State) ->
    lib_mail:clean_old_time(),
    {noreplay, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 清理信件
handle_info(clean_overdure_mail, State) ->
    Now = util:unixtime(),
    Time = Now rem 86400,
    case Time >= 2*3600 andalso Time =< 6*3600 of %%在2点及6点之间
        true ->
            catch lib_mail:clean_old_mail(),
            erlang:send_after(?TIMER_2, self(), clean_overdure_mail);
        false ->
            erlang:send_after(?TIMER_1, self(), clean_overdure_mail)
    end,
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    misc:delete_monitor_pid(self()),
    ?TRACE("~s mod_mail terminated~n",[misc:time_format(now())]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
