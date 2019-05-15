#!/bin/bash
# fetching env from vault file.
# only grab GITHUB_ and SENTRY_ prefixed files.
if test -d /var/run/secrets/nais.io/vault;
then
    for FILE in /var/run/secrets/nais.io/vault/SENTRY_* /var/run/secrets/nais.io/vault/GITHUB_*
    do
        export $(basename ${FILE})=$(<${FILE})
    done
fi