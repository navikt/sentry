#!/bin/sh

# fetching env from vault file.
if test -d /var/run/secrets/nais.io/vault;
then
    for FILE in /var/run/secrets/nais.io/vault/*
    do
        export $(basename ${FILE})=$(cat ${FILE})
    done
fi
export RESOLVER=$(cat /etc/resolv.conf | grep -v '^#' | grep -m 1 nameserver | awk '{print $2}')
export API_GW_APIKEY="${API_GW_APIKEY:-dummy}"
export API_GW_HEADER="${API_GW_HEADER:-x-dummy}"

# replace env for nginx conf
envsubst '$APP_VERSION $APP_PORT $RESOLVER $API_GATEWAY_URL $API_GW_APIKEY $API_GW_HEADER' < /etc/nginx/conf.d/app.conf.template > /etc/nginx/conf.d/default.conf

nginx -g 'daemon off;'
exec "$@"
