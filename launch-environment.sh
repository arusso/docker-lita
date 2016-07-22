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

echo "Launching environment ${LITA_ENV}... Using image ${DOCKER_IMAGE}:${DOCKER_TAG}..."
docker run -d --name "${REDIS_CONTAINER_NAME}" redis:latest
docker run -d --name "${APP_CONTAINER_NAME}" --env-file "env/${LITA_ENV}" --link "${REDIS_CONTAINER_NAME}":redis ${DOCKER_IMAGE}:${DOCKER_TAG}
