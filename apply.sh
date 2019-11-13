#!/usr/bin/env bash
vault() {
  vault_binary=/usr/local/bin/vault
  if [ ! -f ~/.vault-token ] || [ ! -f ~/.vault-token-eol ] || [ $(date +%s) -gt $(cat ~/.vault-token-eol) ]; then
    HTTPS_PROXY=socks5://localhost:14122 $vault_binary login -method oidc >&2
    HTTPS_PROXY=socks5://localhost:14122 $vault_binary token lookup --format json | jq '[ .data.creation_time, .data.creation_ttl ] | add' > ~/.vault-token-eol
  fi

  HTTPS_PROXY=socks5://localhost:14122 $vault_binary $@
}

vault_secrets=$(vault read /secret/aura/sentry --format=json)
enc_key=$(echo -n $vault_secrets | jq -r '.data["terraform_enc-key"]')
db_password=$(echo -n $vault_secrets | jq -r '.data["db_password"]')
openssl enc -d -aes-256-cbc -a -A -md md5 -k "$enc_key" < "sa.json.enc" > sa.json
cat sa.json
export GOOGLE_APPLICATION_CREDENTIALS=./sa.json
terraform init
terraform apply -var "db_password=$db_password"
rm sa.json
