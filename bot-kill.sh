#!/bin/bash
LITA_BOT=$1
LITA_ENV=${2-dev}

if [[ "$LITA_BOT" == "" ]]; then
  echo "$(basename $0) BOTNAME ENVIRONMENT=dev"
  echo ""
  echo "        BOTNAME    Name of bot to run"
  echo "    ENVIRONMENT    Environment file to load for bot. Defaults to dev"
  exit 1
fi

REDIS_CONTAINER_NAME="lita-${LITA_BOT}-${LITA_ENV}-redis"
APP_CONTAINER_NAME="lita-${LITA_BOT}-${LITA_ENV}-app"

echo "Killing ${LITA_BOT} bot environment ${LITA_ENV}"
docker kill $REDIS_CONTAINER_NAME $APP_CONTAINER_NAME 2>/dev/null
docker rm   $REDIS_CONTAINER_NAME $APP_CONTAINER_NAME 2>/dev/null
