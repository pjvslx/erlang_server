cd ../config

erl -pa ../ebin -name sasl_report@127.0.0.1 -setcookie tnser -boot start_sasl -config gateway -eval "rb:start(), rb:start_log(\"../logs/gateway_sasl.log\"), rb:show(), rb:stop_log(),rb:stop()."  -s erlang halt

pause