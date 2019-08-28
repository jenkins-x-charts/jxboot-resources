CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := jxboot-resources
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io

build: clean setup
	helm dependency build jxboot-resources
	helm lint jxboot-resources

install: clean build
	helm upgrade ${NAME} jxboot-resources --install

upgrade: clean build
	helm upgrade ${NAME} jxboot-resources --install

delete:
	helm delete --purge ${NAME} jxboot-resources

clean:
	rm -rf jxboot-resources/charts
	rm -rf jxboot-resources/${NAME}*.tgz
	rm -rf jxboot-resources/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" jxboot-resources/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" jxboot-resources/Chart.yaml
else
	exit -1
endif
	helm package jxboot-resources
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
