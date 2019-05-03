#!/usr/bin/env bash 

REGISTRY=${REGISTRY:-"localhost:5000"}
SOURCE=${IMAGE}
TARGET=$REGISTRY/$SOURCE

docker tag $SOURCE $TARGET
docker push $TARGET 
docker rmi $TARGET
