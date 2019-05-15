from sentry.models import Project
from sentry.receivers.core import create_default_projects
create_default_projects([Project])