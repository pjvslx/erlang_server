#!/bin/sh
NODE=0
COOKIE=smxx4399
##Get the IP Address.
IPADDR=`ifconfig eth0 | grep -m 1 'inet addr' | awk '{print $2}' | sed -e "s/addr\://"`
LOCAL_GAYTE_NODE_NAME=local_gateway@${IPADDR}
NODE_NAME=stop_local_gateway@${IPADDR}
ulimit -SHn 102400


cd ../config
erl -detached \
    -pa ../ebin \
    -name $NODE_NAME \
    -setcookie $COOKIE \
    -s misc_admin stop_local_gateway_node $LOCAL_GAYTE_NODE_NAME \
    -eval "timer:sleep(5000), erlang:halt()."
