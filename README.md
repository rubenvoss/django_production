# django_production
How to Set up your django webapp in production 101


# This Folder contains files to setup the server. 

## How to setup
### Add a user for the ssh login


## settings folder
```
# set vi as editor, fix env language perl bug (https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl)

# add this to your bashrc:

# set vi as standard editor
export EDITOR='vi'
export VISUAL='vi'
# fix perl bug
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# Colorize ls:
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
#set production env
export ENV_NAME=production

# set time & date 
timedatectl set-timezone Europe/Berlin

# bring system up to date
apt update && apt upgrade

# keeping system up to date in the background
apt install unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades
unattended-upgrades --dry-run --debug
# where are the logs?

apt install git python3.11-venv python3-dev libpq-dev gcc
mkdir -p /srv/www/
cd /srv/www
git clone git@github.com:rubenvoss/rubens_blog.git
cd rubens_blog
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt 
export ENV_NAME=production

# back on local
rsync -r rubens_blog/rubens_blog/settings/*.py rubens-blog-production:/srv/www/rubens_blog/rubens_blog/rubens_blog/settings/

# make a webhook to automatically update Repo
apt install webhook
rsync production/hooks.json rubens-blog-production:/srv/www/rubens_blog/production/hooks.json
# test 
/usr/bin/webhook -hooks /srv/www/rubens_blog/install/hooks.json -verbose
# install service 
ln -s /srv/www/rubens_blog/production/webhook.service /etc/systemd/system/webhook.service
systemctl daemon-reload
systemctl enable webhook
systemctl start webhook
# where are the logs?


# back on prod
apt install postgresql postgresql-contrib


sudo -u postgres psql

https://gist.github.com/axelbdt/74898d80ceee51b69a16b575345e8457
CREATE DATABASE rubens_blog;
\connect rubens_blog
CREATE USER ruben WITH PASSWORD 'password';
# psql 15
CREATE SCHEMA rubens_blog_schema AUTHORIZATION ruben;
ALTER ROLE ruben SET client_encoding TO 'utf8';
ALTER ROLE ruben SET default_transaction_isolation TO 'read committed';
ALTER ROLE ruben SET timezone TO 'CET';
GRANT ALL PRIVILEGES ON DATABASE rubens_blog TO ruben;
ALTER DATABASE rubens_blog OWNER TO ruben;
# GRANT ALL ON SCHEMA public TO ruben;
# GRANT ALL ON SCHEMA public TO public;
\q

cat /usr/lib/systemd/system/postgresql.service
rsync install/postgresql.service rubens-blog-production:/usr/lib/systemd/system/postgresql.service
systemctl daemon-reload # load the updated service file from disk
systemctl enable postgresql
systemctl start postgresql
systemctl status postgresql
# where are the logs?


apt install ufw
ufw allow 80
# where are the logs?


# nginx
apt install nginx
ln -s /srv/www/rubens_blog/production/nginx.conf /etc/nginx/nginx.conf
systemctl enable nginx.service
systemctl start nginx
# where are the logs?



# gunicorn
apt install gunicorn
ln -s /srv/www/rubens_blog/production/gunicorn.service /etc/systemd/system/gunicorn.service
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn
# debug gunicorn
export ENV_NAME=production && cd /srv/www/rubens_blog/rubens_blog && ../venv/bin/gunicorn rubens_blog.wsgi -b 127.0.0.1:8000
# where are the logs?

# django setup
python manage.py migrate
python manage.py createsuperuser

# nginx & static files


cd /srv/www/rubens_blog/rubens_blog && export ENV_NAME=production && python manage.py runserver 0.0.0.0:80
cd /srv/www/rubens_blog/rubens_blog && export ENV_NAME=production && /srv/www/rubens_blog/venv/bin/gunicorn rubens_blog.wsgi
```

test233