#!/bin/sh

NODE=1
COOKIE=smxx4399
##Get the IP Address.
IPADDR=`ifconfig eth0 | grep -m 1 'inet addr' | awk '{print $2}' | sed -e "s/addr\://"`
NODE_NAME=smxx_game$NODE@${IPADDR}

ulimit -SHn 102400

# define default configuration
POLL=true
SMP=auto
ERL_MAX_PORTS=32000
ERL_PROCESSES=500000
ERL_MAX_ETS_TABLES=1400

export ERL_MAX_PORTS
export ERL_MAX_ETS_TABLES


cd ../config
erl +P $ERL_PROCESSES \
    +K $POLL \
    -smp $SMP \
    -pa ../ebin \
    -name $NODE_NAME \
    -setcookie $COOKIE \
    -boot start_sasl \
    -config server \
    -s main server_start
   
