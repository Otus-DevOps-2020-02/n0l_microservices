SHELL = /bin/sh
USER_NAME=xmanchan

### adding variables for images versions ###
include ./docker/.env

### Build images ###
build_comment:
	cd ./src/comment && bash ./docker_build.sh

build_post:
	cd ./src/post-py && bash ./docker_build.sh

build_ui:
	cd ./src/ui && bash ./docker_build.sh

build_prometheus:
	cd ./monitoring/prometheus && bash ./docker_build.sh

build_mongodbexporter:
	cd ./monitoring/mongodb-exporter && bash ./docker_build.sh

build_blackbox-exporter:
	cd ./monitoring/blackbox-exporter && bash ./docker_build.sh

build_all: build_post build_comment build_ui build_mongodbexporter build_blackbox-exporter build_prometheus

### start env ####

start_all:
	echo '-- starting environment --'
	docker-compose --project-directory docker -f docker/docker-compose.yml up -d

### stop env ###

stop_all:
	echo '-- stopping environment --'
	docker-compose --project-directory docker -f docker/docker-compose.yml down

### push images ###

push_comment:
	docker push $(USER_NAME)/comment:latest

push_post:
	docker push ${USER_NAME}/post:latest

push_ui:
	docker push ${USER_NAME}/ui:latest

push_prometheus:
	docker push ${USER_NAME}/prometheus:latest

push_mongodbexporter:
	docker push ${USER_NAME}/percona-mongodb-exporter:${VER-DB-EXPORTER}

push_blackbox-exporter:
	docker push ${USER_NAME}/blackbox-exporter:${VER-BLACKBOX-EXPORTER}

push_all: push_comment push_post push_ui push_mongodbexporter push_blackbox-exporter push_prometheus