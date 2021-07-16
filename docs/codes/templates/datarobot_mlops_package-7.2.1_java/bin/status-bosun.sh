#!/bin/bash

# setup some working rules by setting up the basedir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=$(dirname "$DIR")

BOSUN_PID_FILE="$DIR"/PID.bosun
BOSUN_NOT_RUN_MSG="DataRobot Bosun service is not running."
BOSUN_RUN_MSG="DataRobot Bosun service is running."

# platform type
MLOPS_OS_LINUX="linux-gnu"
MLOPS_OS_MAC="darwin"*

# Set the default BOSUN_LOG_PATH
BOSUN_LOG_PATH="$TOP_DIR"/logs/mlops.bosun.log

usage() {
     echo "Usage: `basename $0 ` [--verbose | --help]"
     echo "     --help            this help menu"
     echo "     --verbose         provide process verbose resource usage"
}

check_status() {
    # No BOSUN_PID_FILE means no bosun service is running.
    if ! [[ -e "$BOSUN_PID_FILE" ]]; then
        echo "$BOSUN_NOT_RUN_MSG"
        exit 0
    fi

    # Empty BOSUN_PID_FILE means no MLOps bosun is running as a service.
    bosun_pid=$(cat "$BOSUN_PID_FILE")
    if [[ -z "$bosun_pid" ]]; then
        echo "$BOSUN_NOT_RUN_MSG"
        exit 0
    fi

    if ! [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
        echo "DataRobot Bosun service was previously running (process id $bosun_pid). It might exit out with error."
        echo "Check Bosun log file (default log file - $BOSUN_LOG_PATH)."
        exit 1
    fi

    echo "$BOSUN_RUN_MSG"
}

option_flag=$1
if [[ -z "$option_flag" ]]; then
    check_status
elif [[ "$option_flag" = "--verbose" ]]; then
    check_status
    if [[ "$OSTYPE" == ${MLOPS_OS_LINUX} ]]; then
        cmd_line="ps -eo %cpu,%mem,etime,msgsnd,msgrcv,oublk -q $bosun_pid"
    elif [[ "$OSTYPE" == ${MLOPS_OS_MAC} ]]; then
        cmd_line="ps -o %cpu,%mem,etime,wq,msgsnd,msgrcv,oublk -p $bosun_pid"
    else
        echo "INFO: ($OSTYPE) option 'verbose' not supported"
        exit 1
    fi
    eval $cmd_line
    for i in {1..5}; do sleep 2; \
        eval $cmd_line | tail -n 1; \
    done
elif [[ "$option_flag" = "--help" ]]; then
    usage
else
    usage
    exit 1
fi

exit 0
