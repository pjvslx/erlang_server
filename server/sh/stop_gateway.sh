#!/bin/sh
NODE=0
COOKIE=smxx4399
##Get the IP Address.
IPADDR=`ifconfig eth0 | grep -m 1 'inet addr' | awk '{print $2}' | sed -e "s/addr\://"`
GATE_NODE_NAME=game_gateway@${IPADDR}
NODE_NAME=stop_game_gateway@${IPADDR}


cd ../config
erl -detached \
    -pa ../ebin \
    -name $NODE_NAME \
    -setcookie $COOKIE \
    -s misc_admin stop_game_node $GATE_NODE_NAME \
    -eval "timer:sleep(5000), erlang:halt()."
