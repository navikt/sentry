#!/bin/bash

# Running this fix first. If things doesn't exists this is really not a problem
sentry exec /usr/src/sentry/files/fix_migration_error_417.py
sentry django syncdb  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0100  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0200  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0300  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0400  > /dev/null
sentry django migrate --merge --ignore-ghost-migrations --noinput sentry 0500  > /dev/null
sentry upgrade --noinput > /dev/null
sentry exec /usr/src/sentry/files/create_default_projects.py
echo "Upgrade done"
supervisorctl start sentry:*