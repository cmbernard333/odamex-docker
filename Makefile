-include ../*.mk
-include *.mk



NS ?= cmbernard333

IMAGE_NAME ?= odamex-server
CONTAINER_NAME ?= odamex-server
CONTAINER_INSTANCE ?= default
REPO_URL ?= https://github.com/odamex/odamex.git

VCS_REF := $(strip $(shell git rev-parse --short HEAD))
BUILD_DATE := $(strip $(shell date -u +"%Y-%m-%dT%H:%M:%SZ"))
VERSION := $(strip $(shell cat VERSION))
REPO_TAG := $(VERSION)
ODA_TARGET ?= odasrv 

ifndef VERSION
$(error You need to create a VERSION file to build a release)
endif

ifndef TAG
TAG := testing
endif



.PHONY: build shell debug run start stop rm rmi test clean



default: build



build:
	docker build \
	--no-cache \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--build-arg VERSION=$(VERSION) \
	--build-arg REPO_URL=$(REPO_URL) \
	--build-arg REPO_TAG=$(REPO_TAG) \
	-t $(NS)/$(IMAGE_NAME):$(TAG) .

shell:
	-docker run -it --rm --name $(CONTAINER_NAME)_$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(OTHER) $(ENV) $(NS)/$(IMAGE_NAME):$(TAG) /bin/bash

run:
	-docker run --rm --name $(CONTAINER_NAME)_$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(OTHER) $(ENV) $(NS)/$(IMAGE_NAME):$(TAG)

start:
	-docker run -d --name $(CONTAINER_NAME)_$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(OTHER) $(ENV) $(NS)/$(IMAGE_NAME):$(TAG)

stop:
	-docker stop $(CONTAINER_NAME)_$(CONTAINER_INSTANCE)

rm:
	-docker rm $(CONTAINER_NAME)_$(CONTAINER_INSTANCE)

rmi:
	-docker rmi $(NS)/$(IMAGE_NAME):$(TAG)

test:
	@echo docker build \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--build-arg VERSION=$(VERSION) \
	-t $(NS)/$(IMAGE_NAME):$(TAG) .

clean: stop rm rmi
