cd ../config
erl +P 1024000 -pa ../ebin -name game_server254@192.168.43.254 -env ERL_MAX_ETS_TABLES 5000 -setcookie luyang -boot start_sasl -config server  -s main server_start


pause