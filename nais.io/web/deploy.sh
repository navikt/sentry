#!/usr/bin/env bash
kubectl config use-context prod-fss
export RELEASE_VERSION="v0.17"
export APPLICATION_NAME="sentry"
echo "Pushed ${DOCKER_HOST}/${APPLICATION_NAME}:${RELEASE_VERSION}"
sed "s/RELEASE_VERSION/${RELEASE_VERSION}/g" app.yaml | kubectl apply -f -
kubectl rollout status deployment/${APPLICATION_NAME}
