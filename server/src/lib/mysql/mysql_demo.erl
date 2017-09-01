
-module(mysql_demo).
-compile(export_all).
-include("common.hrl").
%%%%% table
%%%%% test{id:int,name:varchar} 
%%%%% table

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% insert into db %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insert() ->
	?DB_MODULE:insert(test,[name],["this is a test"]) .
insert_admin() ->
	?DB_LOG_MODULE:insert(test,[name],["this is a test"]) .

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% select from table %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
select() ->
	?DB_MODULE:select_all(test,"*",[]) .
select_admin() ->
	?DB_LOG_MODULE:select_all(test,"*",[]) .