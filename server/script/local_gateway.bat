cd ../config
erl +P 1024000 -pa ../ebin -name local_gateway@192.168.43.172 -setcookie smxx4399 -boot start_sasl -config local_gateway  -s main local_gateway_start
pause
