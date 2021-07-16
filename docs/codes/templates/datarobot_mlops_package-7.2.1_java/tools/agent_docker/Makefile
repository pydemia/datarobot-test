#!/usr/bin/make

include ../version.mk

SHELL = /bin/sh

REGISTRY :=
NS := datarobot
IMAGE_NAME := mlops-tracking-agent
ifeq ($(REGISTRY),)
  fq_image := $(NS)/$(IMAGE_NAME)
else
  fq_image := $(REGISTRY)/$(NS)/$(IMAGE_NAME)
endif
VERSION := $(AGENT_VERSION)
DOCKERFILE := Dockerfile
CONTAINER_NAME := mlops-agent
VOLUMES := $(CURDIR):/var/tmp
AGENT_CONF_LOC ?= /opt/datarobot/mlops/agent/conf/mlops.agent.conf.yaml

.PHONY: build run stop remove usage

usage:## > usage - Display MLOps Tracking-Agent Makekfile Targets"
	@echo "-----------------------------------------------------------------------"
	@echo "-                      Available Targets                              -"
	@echo "-----------------------------------------------------------------------"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\t %s\n", $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "-----------------------------------------------------------------------"

.DEFAULT_GOAL := usage

help:## > help - Display MLOps Tracking-Agent help
	@docker run --rm --name $(CONTAINER_NAME) $(fq_image):$(VERSION) help

copy_artifacts:## > copy artifacts - Copy artifacts required to build MLOps Tracking-Agent docker image
	@echo "Copying artifacts required for MLOps Tracking-Agent docker image"
	cp -r ../../lib .
	cp -r ../../conf .

build: copy_artifacts ## > build - To build the MLOps Tracking-Agent Docker image
	@echo "Building MLOps Tracking-Agent docker image"
	-docker pull $(fq_image):latest
	docker build --pull \
		--cache-from $(fq_image):latest \
		-t $(fq_image):$(VERSION) \
		-t $(fq_image):latest \
		--build-arg=version=$(VERSION) \
		-f $(DOCKERFILE) \
		.

push: build ## > push - Pushes the MLOps Tracking-Agent Docker image to a remote registry. Use the NS and REGISTRY variables to control the name of the image that is pushed.
	@echo "Pushing MLOps Tracking-Agent docker image"
	docker push $(fq_image):$(VERSION)
	docker push $(fq_image):latest

start:## > start - To run MLOps Tracking-Agent container
	@echo "Starting MLOps Tracking-Agent container"
	docker run --rm --name $(CONTAINER_NAME) -v $(CURDIR)/mlops.agent.conf.yaml:$(AGENT_CONF_LOC) $(fq_image):$(VERSION)

run:## > run - Build MLOps Tracking-Agent image and start container with defaults
	@echo "Building MLOps Tracking-Agent image and starting container with defaults"
	$(MAKE) build generate start

stop:## > stop - To stop MLOps Tracking-Agent container
	@echo "Stopping MLOps Tracking-Agent docker container"
	docker stop $(CONTAINER_NAME)

config:## > config - To print MLOps Tracking-Agent config(mlops.agent.conf.yaml)"
	@echo "Printing MLOps Tracking-Agent config(mlops.agent.conf.yaml)"
	@docker run --rm --name $(CONTAINER_NAME) $(fq_image):$(VERSION) config

remove:## > remove - To remove the previous MLOps Tracking-Agent container
	docker rm $(CONTAINER_NAME)


generate:## > generate - To Generate MLOps Tracking-Agent configuration file.
	@echo "Generate MLOps Tracking-Agent configuration file."
	@docker run -it --rm  -v $(VOLUMES) --name $(CONTAINER_NAME) $(fq_image):$(VERSION) generate

default: usage
