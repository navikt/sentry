#!/bin/bash

if test -d vault;
then
    for FILE in vault/SENTRY_* vault/GITHUB_*
    do
        echo $(<${FILE})
    done
fi