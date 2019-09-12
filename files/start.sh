#!/bin/bash
export SENTRY_CONF="/etc/sentry"

/usr/bin/supervisord -c /etc/sentry/supervisord.conf
exec "$@"
