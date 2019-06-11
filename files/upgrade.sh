#!/bin/bash

# Running this fix first. If things doesn't exists this is really not a problem
sentry exec /usr/src/sentry/files/fix_migration_error_417.py
sentry django syncdb
sentry upgrade --noinput
sentry exec /usr/src/sentry/files/create_default_projects.py
sentry exec /usr/src/sentry/files/fix_migration_error_241.py
echo "Upgrade done"
supervisorctl start sentry:*