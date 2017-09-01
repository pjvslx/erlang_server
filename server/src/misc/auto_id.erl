%%--------------------------------------
%% @Module  : auto_id
%% @Author  : smxx
%% @Created : 2013.03.01
%% @Description: 设置数据表的自增ID初值
%%--------------------------------------
-module(auto_id).
-compile([export_all]).
-include("auto_id.hrl").
  
%%设置自增ID初值(服务节点才需要处理.　其他不管)
set_auto_increment(server) ->
    ServerNum = config:get_server_num(),
    io:format("~n--------------------------------------------------~n"),
    io:format("Start checking tables Auto Increment...~n"),
    io:format("Current Server Num: ~p~n", [ServerNum]),
    io:format("--------------------------------------------------~n"),
    F = fun(TableName) ->
        case get_auto_increment_width(TableName) of
            no_match -> 
                 io:format("Table: ~p found NO AUTO_INCREMENT fields, check your configuration!~n", [TableName]);
            Width ->  %%字段宽度
                case Width of
                    20 ->  
                        Start = ServerNum * ?SPACE20 + 1,
                        End = (ServerNum + 1) * ?SPACE20;
                    11 -> 
                        Start = ServerNum * ?SPACE11 + 1,
                        End = (ServerNum + 1) * ?SPACE11
                end,
                CurrentOffset = get_auto_increment_offset(TableName),
                if 
%% 					CurrentOffset >= Start andalso CurrentOffset < End ->    %%已经设置好了
%%                       io:format("Table: ~p \tAUTO_INCREMENT OFFSET ->\tOK~n", [TableName]),
%%                       io:format("\t\tCurrent: ~p, Start: ~p, End:~p~n~n", [CurrentOffset, Start, End]);
%%                    CurrentOffset >= End ->
%%                       io:format("Table: ~p \tAUTO_INCREMENT OFFSET -> OUT OF RANGE~n", [TableName]),
%%                       io:format("\t\tCurrent: ~p, Start: ~p, End:~p~n~n", [CurrentOffset, Start, End]);
				   CurrentOffset > ?SPACE20 ->			%% 已经设置过了偏移量
					   io:format("Table: ~p \t AUTO_INCREMENT OFFSET ->\tOK~n", [TableName]),
					   io:format("\t\tCurrent: ~p, Start: ~p, End:~p~n~n", [CurrentOffset, Start, End]);
				   
                   true ->
                      io:format("Table: ~p \tAUTO_INCREMENT OFFSET -> NOT SET~n", [TableName]),
                      io:format("\t\tCurrent: ~p, Start: ~p, End:~p~n", [CurrentOffset, Start, End]),
                      io:format("\t\tSetting to: ~p", [Start]),
                      case set_auto_increment_offset(TableName, Start) of
                           true -> io:format(" -> OK~n~n");
                            _   -> io:format(" -> Failed~n~n")
                      end
                end
        end
    end,
    lists:foreach(F, ?AUTO_ID_TABLES),
    io:format("~nTables Auto Increment Done~n"),
    io:format("--------------------------------------------------~n");
set_auto_increment(_) -> 
    skip.
    
%%Auto_Increment字段在第11位
get_auto_increment_offset(TableName) ->
    Sql = lists:concat(["show table status where name='", TableName, "'"]),
    case lists:nth(11, db_esql:get_row(Sql)) of
        Offset when is_integer(Offset) -> 
            Offset;
        _Error  ->  
            io:format("ERROR when getting Auto_Increment for table ~p~n", [TableName]),
            error
    end.

%%获取数据表的AUTO_INCREMENT字段的宽度
get_auto_increment_width(TableName) ->
    Sql = lists:concat(["show create table ", TableName]),
    case db_esql:get_row(Sql) of 
    	{db_error, _} ->
			error;
		[_, A|_]->
 			CreateTableList = re:split(A,"[\n]",[{return, binary}]),
            search_auto_increment(CreateTableList)
    end.

%%设置AUTO_INCREMENT的值
set_auto_increment_offset(TableName, Offset) ->
    Sql = io_lib:format("alter table ~s auto_increment=~s;", [atom_to_list(TableName), integer_to_list(Offset)]),
    case db_esql:execute_sql(Sql) of
    	{db_error, _} ->
			false;
		_Result ->
            %io:format("Result: ~p~n", [Result])
            true
    end.

%%搜索有没有含AUTO_INCRMENT字段的行
%%如果没有,返回no_match
%%如果有:　搜索AUTO_INCREMENT行中"int(xx)"并返回xx的值,　没有返回no_match
search_auto_increment([]) ->
    no_match;
search_auto_increment([L|T]) ->
    Line = binary_to_list(L),
    case re:run(Line, "AUTO_INCREMENT", [caseless]) of  %%匹配AUTO_INCREMENT行
         {match, _} ->  %%有
              search_int_width(Line);
        _Other -> 
              search_auto_increment(T)
    end.

%%搜索"int(xx)"并返回xx的值,　没有返回no_match
search_int_width(Line) ->
    case re:run(Line, "int", [caseless]) of
         {match, [{Idx1, L1}|_]} ->  %%匹配上,Idx1, L1是"int"起始坏置及长度
             Idx = min(Idx1 + L1 + 1, length(Line)), 
             case lists:sublist(Line, Idx, 4) of   %%取"(xx)"这一段, 最多取4字符
                 [40, A, B, 41] ->                 %%40为"(", 41为")",长度为两数字
                     list_to_integer([A,B]);       
                 [40, A, 41] ->                    %%长度为1数字
                     list_to_integer([A]);
                 _Other -> 
                     no_match
             end;
         _Other ->
             no_match
    end.


