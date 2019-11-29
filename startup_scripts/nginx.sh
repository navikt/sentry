#!/bin/bash
# install sentry
echo "running cloud init" >> /tmp/log.txt
mkdir -p /var/lib/nginx

cat > /var/lib/nginx/default.conf <<'EOF'
access_log off; # Handled gcloud ELB
error_log /dev/stdout info;
charset utf-8;
client_body_buffer_size 10M; # Default er satt veldig lavt. Faar problemer med enkelte dokument queries.
proxy_buffering off;
tcp_nodelay off; ## No need to bleed constant updates. Send the all shebang in one fell swoop.
tcp_nopush off;
gzip off;
gzip_proxied any;
absolute_redirect off; # minor change

gzip_types
    text/css
    text/javascript
    text/xml
    text/plain
    application/javascript
    application/x-javascript
    application/json
    application/xml
    application/rss+xml
    application/atom+xml
    font/truetype
    font/opentype
    image/svg+xml;

server {
    listen 80;
    server_name  _;

    # Proxy headers. Will be overwritten if you set them in blocks.
    proxy_hide_header       Content-Security-Policy;
    proxy_hide_header       Set-Cookie;
    proxy_hide_header       cookie;
    proxy_ignore_headers    Set-Cookie; # We don't want the backend to set cookies.
    proxy_intercept_errors  off;
    proxy_pass_header       Nav-Callid;
    proxy_redirect          off;
    proxy_set_header        Connection "";
    proxy_set_header        Referer $http_referer;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        Cookie "";

    # Readiness check for NAIS
    location = /health/isReady {
        return 200          "Application:READY";
        default_type        text/plain;
    }

    # Just slap frontend directly to the prefix
    location / {
        return 200          "Sentry Proxy";
        default_type        text/plain;
    }

    # Auth redirect (no proxy)
    location = /auth/sso/ {
        return 302          "http://${sentry_internal_url}$request_uri";
    }
    location = /extensions/slack/setup/ {
        return 302          "http://${sentry_internal_url}$request_uri";
    }
    location = /extensions/github/setup/ {
        return 302          "http://${sentry_internal_url}$request_uri";
    }
    location  ~ ^/([a-z\-]+)/([a-z\-]+)/issues/(\d+\/.*) {
        return 301          "http://${sentry_internal_url}$request_uri";
    }

    # Collect endpoints
    location ~ ^/api/(\d+\/store\/.*) {
        proxy_pass          "http://${sentry_internal_ip}/api/$1$is_args$args";
    }

    location ~ ^/api/(\d+\/csp-report\/.*) {
        proxy_pass          "http://${sentry_internal_ip}/api/$1$is_args$args";
    }

    location ~ ^/api/(\d+\/unreal\/.*) {
        proxy_pass          "http://${sentry_internal_ip}/api/$1$is_args$args";
    }

    location ~ ^/api/(\d+\/security\/.*) {
        proxy_pass          "http://${sentry_internal_ip}/api/$1$is_args$args";
    }

    location ~ ^/api/(\d+\/minidump\/.*) {
        proxy_pass          "http://${sentry_internal_ip}/api/$1$is_args$args";
    }

    # Slack integration
    location ~ ^/extensions/slack/action/.* {
        proxy_pass          "http://${sentry_internal_ip}/extensions/slack/action/$is_args$args";
    }

    location ~ ^/extensions/slack/options-load/.* {
        proxy_pass          "http://${sentry_internal_ip}/extensions/slack/options-load/$is_args$args";
    }

    location ~ ^/extensions/slack/event/.* {
        proxy_pass          "http://${sentry_internal_ip}/extensions/slack/event/$is_args$args";
    }

    # Github integration
    location ~ ^/extensions/github/webhook/.* {
        proxy_pass          "http://${sentry_internal_ip}/extensions/github/webhook/$is_args$args";
    }
}
EOF

echo "starting container" >> /tmp/log.txt
# start sentry proxy
docker run --rm \
    -p 80:80 \
    --name nginx \
    -v /var/run \
    -v /var/cache/nginx \
    -v /var/lib/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
    --read-only \
    -d \
    ${nginx_image}
echo "cloud init done" >> /tmp/log.txt
