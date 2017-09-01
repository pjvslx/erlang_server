%% Author: Administrator
%% Created: 2013-4-8
%% Description: TODO: Add description to local_gateway_sup
-module(local_gateway_sup).
-behaviour(supervisor).
-export([start_link/1, init/1]).

-include("common.hrl").

start_link([Port, LogFile, LogLevel]) ->
	supervisor:start_link({local,?MODULE}, ?MODULE, [Port, LogFile, LogLevel]).

init([Port, LogFile, LogLevel]) ->
    {ok,
        {
            {one_for_one, 3, 10},
            [
			 	{
                    mod_gateway_kernel,
                    {mod_gateway_kernel, start_link, []},
                    permanent,
                    10000,
                    worker,
                    [mod_gateway_kernel]
                },
                {
                    local_gateway,
                    {local_gateway, start_link, [Port]},
                    permanent,
                    10000,
                    worker,
                    [local_gateway]
                },
				{
				 	?LOGMODULE, 
					{logger_h, start_link, [LogFile, LogLevel]}, 
					permanent, 
					5000, 
					worker, 
					dynamic
				}
            ]
        }
    }.