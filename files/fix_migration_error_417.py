from django.db import connection, transaction
from click import echo

# Get an instance of a logger
echo("Started fixing migration error 417")
try:
    cursor = connection.cursor()
    cursor.execute("ALTER TABLE sentry_identityprovider ADD FOREIGN KEY (organization_id) REFERENCES sentry_organization(id)")
    transaction.commit_unless_managed()
    echo("Finished fixing migration error 417")
except:
    pass
