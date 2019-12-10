#!/usr/bin/env bash
vault() {
  vault_binary=/usr/local/bin/vault
  if [ ! -f ~/.vault-token ] || [ ! -f ~/.vault-token-eol ] || [[ $(date +%s) -gt $(cat ~/.vault-token-eol) ]]; then
    HTTPS_PROXY=socks5://localhost:14122 $vault_binary login -method oidc >&2
    HTTPS_PROXY=socks5://localhost:14122 $vault_binary token lookup --format json | jq '[ .data.creation_time, .data.creation_ttl ] | add' > ~/.vault-token-eol
  fi

  HTTPS_PROXY=socks5://localhost:14122 $vault_binary $@
}

vault_secrets=$(vault read /secret/aura/sentry --format=json)
vault_secret() {
  echo -n "${1}="
  echo -n $vault_secrets | jq -r ".data[\"$1\"]"
}

enc_key=$(echo -n $vault_secrets | jq -r '.data["terraform_enc-key"]')

openssl enc -d -aes-256-cbc -a -A -md md5 -k "$enc_key" < "sa.json.enc" > sa.json
export GOOGLE_APPLICATION_CREDENTIALS=./sa.json
terraform init

terraform apply \
  -var "sentry_image=sentry:9.1.2" \
  -var "$(vault_secret scaleft_enrollment_token)" \
  -var "$(vault_secret sentry_secret_key)" \
  -var "$(vault_secret sentry_db_name)" \
  -var "$(vault_secret sentry_db_user)" \
  -var "$(vault_secret sentry_db_password)" \
  -var "$(vault_secret sentry_slack_client_id)" \
  -var "$(vault_secret sentry_slack_client_secret)" \
  -var "$(vault_secret sentry_slack_verification_token)" #\
  #-var "github_app_name=sentry-on-prem" \
  #-var "$(vault_secret github_api_secret)" \
  #-var "$(vault_secret github_app_client_id)" \
  #-var "$(vault_secret github_app_client_secret)" \
  #-var "$(vault_secret github_app_id)" \
  #-var "$(vault_secret github_app_private_key)" \
  #-var "$(vault_secret github_app_webhook_secret)"

rm sa.json
