FROM nginx:alpine
COPY start-nginx.sh       /usr/sbin/start-nginx
RUN chmod u+x /usr/sbin/start-nginx
ENV APP_PORT=8043
EXPOSE 80 8043
COPY default-config.nginx /etc/nginx/conf.d/app.conf.template
CMD ["start-nginx"]
