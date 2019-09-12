from sentry.models import Project
from sentry.receivers.core import create_default_projects
try:
    project = create_default_projects([Project])
except:
    pass