#!/bin/bash

# default BOSUN_LOG_PROPERTIES = ../conf/mlops.log4j2.properties
# default BOSUN_CONFIG_YAML    = ../conf/mlops.bosun.conf.yaml
# default BOSUN_LOG_PATH       = ../logs/mlops.bosun.log
# default BOSUN_JAR_PATH       = ../lib/bosun-*.jar
# default BOSUN_JVM_OPT        = -Xmx1G

# setup some working rules by setting up the basedir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=$(dirname "$DIR")

BOSUN_PID_FILE="$DIR"/PID.bosun

# Set the default BOSUN_LOG_PATH
BOSUN_LOG_PATH="$TOP_DIR"/logs/mlops.bosun.log
BOSUN_OUT_PATH="$TOP_DIR"/logs/mlops.bosun.out

# If any instance of bosun service is running, exit.
# If no BOSUN_PID_FILE, start bosun service.
# If there is an BOSUN_PID_FILE, get the pid. If the pid is still running, exit.
# Otherwise, start bosun service.
if [[ -e "$BOSUN_PID_FILE" ]]; then
    if [[ -f "$BOSUN_PID_FILE" && -r "$BOSUN_PID_FILE" && -w "$BOSUN_PID_FILE" ]]; then
        bosun_pid=$(cat "$BOSUN_PID_FILE")
        if ! [[ -z "$bosun_pid" ]]; then
            if [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
                echo "DataRobot Bosun service is already running (process id $bosun_pid)."
                echo "Stop it first."
                exit 1
            else
                echo "DataRobot Bosun Service was previously running (process id $bosun_pid)."
                echo "It might exit out with error."
                echo "Check Bosun log file (default log file - $BOSUN_LOG_PATH)."
                echo "Clean up the Bosun pid file - $BOSUN_PID_FILE."
                exit 1
            fi
        fi
    else
        echo "Permission denied: $BOSUN_PID_FILE"
        exit 1
    fi
fi


if [[ -d ${JAVA_HOME} ]]; then
   CMD_JAVA=${JAVA_HOME}/bin/java
else
   CMD_JAVA=java
fi

JAVA_VER=$(${CMD_JAVA} -version 2>&1 >/dev/null | egrep "\S+\s+version" | awk '{print $3}' | tr -d '"')
if [[ $JAVA_VER != 11* ]]; then
        echo "Java version is not 11: \"${JAVA_VER}\""
        echo "Please install Java Runtime Environment 11 first"
        exit 1
else
        echo "Correct java version found on the system: \"${JAVA_VER}\""
fi

user_override=1

if [[ -z "$BOSUN_CONFIG_YAML" ]]; then
   BOSUN_CONFIG_YAML="$TOP_DIR"/conf/mlops.bosun.conf.yaml
   user_override=0
elif ! [[ -r "$BOSUN_CONFIG_YAML" && -f "$BOSUN_CONFIG_YAML" ]]; then
   BOSUN_CONFIG_YAML="$TOP_DIR"/conf/mlops.bosun.conf.yaml
   user_override=0
fi

echo "INFO: BOSUN_CONFIG_YAML=$BOSUN_CONFIG_YAML"

if [[ -z "$BOSUN_LOG_PROPERTIES" ]]; then
   BOSUN_LOG_PROPERTIES="$TOP_DIR"/conf/mlops.bosun.log4j2.properties
elif ! [[ -r "$BOSUN_LOG_PROPERTIES" && -f "$BOSUN_LOG_PROPERTIES" ]]; then
   BOSUN_LOG_PROPERTIES="$TOP_DIR"/conf/mlops.bosun.log4j2.properties
fi

echo "INFO: BOSUN_LOG_PROPERTIES=$BOSUN_LOG_PROPERTIES"

if [[ -z "$BOSUN_JVM_OPT" ]]; then
   BOSUN_JVM_OPT=-Xmx1G
fi

echo "INFO: BOSUN_JVM_OPT=$BOSUN_JVM_OPT"

if [[ -z "$BOSUN_JAR_PATH" ]]; then
   BOSUN_JAR_PATH=$(ls "$TOP_DIR"/lib/mlops-agent-*.jar)
fi

echo "INFO: BOSUN_JAR_PATH=$BOSUN_JAR_PATH"

function clean_path_string
{
   # remove spaces and quotes
   xquote=${1//\"/}
   echo "${xquote//\ /}"
}

if [[ $user_override == '1' ]]; then
   raw_bosun_log_path=$(cat $BOSUN_CONFIG_YAML | grep "logPath" | cut -d':' -f2)
   custom_log_path=$(clean_path_string $raw_bosun_log_path)

   # If the custom_log_path is valid, set the BOSUN_LOG_PATH to custom_log_path
   if [[ -f "$custom_log_path" && -r "$custom_log_path" && -w "$custom_log_path" ]]; then
       BOSUN_LOG_PATH="$custom_log_path"
   fi
fi

echo "INFO: BOSUN_LOG_PATH=$BOSUN_LOG_PATH"
echo
echo "Starting Bosun Service"
echo
echo
cd "${DIR}"
nohup ${CMD_JAVA} ${BOSUN_JVM_OPT} -Dlog.file="${BOSUN_LOG_PATH}" \
     -Dlog4j.configurationFile=file:"${BOSUN_LOG_PROPERTIES}" \
     -cp "${BOSUN_JAR_PATH}" com.datarobot.mlops.agent.Agent --manage \
     --config "${BOSUN_CONFIG_YAML}" > ${BOSUN_OUT_PATH} 2>&1 &

bosun_pid=$!

sleep 2
if ! [[ $(ps -p "$bosun_pid" -o comm=) =~ "java" ]]; then
    echo "========= Bosun service LOG FILE: ${BOSUN_LOG_PATH} ========= "
    tail -n 20 "${BOSUN_LOG_PATH}"
    echo "============================================== "
    echo "Failed to start DataRobot Bosun service(process id - $bosun_pid)."
    exit 1
fi

echo "$bosun_pid" > "$BOSUN_PID_FILE"
echo "DataRobot Bosun service is running."
exit 0
