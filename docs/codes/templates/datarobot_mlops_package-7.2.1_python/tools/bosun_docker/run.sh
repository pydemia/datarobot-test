#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# IDENTIFY MLOPS-AGENT IMAGES AND CONTAINERS
NS=datarobot
IMAGE_NAME='mlops-management-agent'
CONTAINER_NAME="mlops-bosun"
DOCKERFILE="Dockerfile"
VERSION="latest"
BOSUN_CONF_LOC=${BOSUN_CONF_LOC:="/opt/datarobot/mlops/bosun/conf/mlops.bosun.conf.yaml"}

usage() {
    echo "-----------------------------------------------------------------------"
    echo "-                      Available Commands                             -"
    echo "-----------------------------------------------------------------------"
    echo ""
    echo "\t> usage - Display run.sh Available Commands"
    echo "\t> help - Display MLOps Management-Agent help"
    echo "\t> build - To build the MLOps Management-Agent Docker image"
    echo "\t> start - To run MLOps Management-Agent container"
    echo "\t> run - Build MLOps Management-Agent image and start container with defaults"
    echo "\t> stop - To stop MLOps Management-Agent container"
    echo "\t> config - To print MLOps Management-Agent config(mlops.bosun.conf.yaml)"
    echo "\t> remove - To remove the previous MLOps Management-Agent container"
    echo "\t> generate - To Generate MLOps Management-Agent configuration file."
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
    log "Copying artifacts required for MLOps Management-Agent docker image"
    cp -r ${SCRIPT_DIR}/../../lib ${SCRIPT_DIR}
    cp -r ${SCRIPT_DIR}/../../conf ${SCRIPT_DIR}

}

build() {
  # need to copy files used to build the docker image into the tools/bosun_docker path
    copy_artifacts
    log "Building MLOps Management-Agent docker image"
    docker build -t $NS/$IMAGE_NAME:$VERSION -f $DOCKERFILE .

}

start() {
    log "Starting MLOps Management-Agent container"
    docker run --rm --name $CONTAINER_NAME \
    -v $(PWD)/mlops.bosun.conf.yaml:$BOSUN_CONF_LOC \
    $NS/$IMAGE_NAME:$VERSION

}

run() {
    log "Building MLOps Management-Agent image and starting container with defaults"
    build
    generate
    start

}

stop() {
    log "Stopping MLOps Management-Agent docker container"
    docker stop $CONTAINER_NAME

}

config() {
	log "Printing MLOps Management-Agent config(mlops.bosun.conf.yaml)"
	docker run --rm --name $CONTAINER_NAME $NS/$IMAGE_NAME:$VERSION config

}

remove() {
    log "Removing previous MLOps Management-Agent container:: $CONTAINER_NAME" && \
    docker rm -f $CONTAINER_NAME &> /dev/null || true

}

generate() {
    log "Generate basic MLOps Management-Agent configuration file."
    docker run -it --rm  -v $(PWD):/var/tmp --name $CONTAINER_NAME $NS/$IMAGE_NAME:$VERSION generate

}

if [[ $# -eq 0 ]] ; then
    usage
    return 0
fi

$*
