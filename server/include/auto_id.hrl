-ifndef(_AUTO_ID_HEADER_).
-define(_AUTO_ID_HEADER_, 0).

%%64位/20位 100 0000 0000  %%每服100亿空间,　够用了吧
%%32位/11位 200 0000       %%32位,每服分200W, 大概可以有2000个服务器, 也够了吧
%-define(SPACE20, 10000000000).    
%-define(SPACE11, 2000000).   

%%方便调试输帐号,　先设小一点值
-define(SPACE20, 10000000000).    
-define(SPACE11, 2000000).  
 
%%定义需要处理自增ID的表
-define(AUTO_ID_TABLES,
        [
          player,
          goods,
          guild
        ]
).

-endif.  %% _AUTO_ID_HEADER_ 


