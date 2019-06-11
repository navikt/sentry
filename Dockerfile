FROM sentry:9.1-onbuild

ENV C_FORCE_ROOT='true'
RUN set -x && apt-get update && apt-get install -y supervisor
RUN pip install -r requirements.txt


COPY files/sentry.conf.py /etc/sentry/
COPY files/supervisord.conf /etc/sentry/
RUN chmod a+x ./files/*.sh
RUN mkdir -p /var/run/secrets/nais.io
CMD [ "./files/start.sh" ]