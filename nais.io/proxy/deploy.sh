#!/usr/bin/env bash
export RELEASE_VERSION="v$(date +%Y%m%d%H%M)"
export DOCKER_SERVER="repo-fra-laptop-tunnel:14129"
export APPLICATION_NAME="sentry-proxy"
docker build -t "${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}" .
docker push ${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}
echo "Pushed ${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}"
kubectl config use-context prod-sbs
sed "s/RELEASE_VERSION/${RELEASE_VERSION}/g" app.yaml | kubectl apply -f -
kubectl rollout status deployment/${APPLICATION_NAME}
