%%---------------------------------------------
%% @Module      : robot_mail
%% @Author  	: smxx
%% @Created 	: 2013.09.13
%% @Description: 邮件功能测试客户端
%%---------------------------------------------
-module(robot_mail).
-include("robot.hrl").
-compile(export_all).

handle(Status) ->
	%%因为发邮件不是用户请求协议触发的  所以要靠gm指令来压
	Cmd = 11005,
	Type = 0,
	Content = "-mail 1",
	{ok, BinData} = ptr_11:write(Cmd, [0,Content]),
	gen_tcp:send(Status#robot.socket, BinData),
    Status.





