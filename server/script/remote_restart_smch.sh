cd /data/erlang/smch/sh

./stop_server.sh
./stop_gateway.sh

sleep 120
./start_gateway.sh
./start_server.sh

