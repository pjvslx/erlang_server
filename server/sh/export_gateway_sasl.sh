#!/bin/bin
cd ../config
LogFile=/data/erlang/smxx/logs/gateway_sasl.log
erl -noshell -pa ../ebin -name sasl_report@127.0.0.1 -setcookie tnser -boot start_sasl -config gateway -eval "rb:start(), rb:start_log(\"${LogFile}\"), rb:show(), rb:stop_log(),rb:stop()." -s erlang halt >> /dev/null
echo "export success! ${LogFile}"