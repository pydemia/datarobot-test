#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# IDENTIFY MLOPS-AGENT IMAGES AND CONTAINERS
NS=datarobot
IMAGE_NAME='mlops-tracking-agent'
CONTAINER_NAME="mlops-agent"
DOCKERFILE="Dockerfile"
VERSION="latest"
AGENT_CONF_LOC=${AGENT_CONF_LOC:="/opt/datarobot/mlops/agent/conf/mlops.agent.conf.yaml"}

usage() {
    echo "-----------------------------------------------------------------------"
    echo "-                      Available Commands                             -"
    echo "-----------------------------------------------------------------------"
    echo ""
    echo "\t> usage - Display run.sh Available Commands"
    echo "\t> help - Display MLOps Monitoring-Agent help"
    echo "\t> build - To build the MLOps Monitoring-Agent Docker image"
    echo "\t> start - To run MLOps Monitoring-Agent container"
    echo "\t> run - Build MLOps Monitoring-Agent image and start container with defaults"
    echo "\t> stop - To stop MLOps Monitoring-Agent container"
    echo "\t> config - To print MLOps Monitoring-Agent config(mlops.agent.conf.yaml)"
    echo "\t> remove - To remove the previous MLOps Monitoring-Agent container"
    echo "\t> generate - To Generate MLOps Monitoring-Agent configuration file."
    echo ""
    echo "-----------------------------------------------------------------------"

}

# LOG FUNCTION
log() {
    echo "> $1"
}


help() {
    docker run --rm --name $CONTAINER_NAME $NS/$IMAGE_NAME:$VERSION help

}

copy_artifacts() {
    log "Copying artifacts required for MLOps Monitoring-Agent docker image"
    cp -r ${SCRIPT_DIR}/../../lib ${SCRIPT_DIR}
    cp -r ${SCRIPT_DIR}/../../conf ${SCRIPT_DIR}

}

build() {
  # need to copy files used to build the docker image into the tools/agent_docker path
    copy_artifacts
    log "Building MLOps Monitoring-Agent docker image"
    docker build -t $NS/$IMAGE_NAME:$VERSION -f $DOCKERFILE .

}

start() {
    log "Starting MLOps Monitoring-Agent container"
    docker run --rm --name $CONTAINER_NAME \
    -v $(PWD)/mlops.agent.conf.yaml:$AGENT_CONF_LOC \
    $NS/$IMAGE_NAME:$VERSION

}

run() {
    log "Building MLOps Monitoring-Agent image and starting container with defaults"
    build
    generate
    start

}

stop() {
    log "Stopping MLOps Monitoring-Agent docker container"
    docker stop $CONTAINER_NAME

}

config() {
	log "Printing MLOps Monitoring-Agent config(mlops.agent.conf.yaml)"
	docker run --rm --name $CONTAINER_NAME $NS/$IMAGE_NAME:$VERSION config

}

remove() {
    log "Removing previous MLOps Monitoring-Agent container:: $CONTAINER_NAME" && \
    docker rm -f $CONTAINER_NAME &> /dev/null || true

}

generate() {
    log "Generate basic MLOps Monitoring-Agent configuration file."
    docker run -it --rm  -v $(PWD):/var/tmp --name $CONTAINER_NAME $NS/$IMAGE_NAME:$VERSION generate

}

if [[ $# -eq 0 ]] ; then
    usage
    return 0
fi

$*
