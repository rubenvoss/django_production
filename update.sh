#!/bin/sh

/usr/bin/git pull

# collectstatic?
/srv/www/rubens_blog/venv/bin/python /srv/www/rubens_blog/rubens_blog/manage.py collectstatic --noinput

# restart gunicorn
systemctl reload gunicorn

# postgresql  manage.py migrate?