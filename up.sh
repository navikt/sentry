#!/bin/bash
#docker-compose down
docker-compose up --build --remove-orphans -d
./wait-or-fail.sh