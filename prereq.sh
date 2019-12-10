#!/usr/bin/env bash
project_id=$project_id
gcloud --project "$project_id" iam service-accounts create terraform
gcloud --project "$project_id" iam service-accounts keys create --iam-account="terraform@${project_id}.iam.gserviceaccount.com" sa.json
gcloud projects add-iam-policy-binding "$project_id" --member "serviceAccount:terraform@${project_id}.iam.gserviceaccount.com" --role roles/owner

openssl enc -e -aes-256-cbc -a -A -md md5 -k "$(vault read /secret/aura/sentry --format=json | jq -r '.data["terraform_enc-key"]')" < sa.json > sa.json.enc
rm sa.json

gcloud services enable redis.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com
