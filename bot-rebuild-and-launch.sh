#!/bin/bash
LITA_BOT=$1
LITA_ENV=${2-dev}
LITA_TAG=${3-latest}

if [[ "$LITA_BOT" == "" ]]; then
  echo "$(basename $0) BOTNAME ENVIRONMENT=dev TAG=latest"
  echo ""
  echo "        BOTNAME    Name of bot to run"
  echo "    ENVIRONMENT    Environment data to launch new instance with"
  echo "            TAG    Tag for the resulting docker image. Defaults to latest"
  exit 1
fi

echo "building updated container for bot ${LITA_BOT} with tag ${LITA_TAG}"
DOCKER_IMAGE=ucbpi/lita-${LITA_BOT}:${LITA_TAG}
echo "  container tag: ${DOCKER_IMAGE}"
docker build -t ${DOCKER_IMAGE} bots/${LITA_BOT}/

# kill and reload our environment
./bot-kill.sh   ${LITA_BOT} ${LITA_ENV}
./bot-launch.sh ${LITA_BOT} ${LITA_ENV} ${LITA_TAG}
