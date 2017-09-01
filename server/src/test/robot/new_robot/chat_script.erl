%% @author Administrator
%% @doc @todo Add description to chat_script.


-module(chat_script).

-define(HEADER_LENGTH, 4). %
%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).

call(11010,{Content},Sokcet)-> 
	 Len1 = byte_size(Content),
     Data = <<Len1:16, Content/binary>>,
	 gen_tcp:send(Sokcet,  pack(11010,Data ));
call(11070,{Id,Content},Sokcet)-> 
	 Len1 = byte_size(Content),
     Data = <<Id:32,Len1:16, Content/binary>>,
	 gen_tcp:send(Sokcet,  pack(11070,Data)).
%%  <<Id:32, Len:16, Nick1/binary, Len1:16, Bin1/binary>>
handle_socket(11010,BinData)->
	io:format("rec package ~p~n",[11010]), 
	 <<Id:32, Len1:16, Rest1/binary>> = BinData,
	 <<Nick:Len1/binary-unit:8,Len2:16,Rest2/binary>>= Rest1,
	 <<Content:Len2/binary-unit:8>> = Rest2,
	 Nick1 = binary_to_list(Nick),
	 Content1 = binary_to_list(Content),
	 io:format(" nick name ~p , content ~p~n",[Nick1,Content1]), 
  	 BinData;
handle_socket(11070,BinData)->
	io:format("rec package ~p~n",[11070]), 
	 <<Id:32, Len1:16, Rest1/binary>> = BinData,
	 <<Nick:Len1/binary-unit:8,Len2:16,Rest2/binary>>= Rest1,
	 <<Content:Len2/binary-unit:8>> = Rest2,
	 Nick1 = binary_to_list(Nick),
	 Content1 = binary_to_list(Content),
	 io:format(" nick name ~p , content ~p~n",[Nick1,Content1]), 
  	 BinData;
handle_socket(_,_)->
	void.
%% ====================================================================
%% Internal functions
%% ====================================================================

%%打包数据
pack(Cmd, Data) ->
    L = byte_size(Data) + ?HEADER_LENGTH,
    <<L:16, Cmd:16, Data/binary>>.
