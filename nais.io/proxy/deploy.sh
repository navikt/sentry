#!/usr/bin/env bash
kubectl config use-context prod-sbs
export RELEASE_VERSION="v$(date +%Y%m%d%H%M)"
export DOCKER_SERVER="repo.adeo.no:5443"
export APPLICATION_NAME="sentry-proxy"
docker build -t "${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}" .
docker push ${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}
echo "Pushed ${DOCKER_SERVER}/${APPLICATION_NAME}:${RELEASE_VERSION}"
sed "s/RELEASE_VERSION/${RELEASE_VERSION}/g" app.yaml | kubectl apply -f -
kubectl rollout status deployment/${APPLICATION_NAME}
