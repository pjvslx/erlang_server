%%%-----------------------------------
%%% @Module  : lib_npc
%%% @Author  : csj
%%% @Created : 2010.10.06
%%% @Description: npc
%%%-----------------------------------
-module(lib_npc).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-compile(export_all).

%%初始化基础Npc
init_base_npc() ->
%%     F = fun(Npc) ->
%% 			D = list_to_tuple([ets_npc] ++ Npc),
%% 			NpcInfo = D#ets_npc{
%% 						icon = util:string_to_term(tool:to_list(D#ets_npc.icon)),
%%  						talk = util:string_to_term(tool:to_list(D#ets_npc.talk))
%% 						},			
%%             ets:insert(?ETS_BASE_NPC, NpcInfo)
%%            end,
%% 	L = ?DB_MODULE:select_all(base_npc, "*", [], [], []),
%% 	lists:foreach(F, L),
	ok.
	
%%初始化基础对话
init_base_talk() ->
%% 	ets:delete_all_objects(?ETS_BASE_TALK),
%%     F = fun(Talk) ->
%% 			D = list_to_tuple([talk] ++ Talk),			
%% 			TalkInfo = D#talk{content=data_agent:convert_talk(D#talk.content)},
%%            	ets:insert(?ETS_BASE_TALK, TalkInfo)
%%            end,
%% 	L = ?DB_MODULE:select_all(base_talk, "*", [], [], []),
%% 	lists:foreach(F, L),
    ok.

%% %% 获取npc名称用npc数据库id
%% get_name_by_npc_id(NpcId)->
%%     case data_agent:npc_get(NpcId) of
%%         [] -> <<"">>;
%%         Npc -> Npc#ets_npc.name
%%     end.

%% 获取信息
get_data(NpcId) ->
    case data_agent:npc_get(NpcId) of
        [] -> ok;
        Npc -> Npc
    end.

%%获取一个NPC
%% get_npc(NpcUniqueId, SceneId) ->
%%    	MS = ets:fun2ms(fun(T) when T#ets_npc.id == NpcUniqueId, T#ets_npc.scn == SceneId  -> T end),
%%    	case ets:select(?ETS_SCENE_NPC, MS)	of
%%       		[] -> [];
%%         	[H|_] -> [H] 
%%     end.

%% %% 获取当前场景某类NPC信息 
%% get_scene_by_npc_id(NpcId) ->
%%    	MS = ets:fun2ms(fun(T) when T#ets_npc.nid == NpcId -> 
%% 			[
%%             T#ets_npc.scn,
%%             T#ets_npc.x,
%%             T#ets_npc.y		 
%% 			] 
%% 			end),
%%    	case ets:select(?ETS_BASE_SCENE_NPC, MS)	of
%%       		[] -> [];
%% 			Info -> 
%% 				Info
%% %%         	[[Scene, X, Y]|_] -> 
%% %% 				[Scene, X, Y] 
%%     end.

%% %% 获得NPC唯一id
%% get_unique_id(NpcId, SceneId) ->
%%     case ets:match(?ETS_SCENE_NPC, #ets_npc{id ='$1', nid = NpcId, scn = SceneId,  _ = '_'}) of
%%         [] -> 0;
%%         [[Id]|_] -> Id
%%     end.
%% 
%% 

