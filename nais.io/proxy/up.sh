#!/usr/bin/env bash
docker stop sentry-proxy
docker rm sentry-proxy
docker build . -t sentry-proxy
docker run -d --name sentry-proxy -e API_GATEWAY_URL=https://localhost:9000  -p 8043:8043 sentry-proxy