#!/usr/bin/env bash
if [[ -z "$1" ]]; then
    echo "first argument need to be a password eg. ./files/createuser.sh v3rrYs3cre7" 1>&2
    exit 1
fi

sentry createuser --email admin@sentry.local --superuser --password $1
