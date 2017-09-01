
%%%--------------------------------------
%%% @Module  : db_agent_scene
%%% @Author  : csj
%%% @Created : 2010.08.24
%%% @Description: 场景模块处理函数
%%%--------------------------------------
-module(db_agent_scene).

-include("common.hrl").
-include("record.hrl").
-compile(export_all).


test() ->
	?DB_MODULE:select_all(temp_task_, [content], [{id,501010070}]).


%%@spec 加载场景模板
select_scene() ->
	case ?DB_MODULE:select_all(temp_scene, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  SceneRcd = list_to_tuple([temp_scene|DataItem]) ,
						  SceneRcd#temp_scene{id = SceneRcd#temp_scene.sid}
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .


%%@spec 加载NPC模板
select_npc() ->
	case ?DB_MODULE:select_all(temp_npc, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  SceneRcd = list_to_tuple([temp_npc|DataItem]) ,
						  SceneRcd#temp_npc{act_skilllist = util:bitstring_to_term(SceneRcd#temp_npc.act_skilllist),
											pas_skilllist = util:bitstring_to_term(SceneRcd#temp_npc.pas_skilllist)}
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%@spec 加载NPC布局模板（NPC最多3位数能够）
select_npc_layout() ->
	case ?DB_MODULE:select_all(temp_npc_layout, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  LayoutRcd = list_to_tuple([temp_npc_layout|DataItem]) ,
						  LayoutRcd#temp_npc_layout{id = LayoutRcd#temp_npc_layout.scene_id * 100 + LayoutRcd#temp_npc_layout.npcid} 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%@spec 加载MON布局模板（MON最多4位数能够）
select_mon_layout() ->
	case ?DB_MODULE:select_all(temp_mon_layout, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  LayoutRcd = list_to_tuple([temp_mon_layout|DataItem]) ,
						  LayoutRcd 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .


