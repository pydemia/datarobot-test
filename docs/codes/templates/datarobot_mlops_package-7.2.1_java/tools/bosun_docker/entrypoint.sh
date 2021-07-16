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

    BOSUN_BASE_LOC
        Location of your MLOps Management-Agent base install.
    BOSUN_CONF_LOC
        Location of your MLOps Management-Agent configuration file(e.g. /var/tmp/mlops.bosun.conf). This option allow you to configure the location of
        MLOps Management-Agent configuration.
    BOSUN_LOG_PROPERTIES
        Configure logging properties of MLOps Management-Agent. mlops.log4j2.properties(FILE) and stdout.mlops.log4j2.properties(STDOUT) are available
        or mount your onw log4j2.properties.
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

  Run with external management agent configuration mounted default:
    $ docker run \\
        -v /path/to/mlops.bosun.conf.yaml:/opt/datarobot/mlops/bosun/conf/mlops.bosun.conf.yaml \\
        datarobot-mlops-bosun

  Run with external management agent configuration mounted in custom location:
    $ docker run \\
        -v /path/to/mlops.bosun.conf.yaml:/var/tmp \\
        -e BOSUN_CONF_LOC=/var/tmp \\
        datarobot-mlops-bosun

  Run with mlops-agent log directed to stdout:
    $ docker run \\
        -v /path/to/mlops.bosun.conf.yaml:/var/tmp \\
        -e BOSUN_LOG_PROPERTIES=stdout.mlops.log4j2.properties
        datarobot-mlops-bosun

EOF
}

# GENERATE BASIC MLOPS-AGENT CONFIGURATION
function generate() {
    # READ INPUTS
    read -p "Enter DataRobot App URL (e.g. https://app.datarobot.com): " DATAROBOT_URL
    read -p "Enter DataRobot API Token: " DATAROBOT_API_TOKEN
    read -p "Enter DataRobot Prediction Environment ID: " DATAROBOT_PRED_ENV
    
    # REPLACE CONFIGURATION PLACEHOLDERS WITH USER INPUTS
    sed -i \
        -e "s|https:\/\/<MLOPS_HOST>|$DATAROBOT_URL|g" \
	-e "s|<MLOPS_API_TOKEN>|$DATAROBOT_API_TOKEN|g" \
	-e "s|<MLOPS_PREDICTION_ENV_ID>|$DATAROBOT_PRED_ENV|g" \
	-e "s|<CONF_PATH>|${BOSUN_BASE_LOC}/conf|g" \
	-e "s|<BOSUN_VENV_PATH>\/||g" \
	$BOSUN_CONF_LOC
    
    # PRINT & SAVE BASIC MLOPS-AGENT CONFIGURATION LOCALLY
    cat $BOSUN_CONF_LOC > /var/tmp/mlops.bosun.conf.yaml
    cat $BOSUN_CONF_LOC
    echo
    echo "######## MLOPS MANAGEMENT-AGENT CONFIGURATION GENERATED ########"
    echo "./mlops.bosun.conf.yaml"
    echo "######################################################"
    echo
}

# PRINT SAMPLE MLOPS-AGENT SAMPLE CONFIGURATION
function config() {
    
    echo "######## MLOPS MANAGEMENT-AGENT SAMPLE CONFIGURATION START ########"
    echo
    cat $BOSUN_CONF_LOC
    echo
    echo  "######## MLOPS MANAGEMENT-AGENT SAMPLE CONFIGURATION END ########"
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
echo "######## STARTING MLOPS MANAGEMENT-AGENT ########"
echo

if [ -n "$START_DELAY" ] ; then
   echo "Sleeping for $START_DELAY seconds before starting the agent"
   sleep $START_DELAY
fi

exec java $JAVA_OPTIONS \
     -Djava.io.tmpdir=$TMPDIR \
     -Dlog.file=$BOSUN_BASE_LOC/logs/mlops.bosun.log \
     -Dlog4j.configurationFile=file:$BOSUN_BASE_LOC/conf/$BOSUN_LOG_PROPERTIES \
     -cp $BOSUN_BASE_LOC/mlops-agents.jar \
     com.datarobot.mlops.agent.Agent --manage \
     --config $BOSUN_CONF_LOC \
     ${MLOPS_API_TOKEN:+--api-token} "${MLOPS_API_TOKEN:-}"
