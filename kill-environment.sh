#!/bin/bash

LITA_ENV=$1
if [[ ! -f "env/$LITA_ENV" ]]; then
  echo "Unable to find settings for environment ${LITA_ENV}"
  exit 1
fi

DOCKER_IMAGE="ucbpi/lita"
DOCKER_TAG="${2:-latest}"

REDIS_CONTAINER_NAME="lita-redis-${LITA_ENV}"
APP_CONTAINER_NAME="lita-app-${LITA_ENV}"

echo "Killing environment ${LITA_ENV}"
for i in lita-{app,redis}-${LITA_ENV}; do
  docker kill $i
  docker rm $i
done
