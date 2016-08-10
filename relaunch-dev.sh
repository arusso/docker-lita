#!/bin/bash

echo "building update dev container"
docker build -t ucbpi/lita:dev ./

echo "cleaning up existing containers"
./kill-environment dev

echo "launching dev environment"
./launch-environment.sh dev dev
