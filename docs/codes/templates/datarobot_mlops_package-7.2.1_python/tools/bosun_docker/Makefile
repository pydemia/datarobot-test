#!/usr/bin/make

include ../version.mk

SHELL = /bin/sh

REGISTRY :=
NS := datarobot
IMAGE_NAME := mlops-management-agent
ifeq ($(REGISTRY),)
  fq_image := $(NS)/$(IMAGE_NAME)
else
  fq_image := $(REGISTRY)/$(NS)/$(IMAGE_NAME)
endif
VERSION := $(BOSUN_VERSION)
DOCKERFILE := Dockerfile
CONTAINER_NAME := mlops-bosun
VOLUMES := $(CURDIR):/var/tmp
BOSUN_CONF_LOC ?= /opt/datarobot/mlops/bosun/conf/mlops.bosun.conf.yaml

.PHONY: build run stop remove usage

usage:## > usage - Display MLOps Management-Agent Makekfile Targets"
	@echo "-----------------------------------------------------------------------"
	@echo "-                      Available Targets                              -"
	@echo "-----------------------------------------------------------------------"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\t %s\n", $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "-----------------------------------------------------------------------"

.DEFAULT_GOAL := usage

help:## > help - Display MLOps Management-Agent help
	@docker run --rm --name $(CONTAINER_NAME) $(fq_image):$(VERSION) help

copy_artifacts:## > copy artifacts - Copy artifacts required to build MLOps Management-Agent docker image
	@echo "Copying artifacts required for MLOps Management-Agent docker image"
	cp -r ../../lib .
	cp -r ../../conf .

build: copy_artifacts ## > build - To build the MLOps Management-Agent Docker image
	@echo "Building MLOps Management-Agent docker image"
	-docker pull $(fq_image):latest
	docker build --pull \
		--cache-from $(fq_image):latest \
		-t $(fq_image):$(VERSION) \
		-t $(fq_image):latest \
		--build-arg=version=$(VERSION) \
		-f $(DOCKERFILE) \
		.

push: build ## > push - Pushes the MLOps Management-Agent Docker image to a remote registry. Use the NS and REGISTRY variables to control the name of the image that is pushed.
	@echo "Pushing MLOps Management-Agent docker image"
	docker push $(fq_image):$(VERSION)
	docker push $(fq_image):latest

start:## > start - To run MLOps Management-Agent container
	@echo "Starting MLOps Management-Agent container"
	docker run --rm --name $(CONTAINER_NAME) -v $(CURDIR)/mlops.bosun.conf.yaml:$(BOSUN_CONF_LOC) $(fq_image):$(VERSION)

run:## > run - Build MLOps Management-Agent image and start container with defaults
	@echo "Building MLOps Management-Agent image and starting container with defaults"
	$(MAKE) build generate start

stop:## > stop - To stop MLOps Management-Agent container
	@echo "Stopping MLOps Management-Agent docker container"
	docker stop $(CONTAINER_NAME)

config:## > config - To print MLOps Management-Agent config(mlops.bosun.conf.yaml)"
	@echo "Printing MLOps Management-Agent config(mlops.bosun.conf.yaml)"
	@docker run --rm --name $(CONTAINER_NAME) $(fq_image):$(VERSION) config

remove:## > remove - To remove the previous MLOps Management-Agent container
	docker rm $(CONTAINER_NAME)


generate:## > generate - To Generate MLOps Management-Agent configuration file.
	@echo "Generate MLOps Management-Agent configuration file."
	@docker run -it --rm  -v $(VOLUMES) --name $(CONTAINER_NAME) $(fq_image):$(VERSION) generate

default: usage
