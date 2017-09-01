#!/bin/bin

cd ../config

LogFile=/data/erlang/server/logs/sever_sasl.log
erl -noshell -pa ../ebin -name sasl_report@127.0.0.1 -setcookie tnser -boot start_sasl -config server -eval "rb:start(), rb:start_log(\"${LogFile}\"), rb:show(), rb:stop_log(),rb:stop()." -s erlang halt >> /dev/null 


echo "export success! ${LogFile}"