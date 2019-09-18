#!/bin/sh

# fetching env from vault file.
if test -d /var/run/secrets/nais.io/vault;
then
    for FILE in /var/run/secrets/nais.io/vault/*
    do
        export $(basename ${FILE})=$(cat ${FILE})
    done
fi
export APP_PORT="${APP_PORT:-dev-img}"
export APP_VERSION="${APP_VERSION:-dev-img}"
export GATEWAY_HEADER_NAME="${GATEWAY_HEADER_NAME:-dummy-gw-key}"
export GATEWAY_KEY_API="${GATEWAY_KEY_API:-x-dummy-gateway-key-api-value}"
export GATEWAY_KEY_EXTENSIONS="${GATEWAY_KEY_EXTENSIONS:-x-dummy-gateway-key-extensions-value}"
export GATEWAY_URL="${GATEWAY_URL:-http://localhost:9000}"
export RESOLVER=$(cat /etc/resolv.conf | grep -v '^#' | grep -m 1 nameserver | awk '{print $2}')
export SENTRY_INTERNAL_URL="${SENTRY_INTERNAL_URL:-http://localhost:9000}"

# replace env for nginx conf
envsubst '$APP_PORT $APP_VERSION $GATEWAY_HEADER_NAME $GATEWAY_KEY_API $GATEWAY_KEY_EXTENSIONS $GATEWAY_URL $RESOLVER $SENTRY_INTERNAL_URL' < /etc/nginx/conf.d/app.conf.template > /etc/nginx/conf.d/default.conf

nginx -g 'daemon off;'
exec "$@"
