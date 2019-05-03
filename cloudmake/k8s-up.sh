#!/usr/bin/env bash

set -e

SELFDIR="$(cd "$(dirname "$(readlink "$0")")"; pwd -P)"

DIND_LABEL=cloudmake $SELFDIR/dind-cluster-v1.13.sh clean 
DIND_LABEL=cloudmake $SELFDIR/dind-cluster-v1.13.sh up 

DAEMON_JSON='{ "insecure-registries": ["cloudmake-registry:5000"] }'

CONTAINERS="master node-1 node-2"
for container in $CONTAINERS; do 
    container_id=kube-$container-cloudmake 
	echo $container_id
    docker exec -i ${container_id} /bin/sh \
			-c "mkdir -p /etc/docker && jq -n '${DAEMON_JSON}' > /etc/docker/daemon.json" 
    docker exec ${container_id} systemctl daemon-reload 
    docker exec ${container_id} systemctl restart docker 
done
