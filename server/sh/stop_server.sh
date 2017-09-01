#!/bin/sh

NODE=1
COOKIE=smxx4399
##Get the IP Address.
IPADDR=`ifconfig eth0 | grep -m 1 'inet addr' | awk '{print $2}' | sed -e "s/addr\://"`
SERVER_NODE_NAME=smxx_game$NODE@${IPADDR}
NODE_NAME=stop_server$NODE@${IPADDR}


cd ../config
erl -detached \
    -pa ../ebin \
    -name $NODE_NAME \
    -setcookie $COOKIE \
    -s misc_admin stop_server_node $SERVER_NODE_NAME \
    -eval "timer:sleep(5000), erlang:halt()."