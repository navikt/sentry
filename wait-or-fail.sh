#!/bin/bash

export HEALTHCHECK_URL=localhost:9000/_health/

attempt_counter=0
max_attempts=60

until $(docker run --rm --network container:sentry_web_1 appropriate/curl --output /dev/null --silent --head --fail $HEALTHCHECK_URL); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached, failing"
      exit 1
    fi
    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 10
done