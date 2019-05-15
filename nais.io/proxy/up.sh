#!/usr/bin/env bash
docker stop sentry-proxy
docker rm sentry-proxy
docker build . -t sentry-proxy
docker run -d --name sentry-proxy -e API_GATEWAY_URL=https://sentry.nais.adeo.no  -p 8043:8043 sentry-proxy