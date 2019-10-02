FROM sentry:9.1-onbuild

ENV C_FORCE_ROOT='true'
ENV SENTRY_CONF='/etc/sentry'
RUN set -x && apt-get update && apt-get install -yq supervisor cron
RUN pip install -r requirements.txt


COPY files/cronjobs.txt /etc/cron.d/sentry-cron
RUN chmod 0644 /etc/cron.d/sentry-cron
RUN crontab /etc/cron.d/sentry-cron

COPY files/sentry.conf.py /etc/sentry/
COPY files/supervisord.conf /etc/sentry/
RUN chmod a+x ./files/*.sh
RUN mkdir -p /var/run/secrets/nais.io
CMD [ "./files/start.sh" ]