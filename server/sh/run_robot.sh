#!/bin/sh

NODE=6
COOKIE=smxx1608
NODE_NAME=robot$NODE@127.0.0.1

ulimit -SHn 102400

# define default configuration
POLL=true
SMP=auto
ERL_MAX_PORTS=1024000
ERL_PROCESSES=500000
ERL_MAX_ETS_TABLES=1400

export ERL_MAX_PORTS
export ERL_MAX_ETS_TABLES

DATETIME=`date "+%Y%m%d%H%M%S"` 
LOG_PATH="../logs/robot_$NODE.$DATETIME.log" 

cd ../ebin
erl +P $ERL_PROCESSES \
    +K $POLL \
    -smp $SMP \
    -pa ../ebin \
    -name $NODE_NAME \
    -setcookie $COOKIE \
    -boot start_sasl \
    -kernel error_logger \{file,\"$LOG_PATH\"\} \
    -s robot start

