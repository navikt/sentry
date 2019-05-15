#!/usr/bin/env bash
kubectl config use-context prod-fss
kubectl apply -f app.yaml
kubectl rollout status deployment/sentry-redis
