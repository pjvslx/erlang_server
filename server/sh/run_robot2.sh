#!/bin/sh
cd ../ebin
erl +P 1024000 -smp disable -name robot@127.0.0.1 -s robot start
