#!/bin/bash

/usr/bin/supervisord -c /etc/sentry/supervisord.conf
exec "$@"
