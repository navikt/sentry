from django.db import connection, transaction
try:
    cursor = connection.cursor()
    cursor.execute("ALTER TABLE sentry_identityprovider ADD FOREIGN KEY (organization_id) REFERENCES sentry_organization(id)")
    transaction.commit_unless_managed()
except:
    pass
