%% Author: Administrator
%% Created: 2011-11-1
%% Description: TODO: Add description to random_test
-module(random_test).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%
random_test() ->
	?DEBUG("Start ~p",[[0]]),
	random_test_loop(1000000),
	?DEBUG("Finish ~p",[[0]]).

random_test_loop(T) ->
	case T < 1 of
		true ->
			[];
		_ ->
			R = util:rand(1,10000),
			io:format("~p\n",[R]),
			random_test_loop(T-1)
	end.



%% acid_to_player() ->
%% 	PlayerDB = ?DB_MODULE:select_all(player, "*", []),
%% 	F = fun(CD) ->
%% 		Cin = list_to_tuple([player | CD]),
%%   		case Cin#player.acid of
%% 			0 ->
%% 				case ?DB_MODULE:select_row(user,"*",[{acnm,Cin#player.acnm}]) of
%% 					[] -> 
%% 						ACId = ?DB_MODULE:insert(user, [acid,acnm,state,idcrs,sn], [0,Cin#player.acnm,0,0,0]),
%% 						?DB_MODULE:update(user, [{acid,ACId}], [{id,ACId}]);
%% 					D ->
%% 						[ACId,_acid,_acnm,_st,_idc,_sn] = D
%% 				end,
%% 				?DB_MODULE:update(player,[{acid, ACId}],[{id, Cin#player.id}]);
%% 			_ ->
%% 				[]
%% 		end
%%     end,
%% 	lists:foreach(F, PlayerDB).
		


online_clear() ->
	PlayerDB = ?DB_MODULE:select_all(player, "*", [{olflg,1}]),
%% 	Ftime = util:unixtime(),
%% 	?DEBUG("Start ~p",[Ftime]),
%% 	PlayerDB = ?DB_MODULE:select_all(player, "*", []),
	F = fun(CD) ->
		Cin = list_to_tuple([player | CD]),
		case lib_player:is_online(Cin#player.id) of
			true ->
				[];
			_ ->
				?DB_MODULE:update(player, [{olflg,0}], [{id,Cin#player.id}])
		end
	end, 
	lists:foreach(F, PlayerDB).
%% 		Etime = util:unixtime(),
%% 	?DEBUG("End ~p",[Etime]).


idcrs_clear() ->
	UsrDB = ?DB_MODULE:select_all(user, "*", []),
	F = fun(CD) ->
		[Id,_ACId,_Acnm,_St,_Id,_sn] = CD,
		?DB_MODULE:update(user, [{idcrs,0}], [{id,Id}])		
	end,
	lists:foreach(F, UsrDB).
		

%% relationship2relaTrans() ->
%% 	Relationship = ?DB_MODULE:select_all(relationship, "*", [{rela,0}]),
%% 	F = fun(CD) ->
%% 		[Id,IDA,IDB,Re,Al,Bsex,Bnick,Bcar,Bg,Bj,Asex,Anick,Acar,Ag,Aj] = CD,
%% 		RD = db_agent_rela:insert_rela(IDA,0,Anick,Asex,Acar,0,"",1),
%% 		Cin = list_to_tuple([ets_rela | RD]),
%% 		NFR = {IDB,Bnick,Bsex,Bcar,0,[]},
%% 		NFRALL = [NFR|Cin#ets_rela.frid], 
%% 		NCin = Cin#ets_rela{frid = NFRALL,fn = Cin#ets_rela.fn+1},
%% 		db_agent_rela:update_rela_by_uid(NCin) 
%% 	end,
%% 	lists:foreach(F, Relationship).



fore_test() ->
	lists:foreach(fun(D) ->
						  io:format(" ~p ",[D])
				  end,[1,2,3,4]).



log_player() ->
	D = ?DB_MODULE:select_all(player, "id,acid,acnm,nick,sex,crr", []),
%% 	?DEBUG("~p",[D]),
	F = fun(CD) ->
			[Uid,Acid,Acnm,Nick,Sex,Crr] = CD,	
			?DB_LOG_MODULE:insert(log_player,[uid,acid,acnm,nick,sex,crr], [Uid,Acid,Acnm,Nick,Sex,Crr])
		end,
	lists:foreach(F, D).


lists_find() ->
	Lis = data_name_list:get_list(),
	Start = util:unixtime(),
	io:format("Start Time ~p~n",[Start]),
	find_test(Lis,100000),
	End = util:unixtime(),
	io:format("End Time ~p~n",[End]).	

find_test(Lis,Num) ->
	if Num < 1 ->
		   ok;
	   true ->
		   FindNum = 100001 + random:uniform(1000),
		   lists:keyfind(FindNum,1,Lis),
		   find_test(Lis,Num-1)
	end.
	


get_player(Lv) ->
	D = ?DB_MODULE:select_all(player, "acnm,lv", [{lv,">=",Lv}]),
%% 	?DEBUG("~p",[D]).
	F = fun(CD) ->
			[Acnm,NLv] = CD,
			Acm = util:string_to_term(tool:to_list(Acnm)),
			{Acm,NLv}
%% 			?DB_LOG_MODULE:insert(log_player,[uid,acid,acnm,nick], [Uid,Acid,Acnm,Nick])
		end,
	Res = lists:map(F, D),
	Start = util:unixtime(),
	FileName = io_lib:format("./~p.txt",[Start]),
	{ok,FileIo} = file:open(FileName, [write]),
	File = io_lib:format("~p",[Res]),
	file:write(FileIo, File),
	file:close(FileIo).









