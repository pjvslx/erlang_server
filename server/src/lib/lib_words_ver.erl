%% Author:  smxx
%% Created: 2013-01-15
%% Description: 敏感词处理
-module(lib_words_ver).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

-compile(export_all).

%%
%% API Functions
%%
%% -----------------------------------------------------------------
%% 敏感词处理
%% -----------------------------------------------------------------
words_filter(Words_for_filter) ->
	Words_List = data_words:get_words_verlist(),  
	binary:bin_to_list(lists:foldl(fun(Kword, Words_for_filter0)->
										   re:replace(Words_for_filter0,Kword,"*",[global,caseless,{return, binary}])
								   end,
								   Words_for_filter,Words_List)).

%%敏感词过滤, 
%%合法:返回true
words_ver(Words_for_ver) ->
	Words_List = data_words:get_words_verlist(),
	BeMatch = lists:any(fun(Words) ->
				 case re:run(Words_for_ver, Words, [caseless]) of
							   nomatch -> false;
							   _-> true
						   end				 
			  end, Words_List),
	BeMatch =:= false.
		

%%检查是否含特殊字符/敏感词
validate_name(Name, special) ->
   case asn1rt:utf8_binary_to_list(tool:to_binary(Name)) of
        {ok, CharList} ->
             case check_special_char(CharList) of
                 true  -> 
                      case validate_name(Name, sen_words) of
                          true  -> true;
                          false -> false
                      end;
                 false -> 
                     false
             end;
        {error, _Reason} ->
             false
    end; 

%%长度合法性检测:长度
validate_name(Name, [MinL, MaxL]) ->
    case asn1rt:utf8_binary_to_list(tool:to_binary(Name)) of
        {ok, CharList} ->
            Len = string_width(CharList),   
            case Len >= MinL andalso Len =< MaxL of
                true  -> true;
                false -> false
            end;
        {error, _Reason} ->
            false
    end; 

%%是否包含敏感词
validate_name(Name, sen_words) ->
    case lib_words_ver:words_ver(Name) of  
        true ->
            true;  
        false ->
            false
    end;

validate_name(_Name, _) ->
    false.

%% 字符宽度，1汉字=2单位长度，1数字字母=1单位长度
string_width(String) ->
    string_width(String, 0).
string_width([], Len) ->
    Len;
string_width([H | T], Len) ->
    case H > 255 of
        true ->
            string_width(T, Len + 2);
        false ->
            string_width(T, Len + 1)
    end.

%%检查是否含特殊字符
%%ASCII 48 == "0", %%ASCII 57 == "9"
%%ASCII 65 == "A", %%ASCII 90 == "Z"
%%ASCII 97 == "a", %%ASCII 122 == "z"
check_special_char([]) ->
    true;
check_special_char([NameChar|T]) ->
    case  NameChar =:= 8226 orelse 
          NameChar < 48 orelse   %%ASCII"0"以下非法字符
         (NameChar > 57 andalso NameChar < 65) orelse  %%"0" ~ "A"之间非法ASCII
         (NameChar > 90 andalso NameChar < 95) orelse  %%"Z" ~ "a"之间非法ASCII
         (NameChar > 122 andalso NameChar < 130)  of   %%"z"之后非法ASCII, 大于127是unicode, 不是ASCII了
         true  -> %%含非法字符
             false;
         false -> %%
             check_special_char(T)
    end.

