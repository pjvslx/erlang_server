%%%------------------------------------
%%% @Author  : 
%%% @Created : 2010.09.27
%%% @Description: 坐骑处理
%%%------------------------------------
-module(robot_mount).
-include("robot.hrl").
-compile(export_all).

handle(Status) ->
	RandNum = util:rand(1,3),
	if
		RandNum == 1 ->
			upgrade_mount_star(Status);
		RandNum == 2 ->
			upgrade_mount_level(Status);
		RandNum == 3 ->
			upgrade_mount_skill(Status);
		true ->
			skip
	end,
	Status.

upgrade_mount_star(Status) ->
	Cmd = 44006,
	AutoBuy = 1,
	BatchUpgrade = 1,
	{ok, BinData} = ptr_44:write(Cmd, [AutoBuy,BatchUpgrade]),
	gen_tcp:send(Status#robot.socket, BinData),
    Status.

upgrade_mount_level(Status) ->
	Cmd = 44007,
	AutoBuy = 1,
	{ok, BinData} = ptr_44:write(Cmd, [AutoBuy]),
	gen_tcp:send(Status#robot.socket, BinData),
	Status.

upgrade_mount_skill(Status) ->
	Cmd = 44001,
	UpgradeType = 1,
	{ok, BinData} = ptr_44:write(Cmd,[UpgradeType]),
	gen_tcp:send(Status#robot.socket, BinData),
	Status.