#!/bin/bash
export SENTRY_CONF="/etc/sentry"
# Running this fix first. If things doesn't exists this is really not a problem
sentry exec /usr/src/sentry/files/fix_migration_error_417.py
echo "Done fix_migration_error_417"
sentry upgrade --noinput
echo "Done sentry_upgrade"
sentry exec /usr/src/sentry/files/create_default_projects.py
echo "Done fixing create_default_projects"
sentry exec /usr/src/sentry/files/fix_migration_error_241.py
echo "Done fixing fix_migration_error_241"
supervisorctl start sentry:*