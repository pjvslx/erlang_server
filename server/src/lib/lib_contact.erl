%%%-----------------------------------
%%% @Module  : lib_contact
%%% @Author  : ly
%%% @Created : 2013.10.29
%%% @Description: 最近联系人处理
%%%-----------------------------------
-module(lib_contact).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).

%%处理最近联系人加载
role_login(Status) ->
	case get_contact(Status#player.id) of
		[] ->
			open_contact(Status);
		Contact ->
			%%这里要对contact_list中离线的uid进行剔除
			Fun = fun(Uid,List) ->
				PlayerInfo = lib_player:get_player(Uid),
				if
					PlayerInfo == {} ->
						List;
					true ->
						List ++ [Uid]
				end
			end,
			NewContactList = lists:foldl(Fun, [], Contact#contact.contact_list),
			NewContact = Contact#contact{contact_list = NewContactList},
			ets:insert(?ETS_CONTACT, NewContact)
	end.

%登出时联系人卸载
role_logout(Status) ->
	ets:delete(?ETS_CONTACT,Status#player.id).

%获取联系人信息  外部接口
get_contact_info(Status) ->
	Contact = get_contact(Status#player.id),
	Fun = fun(Uid,List) ->
		PlayerInfo = lib_player:get_player(Uid),
		if
			PlayerInfo == {} ->
				List;
			true ->
				List ++ [{Uid,PlayerInfo#player.nick}]
		end
	end,
	UidNameList = lists:foldl(Fun, [], Contact#contact.contact_list),
	UidNameList.

%获取在线玩家联系人(内部使用)
get_online_player_contact(PlayerId) ->
	case ets:lookup(?ETS_CONTACT, PlayerId) of
			[] ->
				[];
			[Contact] ->
				Contact
	end.

%添加最近联系人信息 Uid为在线
add_contact(SendUid,RecvUid) ->
	SendContact = get_online_player_contact(SendUid),
	%%为发送者添加信息
	if
		SendContact == [] ->
			skip;
		true ->
			%%在发送者的联系人列表中加入RecvUid
			Contact_len = length(SendContact#contact.contact_list),
			IsMember = lists:member(RecvUid, SendContact#contact.contact_list),
			if
				IsMember == true ->
					%%删除掉已经存在列表的 并且将RecvUid放在最前面
					NewContactList = lists:delete(RecvUid, SendContact#contact.contact_list),
					NewSendContact = SendContact#contact{contact_list = [RecvUid] ++ NewContactList};			
				true ->
					if 
						Contact_len >= 10 ->
							%%删除尾部的Uid  首部添加RecvUid
							LastMem = lists:last(SendContact#contact.contact_list),
							NewList = lists:delete(LastMem, SendContact#contact.contact_list);
						true ->
							NewList = SendContact#contact.contact_list
					end,
					NewSendContact = SendContact#contact{contact_list = [RecvUid] ++ NewList}
			end,
			%%更新最近联系人ETS
			ets:insert_new(?ETS_CONTACT, NewSendContact),
			spawn(fun()->db_agent_contact:update_activity(NewSendContact) end)
	end.


%获取联系人(内部使用)
get_contact(PlayerId) ->
	case ets:lookup(?ETS_CONTACT, PlayerId) of
		[] ->
			case db_agent_contact:get_contact(PlayerId) of
				[] ->
					[];
				Contact ->
					Contact
			end;
		[Contact] ->
			Contact
	end.

%开启联系人 往数据库冲插入数据
open_contact(Status) ->
	Contact = #contact{uid = Status#player.id,contact_list = []},
	ets:insert(?ETS_CONTACT, Contact),
	spawn(fun()->db_agent_contact:insert_contact(Contact) end).