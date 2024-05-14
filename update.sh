#!/bin/sh
export ENV_NAME=production

/usr/bin/git pull

# collectstatic?
/srv/www/rubens_blog/venv/bin/python /srv/www/rubens_blog/rubens_blog/manage.py collectstatic --noinput

# install new reqs
/srv/www/rubens_blog/venv/bin/pip install -r /srv/www/rubens_blog/requirements.txt

# migrate db
/srv/www/rubens_blog/venv/bin/python /srv/www/rubens_blog/rubens_blog/manage.py migrate

# restart gunicorn
systemctl reload gunicorn
