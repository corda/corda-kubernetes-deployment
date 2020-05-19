#!/bin/sh
IP=$1
PORT=$2
(echo > /dev/tcp/$IP/$PORT) > /dev/null 2>&1 && echo "UP" || echo "DOWN"
#Alternatives https://superuser.com/questions/621870/test-if-a-port-on-a-remote-system-is-reachable-without-telnet:
#curl http://$IP:$PORT
#nc -zv $IP $PORT &> /dev/null; echo $?
#cat < /dev/tcp/$IP/$PORT
