#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin

for i in {1..10}; do
    pid=$(ps ax | grep "iperf3 -s -D" | grep -v grep | awk '{print $1;}')
    if [ "$pid" == "" ]; then
        echo "$0: iperf3 process not found. Starting iperf3"
        iperf3 -s -D
        exit 0
    fi

    established=$(ss -l -t -p -n sport eq 5201 | grep 'LISTEN\|ESTAB')
    if [ "$?" == "0" ]; then
        echo "$0: iperf3 pid $pid established or listening. Not restarting iperf3 process"
    else
        echo "$0: killing iperf3 server with pid: $pid"
        kill -9 $pid
        echo "$0: Restarting iperf3 server and exiting"
        iperf3 -s -D
        break
    fi
    sleep 30
done

exit 0