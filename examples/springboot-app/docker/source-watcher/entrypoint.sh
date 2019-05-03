#!/bin/sh 

sleep 10
while true; do
    inotifywait --recursive --event modify --event create /app/src && \
    docker exec $TARGET_CONTAINER mvn package;
done
