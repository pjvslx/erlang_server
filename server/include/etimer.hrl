-ifndef(ETIMER_HRL).
-define(ETIMER_HRL, 0). 

-record(
    timer,
    {
        %% 该区域参数为定时器事件不变的信息
        id          = 0     :: pos_integer(),       % 惟一标识
        name        = ""    :: string(),            % 描述
        server      = []    :: list(),              % 适用服务器
        beg         = 0     :: etime:time_fmt(),    % 开始时间字符串
        afters      = 0     :: integer(),           % 开服后多少天
        create      = 0     :: integer(),           % 新服务器启动多少天
        ends        = 0     :: etime:time_fmt(),    % 结束时间字符串
        interval    = 0     :: pos_integer(),       % 间隔
        count       = 0     :: integer(),           % 次数
        mode        = 0     :: 0 | 1,               % 启动方式
        duration    = 0     :: integer(),           % 有效时间, -1 表示无限时间
        node        = 0     :: 0 | 1,               % 结点 0 表示server 1 表示world
        trigger     = none  :: mfa() | none,        % 事件
        close       = none  :: mfa() | none,        % 停止事件
        remove      = none  :: mfa() | none,        % 移除事件

        %% 该区域信息在运行过程会修改
        mbeg        = 0     :: non_neg_integer(),   % 开始时间戳
        mends       = 0     :: non_neg_integer(),   % 结束时间戳
        mcount      = 0     :: integer(),           % 剩余次数
        cur_state   = none  :: etimer:timer_type(), % 当前定时器类型
        next_state  = none  :: etimer:timer_type(), % 下次定时器类型
        ref         = none  :: term()               % 定时器引用
    }). 

-endif. %ETIMER_HRL
