#!/bin/bash

# setup some working rules by setting up the basedir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=$(dirname "$DIR")

BOSUN_PID_FILE="$DIR"/PID.bosun
BOSUN_NOT_RUNNING_MSG="No DataRobot Bosun service is currently running."

bosun_pid=""
# Set the default BOSUN_LOG_PATH
BOSUN_LOG_PATH="$TOP_DIR"/logs/mlops.bosun.log

if ! [[ -e "$BOSUN_PID_FILE" ]]; then
    echo $BOSUN_NOT_RUNNING_MSG
    exit 1
fi

if [[ -f "$BOSUN_PID_FILE" && -r "$BOSUN_PID_FILE" && -w "$BOSUN_PID_FILE" ]]; then
    bosun_pid=$(cat "$BOSUN_PID_FILE")
    # If there is no pid in the BOSUN_PID_FILE or the pid is not valid, clean up the BOSUN_PID_FILE and exit.
    if [[ -z "$bosun_pid" ]]; then
        echo $BOSUN_NOT_RUNNING_MSG
        exit 1
    elif ! [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
        echo "DataRobot Bosun service was previously running (process id $bosun_pid). It might exit out with error."
        echo "Check Bosun log file (default log file - $BOSUN_LOG_PATH)."
        echo "Clean up the Bosun pid file - $BOSUN_PID_FILE"
        exit 1
    fi
else
    echo "Permission denied $BOSUN_PID_FILE"
    exit 1
fi

kill "$bosun_pid"
for i in {1..15}; do
    sleep 1
    if ! [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
        echo "DataRobot Bosun service shutdown done."
        rm $BOSUN_PID_FILE
        exit 0
    fi
 done

echo "DataRobot Bosun service force shutdown initiated."
kill -9 "$bosun_pid"
sleep 1
if [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
   echo "Force shutdown of DataRobot Bosun service failed (PID:${bosun_pid})"
   exit 1
fi

echo "DataRobot Bosun service force shutdown done."
rm $BOSUN_PID_FILE
exit 0
