%% @author Johanthe_Yip
%% @doc 旧项目邮件模块接口调试 ,由于本项目之前用于两个项目中，故包换两种邮件协议，该脚本
%% 对两项目协议进行调试

-module(mail_script).

%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).
-define(HEADER_LENGTH, 4). %

%%-----------旧版邮件协议请求服务器 1900x c_2_s ------------

%%==========获取信件列表及内容============= 
call(19004,{Mail_type, Mail_page},Sokcet)->
		   gen_tcp:send(Sokcet,  pack(19004, <<Mail_type:8,Mail_page:8>>));
%%==========提取附件==========
call(19006,{Mail_id},Sokcet)->
	 gen_tcp:send(Sokcet,  pack(19006, <<Mail_id:32>>));

%%-----------新版邮件协议请求服务器 190x c_2_s---------------

%%==========获取信件列表及内容=========
call(19051,{Page_index},Sokcet)->
	gen_tcp:send(Sokcet,  pack(19051, <<Page_index:16>>)).

%%-----------旧版邮件协议接收信息 1900x s_2_c ------------

%%==========获取信件列表及内容=============  
handle_socket(19004,BinData)->
	<<Result:8,Rest/binary>> = BinData,
	if Result =/= 0 ->
  	<< Mail_num:8,Mail_page:8, MailNum:16, BinList/binary>>=Rest,
	io:format("rec package ~p~n",[19004]), 
	 {Maillist, _} = get_list([], BinList, MailNum),
	io:format("package info: ~p~n",[Maillist]);
	  true ->
	io:format("rec package but no data ~p ~n",[19004]) end,
			BinData;
%%==========提取附件==========
handle_socket(19006,BinData)->
	io:format("rec package ~p~n",[19006]),
	<<Result:16, MailId:32>> = BinData,
	io:format("package info Result:~p MailId:~p~n", [Result,MailId]);

%%-----------新版邮件协议请求服务器 190x s_2_c---------------

%%==========获取信件列表及内容=========
handle_socket(19051,BinData)->
	io:format("rec package ~p~n",[19051]), 
			BinData;
handle_socket(_,_)-> 
	void.


%% 读取列表，列表每项：[Id, Type,State, Timestamp, SName, Uid,Title, Content,Goods_list,Coin,Gold]
%% 对应：<<Id:32, Type:8, State:8, Timestamp:32, Len1:16, SName/binary, Len2:16, Title/binary, Len3:16, Content/binary, GLen:16, GoodsBin/binary, Gold:32, Coin:32>> 
%% AccList 列表累加器，使用时初始为[]
get_list(AccList, Bin, N) when N>0 ->
    case Bin of
        <<Id:32, Type:8, State:8, Timestamp:32, Len1:16, Rest/binary>> ->
            <<SName:Len1/binary-unit:8, Len2:16, Rest2/binary>> = Rest,
            <<Title:Len2/binary-unit:8, Len3:16, Rest3/binary>> = Rest2,
			<<Content:Len3/binary-unit:8,Len4:16,Rest4/binary>> = Rest3,
            <<GoodsBin:Len4/binary-unit:8, Gold:32, Coin:32,Rest5/binary>>=Rest4,
            SName1 = binary_to_list(SName),
            Title1 = binary_to_list(Title),
			Content1 = binary_to_list(Content),
			GoodsBin1 = binary_to_list(GoodsBin),
            Item = [Id, Type,State, Timestamp, SName,Title, Content,GoodsBin,Coin,Gold],
            %io:format("Item: ~p~n", [Item]),
            NewList = [Item | AccList],
            get_list(NewList, Rest5, N - 1);
        _R1 ->
            error
    end;
get_list(AccList, Bin, _) ->
    {lists:reverse(AccList), Bin}.

%%打包数据
pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.