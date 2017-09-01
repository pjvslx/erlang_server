%%---------------------------------------------
%% @Module      : robot_openfunc
%% @Author  	: smxx
%% @Created 	: 2013.03.01
%% @Description: 功能开放测试客户端
%%---------------------------------------------
-module(robot_openfunc).
-include("robot.hrl").
-compile(export_all).

handle(Status) ->
	%%通过-openfunc XX XX的gm指令来压
	Cmd = 11005,
	Type = 0,
	Content = "-openfunc 1 20",
	{ok, BinData} = ptr_11:write(Cmd, [0,Content]),
	gen_tcp:send(Status#robot.socket, BinData),
    Status.





