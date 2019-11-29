#!/bin/bash
# install sentry
cd /var/lib
sudo git clone https://github.com/getsentry/onpremise
cd onpremise
sudo git checkout origin/stable -b stable
cd ..
sudo mv onpremise sentry
cd sentry

cat > requirements.txt <<EOF
https://github.com/getsentry/sentry-auth-github/archive/master.zip
EOF

cat > config.yml <<EOF
github-app.id: ${github_app_id}
github-app.name: ${github_app_name}
github-app.webhook-secret: ${github_app_webhook_secret}
github-app.private-key: ${github_app_private_key}
github-app.client-id: ${github_app_client_id}
github-app.client-secret: ${github_app_client_secret}
EOF

cat > docker-compose.yml <<EOF
version: '3.4'

x-defaults: &defaults
  restart: unless-stopped
  build:
    context: .
    args:
      SENTRY_IMAGE: ${sentry_image}
  depends_on:
    - memcached
    - smtp
  env_file: .env
  environment:
    SENTRY_MEMCACHED_HOST: memcached
    SENTRY_EMAIL_HOST: smtp
  volumes:
    - sentry-data:/var/lib/sentry/files
    - /var/lib/sentry/config.yml:/etc/sentry/config.yml:ro


services:
  smtp:
    restart: unless-stopped
    image: tianon/exim4

  memcached:
    restart: unless-stopped
    image: memcached:1.5-alpine

  web:
    <<: *defaults
    ports:
      - '80:9000'
      - '9000:9000'

  cron:
    <<: *defaults
    command: run cron

  worker:
    <<: *defaults
    command: run worker


volumes:
    sentry-data:
      external: true
EOF

cat > .env <<EOF
SENTRY_SECRET_KEY=${sentry_secret_key}
SENTRY_POSTGRES_HOST=${sentry_postgres_host}
SENTRY_POSTGRES_PORT=${sentry_postgres_port}
SENTRY_DB_NAME=${sentry_db_name}
SENTRY_DB_USER=${sentry_db_user}
SENTRY_DB_PASSWORD=${sentry_db_password}
SENTRY_REDIS_HOST=${sentry_redis_host}
#  SENTRY_REDIS_PASSWORD=
SENTRY_REDIS_PORT=${sentry_redis_port}
#  SENTRY_REDIS_DB=
#  SENTRY_SINGLE_ORGANIZATION=
SENTRY_SLACK_CLIENT_ID=${sentry_slack_client_id}
SENTRY_SLACK_CLIENT_SECRET=${sentry_slack_client_secret}
SENTRY_SLACK_VERIFICATION_TOKEN=${sentry_slack_verification_token}
GITHUB_APP_ID=${github_app_id}
GITHUB_API_SECRET=${github_api_secret}
#SENTRY_GITHUB_APP_ID=
#SENTRY_GITHUB_APP_CLIENT_ID=${github_app_client_id}
#SENTRY_GITHUB_APP_CLIENT_SECRET=
#SENTRY_GITHUB_APP_WEBHOOK_SECRET=${github_app_webhook_secret}
#SENTRY_GITHUB_APP_PRIVATE_KEY=
SENTRY_SYSTEM_URL_PREFIX=https://${sentry_external_url}
EOF

# ./install.sh

set -e

DID_CLEAN_UP=0
# the cleanup function will be the exit point
cleanup () {
  if [ "$DID_CLEAN_UP" -eq 1 ]; then
    return 0;
  fi
  echo "Cleaning up..."
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.24.0 down &> /dev/null
  DID_CLEAN_UP=1
}
trap cleanup ERR INT TERM

echo "Created $(docker volume create --name=sentry-data)."
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.24.0 build
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.24.0 run --rm web upgrade --noinput

cleanup

# start sentry
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:$PWD" \
    -w="$PWD" \
    docker/compose:1.24.0 up -d
