# Single pod setup for sentry

Because of our data policies in NAV we need to run Sentry as an internal service. This repository
serves as an example of how this can be done. We have done some adaptions to fit into our Kubernetes
cluster, which have some limitations when running third party applications.

Our primary attempt to run Sentry was of course the [sentry helm chart], which almost did the job for us. But there
where issues with this that made it impossible for us to use it.

This setup contains a simpler setup of [Sentry onpremise]. We have made some changes. Most 
important is that it depends on running just three services on the cluster and allow using an external database and
redis instance.

* Sentry Web, the main Dockerfile included in this folder.
* Redis, can be any implementation.
* Postgres (can be any installation, we are using [the official Posgresql helm chart])

The main docker image runs [supervisord] to start the cronjob, a worker and the webserver. Also it runs migrations 
on startup. The migrations is a little bit flacky, but everything seem to work perfectly.

## Issues
To make it easier for others to adapt this way of running sentry, we are included some of the problems we
encountered while setting this up.

### Problem with the sentry database user or database
You need to log into the pod and just fix things yourself. We got it working eventually.
Here are some useful commands:

```bash
psql -U postgres
> CREATE USER sentry WITH PASSWORD 'xxx';
> CREATE DATABASE sentry OWNER sentry;
> ALTER USER sentry WITH SUPERUSER;
```

The user that migrations need to be run with have to be a superuser. If not one of the extensions
will fail and you will have to do some work to get it right again. 
ref: https://github.com/getsentry/sentry/issues/11095

### memory leak in migrations
Apparently there is an issue with migrations and memory which causes pods to run out of memory on
startup of the containers. We used [this solution] to solve this. The solution can be found in the 
file [upgrade.sh](./blob/master/files/upgrade.sh) where we are running the migrations like
described in the github-issue.

### when the application is running
Diagnostic you can get diagnostic information on: http://localhost:9000/_health/?full

### Creating a superuser
Unfortunately this has to be done manually inside the pod. Fortunately its easy:
```bash
kubectl exec -it your_sentry_pod -- sentry createuser --email admin@sentry.local --password supersecret
```
After this the GITHUB_APPS integration should handle signup. That worked fine for us.

How ever if this command fails, that is due to lack of env-variables that are read from vault. Just run
`source ./files/vault.sh` to get exported those variables.

## Running on [nais]
As said earlier we have an application platform built with kubernetes. These examples should possible to
relate to other setups. So we included the application manifests.
```bash
kubectl apply -f nais.io/web/app.yaml
kubectl apply -f nais.io/redis/app.yaml
kubectl apply -f nais.io/proxy/app.yaml
```
### Vault
Nais is using vault to manage secrets. They get injected into a folder and we read them into environment variables as 
seen in the file [/start.sh](./blob/master/files/start.sh). For local development we use the same mechanism to inject
variables.

### Google Application Credentials
The environment variable `GOOGLE_APPLICATION_CREDENTIALS` should referee to a filepath not the whole json-object. We 
also use vault to store this setting and just make a reference to it in environment variables.


[nais]: https://nais.io/
[sentry helm chart]: https://github.com/helm/charts/tree/master/stable/sentry
[supervisord]: http://supervisord.org/
[Sentry onpremise]: https://github.com/getsentry/onpremise
[the official Posgresql helm chart]: https://github.com/helm/charts/tree/master/stable/postgresql
[this solution]: https://github.com/getsentry/sentry/issues/8862