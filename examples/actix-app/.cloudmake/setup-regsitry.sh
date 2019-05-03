container_id=$1
json='{ "insecure-registry": ["cloudmake-registry:5000"] }'

docker exec -i ${container_id} /bin/sh -c "mkdir -p /etc/docker && jq -n '${json}' > /etc/docker/daemon.json"                                                       
docker exec ${container_id} systemctl daemon-reload                                                                                                                 
docker exec ${container_id} systemctl restart docker
