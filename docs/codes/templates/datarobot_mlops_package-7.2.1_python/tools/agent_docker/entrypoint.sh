#!/bin/bash

set -euo pipefail
# Output colors
NORMAL="\\033[0;39m"
RED="\\033[1;31m"
BLUE="\\033[1;34m"

# LOG FUNCTIONS
log() {
    echo "$BLUE > $1 $NORMAL"
}

error() {
    echo ""
    echo "$RED >>> ERROR - $1$NORMAL"
}

# PRINT DOCKER EXAMPLES
function usage() {
  cat << EOF
ENVIRONMENT VARIABLES

    AGENT_BASE_LOC
        Location of your MLOps Monitoring-Agent base install.
    AGENT_CONF_LOC
        Location of your MLOps Monitoring-Agent configuration file(e.g. /var/tmp/mlops.agent.conf). This option allow you to configure the location of
        MLOps Monitoring-Agent configuration.
    AGENT_LOG_PROPERTIES
        Configure logging properties of MLOps Monitoring-Agent. mlops.log4j2.properties(FILE) and stdout.mlops.log4j2.properties(STDOUT) are available
        or mount your onw log4j2.properties.
    MLOPS_SERVICE_URL
        URL of DataRobot MLOps system to connecto to
    MLOPS_API_TOKEN
        API token to use when connecting to DataRobot MLOps system
    START_DELAY
        Number of seconds to delay before starting the agent. This is usefull when the agent needs to connect with
        other services (e.g. rabbitmq) which takes time to start. Value should be number of seconds to delay.
    JAVA_OPTIONS
        JVM options can be set by passing the JAVA_OPTIONS environment variable to the container.
    TMPDIR
        Location for agent to write temporary files.

EXAMPLE

  Run with external monitoring agent configuration mounted default:
    $ docker run \\
        -v /path/to/mlops.agent.conf.yaml:/opt/datarobot/mlops/agent/conf/mlops.agent.conf.yaml \\
        datarobot-mlops-agent

  Run with external monitoring agent configuration mounted in custom location:
    $ docker run \\
        -v /path/to/mlops.agent.conf.yaml:/var/tmp \\
        -e AGENT_CONF_LOC=/var/tmp \\
        datarobot-mlops-agent

  Run with mlops-agent log directed to stdout:
    $ docker run \\
        -v /path/to/mlops.agent.conf.yaml:/var/tmp \\
        -e AGENT_LOG_PROPERTIES=stdout.mlops.log4j2.properties
        datarobot-mlops-agent

EOF
}

# GENERATE BASIC MLOPS-AGENT CONFIGURATION
function generate() {
    # READ INPUTS
    read -p "Enter DataRobot App URL(e.g. https://app.datarobot.com): " DATAROBOT_URL
    read -p "Enter DataRobot API Token: " DATAROBOT_API_TOKEN
    
    # REPLACE CONFIGURATION PLACEHOLDERS WITH USER INPUTS
    sed -i -e "s|https:\/\/<MLOPS_HOST>|$DATAROBOT_URL|g" -e "s|<MLOPS_API_TOKEN>|$DATAROBOT_API_TOKEN|g" $AGENT_CONF_LOC
    
    # PRINT & SAVE BASIC MLOPS-AGENT CONFIGURATION LOCALLY
    cat $AGENT_CONF_LOC > /var/tmp/mlops.agent.conf.yaml
    cat $AGENT_CONF_LOC
    echo
    echo "######## MLOPS MONITORING-AGENT CONFIGURATION GENERATED ########"
    echo "./mlops.agent.conf.yaml"
    echo "######################################################"
    echo
}

# PRINT SAMPLE MLOPS-AGENT SAMPLE CONFIGURATION
function config() {
    
    echo "######## MLOPS MONITORING-AGENT SAMPLE CONFIGURATION START ########"
    echo
    cat $AGENT_CONF_LOC
    echo
    echo  "######## MLOPS MONITORING-AGENT SAMPLE CONFIGURATION END ########"
}

# CHECK FOR USER INPUTS
while [ "$#" -ge 1 ]; do
    case "$1" in
        -h | help ) usage; exit 0 ;;
        -c | config ) config; exit 0 ;;
        -g | generate ) generate; exit 0 ;;
        * ) if [ -z "$1" ]; then break; else echo "$1 is not a valid option"; exit 1; fi;;
    esac
    shift
done

# RUN MLOPS AGENT
echo "######## STARTING MLOPS MONITORING-AGENT ########"
echo

if [ -n "$START_DELAY" ] ; then
   echo "Sleeping for $START_DELAY seconds before starting the agent"
   sleep $START_DELAY
fi

exec java $JAVA_OPTIONS \
     -Djava.io.tmpdir=$TMPDIR \
     -Dlog.file=$AGENT_BASE_LOC/logs/mlops.agent.log \
     -Dlog4j.configurationFile=file:$AGENT_BASE_LOC/conf/$AGENT_LOG_PROPERTIES \
     -cp $AGENT_BASE_LOC/mlops-agents.jar \
     com.datarobot.mlops.agent.Agent \
     --config $AGENT_CONF_LOC \
     ${MLOPS_SERVICE_URL:+--mlops-url} "${MLOPS_SERVICE_URL:-}" \
     ${MLOPS_API_TOKEN:+--api-token} "${MLOPS_API_TOKEN:-}"
