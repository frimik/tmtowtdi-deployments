#!/bin/bash

docker volume create local_registry
docker container run -d \
    --name registry \
    --restart always -p 5000:5000 \
    -v local_registry:/var/lib/registry \
    -e REGISTRY_PROXY_REMOTEURL="https://registry-1.docker.io" \
    registry:2
