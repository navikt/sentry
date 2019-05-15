#!/bin/bash
sentry django syncdb  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0100  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0200  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0300  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0400  > /dev/null
sentry upgrade --noinput > /dev/null
sentry exec /usr/src/sentry/files/create_default_projects.py
echo "Upgrade done"
supervisorctl start sentry:*