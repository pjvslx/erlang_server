%% Author: Administrator
%% Created: 2012-4-17
%% Description: TODO: Add description to pt_32
-module(pt_32).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([read/2, write/2]).

%%
%% API Functions
%%


%% 激活
read(32001, <<Id:32, SLv1:8, SLv2:8>>) -> 
	{ok, [Id, SLv1, SLv2]};

%% 渡劫
read(32002, <<Id:32, CrLv:16>>) -> 
	{ok, [Id, CrLv]};

%% 查询
read(32003, _R) -> 
	{ok, []};

%% 五行珠仓储信息
read(32020, _R) -> 
	{ok, []};

%% 五行珠装备情况
read(32021, <<RoleId:32,RoleType:8>>) -> 
	{ok, [RoleId,RoleType]};

%% 重铸次数
read(32022, _R) -> 
	{ok, []};


%% 卸载五行珠
read(32023, <<BeadId:32>>) -> 
	{ok, [BeadId]};


%% 装备五行珠 
read(32024, <<BeadId:32,RoleId:32,RoleType:8>>) -> 
	{ok, [BeadId,RoleId,RoleType]};

%% 卖出五行珠 
read(32025,<<BeadId:32>>) -> 
	{ok, [BeadId]};

%% 刻印五行珠 
read(32026, <<BeadId:32>>) -> 
	{ok, [BeadId]};

%% 锁定属性 
read(32027,<<BeadId:32,Bin/binary>>) -> 
    {AttrName, <<Lock:8>>} = pt:read_string(Bin),
	{ok, [BeadId,util:string_to_term(AttrName),Lock]};

%% 五行珠重铸
read(32028,<<BeadId:32,Type:8>>) ->
	{ok, [BeadId,Type]};

%% 五行珠重铸前后属性查询
read(32029,<<BeadId:32,RoleId:32,RoleType:8>>) ->
	{ok, [BeadId,RoleId,RoleType]};

%% 五行珠装备情况
read(32031, <<RoleId:32,RoleType:8>>) -> 
	{ok, [RoleId,RoleType]};

%% 五行珠装备情况
read(32032, <<UId:32,RoleId:32,RoleType:8>>) -> 
	{ok, [UId,RoleId,RoleType]};


read(_Arg0, _Arg1) -> 
	ok.

write(32001, [Ret, Id, NewSLv1, NewSLv2, _Soul]) ->
	Data = <<Ret:8, Id:32, NewSLv1:8, NewSLv2:8>>,
    {ok, pt:pack(32001, Data)};

write(32002, [Ret, Id, NewCrLv]) ->
	Data = <<Ret:8, Id:32, NewCrLv:16>>,
    {ok, pt:pack(32002, Data)};

write(32003, [Soul]) ->
	Data = <<Soul:32>>,
    {ok, pt:pack(32003, Data)};	



%% 五行珠仓储信息
write(32020, [BeadRcdList]) -> 
	Len = length(BeadRcdList) ,
	F = fun({BeadId,BeadType,GoodsTypeID,BeadStep,AttrList}) ->
				AttrLen = length(AttrList) ,
				FA = fun({AttrName,AttrValue,AttrQlt,Lock,MinValue,MaxValue}) ->
							 {NMLen,NMBin} = tool:pack_string(AttrName) ,
							 <<NMLen:16,NMBin/binary,AttrValue:32,AttrQlt:8,Lock:8,MinValue:32,MaxValue:32>>
					 end ,
				AttrBin = tool:to_binary([FA(A) || A <- AttrList]) ,
				<<BeadId:32,BeadType:8,GoodsTypeID:32,BeadStep:8,AttrLen:16,AttrBin/binary>>
		end ,
	RB = tool:to_binary([F(D) || D <- BeadRcdList]) ,
	Data = <<Len:16,RB/binary>> ,
	{ok, pt:pack(32020, Data)};


%% 角色装备五行珠情况查询
write(32021, [DataList]) -> 
	Len = length(DataList) ,
	F = fun({BeadId,BeadType,GoodsTypeId,BeadStep,CanUp,AttrList}) ->
				AttrLen = length(AttrList) ,
				FA = fun({AttrName,AttrValue,AttrQlt,Lock,MinValue,MaxValue}) ->
							 {NMLen,NMBin} = tool:pack_string(AttrName) ,
							 <<NMLen:16,NMBin/binary,AttrValue:32,AttrQlt:8,Lock:8,MinValue:32,MaxValue:32>>
					 end ,
				AttrBin = tool:to_binary([FA(A) || A <- AttrList]) ,
				<<BeadId:32,BeadType:8,GoodsTypeId:32,BeadStep:8,CanUp:8,AttrLen:16,AttrBin/binary>> 
		end ,
	RB = tool:to_binary([F(D) || D <- DataList]) ,
	Data = <<Len:16,RB/binary>> ,
	{ok, pt:pack(32021, Data)};



%% 重铸次数
write(32022, [Times]) ->
	Data = <<Times:8>>,
    {ok, pt:pack(32022, Data)};	


%% 卸载五行珠
write(32023, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(32023, Data)};	


%% 装备五行珠
write(32024, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(32024, Data)};	


%% 卖出五行珠
write(32025, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(32025, Data)};	


%% 五行珠刻印
%% write(32026, [Code,Name,Value,Qlty,Lock]) ->
%% 	{NMLen,NMBin} = tool:pack_string(Name) ,
%% 	Data = <<Code:8,NMLen:16,NMBin/binary,Value:32,Qlty:8,Lock:8>> ,
%%     {ok, pt:pack(32026, Data)};	
write(32026, [Code]) ->
	Data = <<Code:8>> ,
    {ok, pt:pack(32026, Data)};	


%% 锁定五行珠属性
write(32027, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(32027, Data)};	

%% 五行珠重铸
write(32028, [Code]) ->
	Data = <<Code:8>> ,
    {ok, pt:pack(32028, Data)};	

%% 五行珠重铸
write(32029, [Code,NAttrList]) ->
	NLen = length(NAttrList) ,
	F = fun({AttrName,AttrValue,Qlty,Lock,MinValue,MaxValue}) ->
				{NNLen,NMBin} = tool:pack_string(AttrName) ,
				<<NNLen:16,NMBin/binary,AttrValue:32,Qlty:8,Lock:8,MinValue:32,MaxValue:32>> 
		end ,
	NRB = tool:to_binary([F(D) || D <- NAttrList]) ,
	Data = <<Code:8,NLen:16,NRB/binary>> ,
    {ok, pt:pack(32029, Data)};	

%% 角色装备五行珠情况(供人物宠物面板使用)
write(32031, [RoleID,RoleType,DataList]) -> 
	Len = length(DataList) ,
	F = fun({GoodsTypeId,BeadStep,AttrList}) ->
				AttrLen = length(AttrList) ,
				FA = fun({AttrName,AttrValue,AttrQlt}) ->
							 {NMLen,NMBin} = tool:pack_string(AttrName) ,
							 <<NMLen:16,NMBin/binary,AttrValue:32,AttrQlt:8>>
					 end ,
				AttrBin = tool:to_binary([FA(A) || A <- AttrList]) ,
				<<GoodsTypeId:32,BeadStep:8,AttrLen:16,AttrBin/binary>> 
		end ,
	RB = tool:to_binary([F(D) || D <- DataList]) ,
	Data = <<RoleID:32,RoleType:8,Len:16,RB/binary>> ,
	{ok, pt:pack(32031, Data)};


%% 角色装备五行珠情况(供人物宠物面板使用)
write(32032, [RoleID,RoleType,DataList]) -> 
	Len = length(DataList) ,
	F = fun({GoodsTypeId,BeadStep,AttrList}) ->
				AttrLen = length(AttrList) ,
				FA = fun({AttrName,AttrValue,AttrQlt}) ->
							 {NMLen,NMBin} = tool:pack_string(AttrName) ,
							 <<NMLen:16,NMBin/binary,AttrValue:32,AttrQlt:8>>
					 end ,
				AttrBin = tool:to_binary([FA(A) || A <- AttrList]) ,
				<<GoodsTypeId:32,BeadStep:8,AttrLen:16,AttrBin/binary>> 
		end ,
	RB = tool:to_binary([F(D) || D <- DataList]) ,
	Data = <<RoleID:32,RoleType:8,Len:16,RB/binary>> ,
	{ok, pt:pack(32032, Data)};

write(_Arg0, _Arg1) -> 
	ok.


%%
%% Local Functions
%%

