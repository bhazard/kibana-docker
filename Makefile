SHELL=/bin/bash
export PATH := ./bin:./venv/bin:$(PATH)
export VIRTUALENV_PYTHON=python3.6

ifndef ELASTIC_VERSION
ELASTIC_VERSION := $(shell cat version.txt)
endif

ifdef STAGING_BUILD_NUM
VERSION_TAG=$(ELASTIC_VERSION)-${STAGING_BUILD_NUM}
else
VERSION_TAG=$(ELASTIC_VERSION)
endif

ELASTIC_REGISTRY=docker.elastic.co
VERSIONED_IMAGE=$(ELASTIC_REGISTRY)/kibana/kibana:$(VERSION_TAG)

test: lint build docker-compose.yml
	./bin/testinfra tests

lint: venv
	  flake8 tests

build: dockerfile
	docker build --pull -t $(VERSIONED_IMAGE) build/kibana

push: test
	docker push $(VERSIONED_IMAGE)

clean-test:
	$(TEST_COMPOSE) down
	$(TEST_COMPOSE) rm --force

venv: requirements.txt
	test -d venv || virtualenv venv
	pip install -r requirements.txt
	touch venv

# Generate the Dockerfile from a Jinja2 template.
dockerfile: venv
	jinja2 \
	  -D version_tag='$(VERSION_TAG)' \
	  templates/Dockerfile.j2 > build/kibana/Dockerfile

# Generate docker-compose.yml from a Jinja2 template.
docker-compose.yml: venv
	jinja2 \
	  -D version_tag='$(VERSION_TAG)' \
	  templates/docker-compose.yml.j2 > docker-compose.yml

.PHONY: build clean flake8 push pytest test dockerfile docker-compose.yml
