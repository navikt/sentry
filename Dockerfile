FROM sentry:9.1-onbuild

ENV C_FORCE_ROOT='true'

COPY files/sentry.conf.py /etc/sentry/
COPY files/supervisord.conf /etc/sentry/
RUN chmod a+x ./files/*.sh

RUN mkdir -p /var/run/secrets/nais.io

RUN pip install -r requirements.txt
RUN set -x && apt-get update && apt-get install -y supervisor
CMD [ "./files/start.sh" ]