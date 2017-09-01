%% Author: Administrator
%% Created: 2013-9-16
%% Description: TODO: Add description to robot_goods
-module(robot_goods).
-behaviour(gen_server).

%%
%% Include files
%%
-include("robot.hrl").
%%
%% Exported Functions
%%
-compile(export_all).
%% -export([]).

%%
%% API Functions
%%

%% 开始机器人逻辑，RS = RobotStatus #robot
start_robot_test(RS) ->
	io:format("**********20130916 robot_goods start_robot_test~n"),
	handle(15000, RS),
	handle(15002, RS#robot.socket),
	handle(15003, RS#robot.socket),
	handle(15004, RS),
	ok.

%% 查询物品详细信息
handle(15000, RS) ->
	?TRACE("**********20130916 robot_goods 15000 handle~n"),
	Id = RS#robot.id,
	gen_tcp:send(RS#robot.socket, pack(15000, <<Id:64>>)),
	ok;

%% 测试背包物品获取
handle(15002, Socket) ->
	?TRACE("**********20130916 robot_goods 15002 handle~n"),
	gen_tcp:send(Socket, pack(15002, <<0:8>>)),
	ok;

%% 扩充背包
handle(15003, Socket) ->
	?TRACE("**********20130916 robot_goods 15003 handle~n"),
	gen_tcp:send(Socket, pack(15003, <<0:8, 1:8>>)),
	ok;

%% 背包内拖动物品
handle(15004, RS) ->
	?TRACE("**********20130916 robot_goods 15004 handle~n"),
	gen_tcp:send(RS#robot.socket, pack(15004, <<123:64, 1:16, 2:16>>)),
	ok.



%%
%% Local Functions
%%

pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
