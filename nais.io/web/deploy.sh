#!/usr/bin/env bash
kubectl config use-context prod-fss
export RELEASE_VERSION="latest"
export APPLICATION_NAME="sentry"
sed "s/RELEASE_VERSION/${RELEASE_VERSION}/g" app.yaml | kubectl apply -f -
kubectl rollout status deployment/${APPLICATION_NAME}
