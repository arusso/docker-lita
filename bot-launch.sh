#!/bin/bash

LITA_BOT=$1
LITA_ENV=${2-dev}
LITA_TAG=${3-latest}

if [[ "$LITA_BOT" == "" ]]; then
  echo "$(basename $0) BOTNAME ENVIRONMENT=dev [TAG=latest]"
  echo ""
  echo "        BOTNAME    Name of bot to run"
  echo "    ENVIRONMENT    Environment file to load for bot. Defaults to dev"
  echo "            TAG    Docker image tag to launch from. Defaults to latest"
  exit 1
fi

if [[ ! -f "bots/${LITA_BOT}/env/$LITA_ENV" ]]; then
  echo "Unable to find settings for bot ${LITA_BOT} environment ${LITA_ENV}"
  exit 1
fi

DOCKER_IMAGE="ucbpi/lita-${LITA_BOT}"
DOCKER_TAG="${3:-latest}"

REDIS_CONTAINER_NAME="lita-${LITA_BOT}-${LITA_ENV}-redis"
APP_CONTAINER_NAME="lita-${LITA_BOT}-${LITA_ENV}-app"

echo "Launching environment ${LITA_ENV}... Using image ${DOCKER_IMAGE}:${DOCKER_TAG}..."
docker run -d --restart unless-stopped --name "${REDIS_CONTAINER_NAME}" redis:latest
docker run -d --restart unless-stopped --name "${APP_CONTAINER_NAME}" --env-file "bots/${LITA_BOT}/env/${LITA_ENV}" --link "${REDIS_CONTAINER_NAME}":redis ${DOCKER_IMAGE}:${DOCKER_TAG}
