#!/bin/bash
export SENTRY_CONF="/etc/sentry"

#source ./files/vault.sh

/usr/bin/supervisord -c /etc/sentry/supervisord.conf
exec "$@"
