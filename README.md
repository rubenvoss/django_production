# django_production
How to set up a django webapp in production 101
Opionionated way of setting up a django webapp on a 'bare metal' Debian Linux Server.
With automated Continuous Deployment via Github & webhooks.

## Stack
- Debian 12
- Django 5.0.4
- postgresql 15.6
- gunicorn 21.2.0
- nginx 1.22.1
- webhook 2.8.0
- ufw 0.36.2

## Why do it this way?
Why not host your app on a Cloud-Service app Platform like digitalocean, aws or heroku? Well, because:
You're dependent on the Platform. They demand a price and you must pay it. You're locked in to a vendor if you want to get the real benefits from the cloud. 
You're gonna learn a lot about how django and applications in general behave in production.
You can host your app really cheap on any VPS
No need to spend lots of time on Kubernetes.

## Downsides of doing it on 'bare metal'
Lots of terminal time.

## fix perl bug
If your machine has SendEnv LANG LC_* in the /etc/ssh/ssh_config file, you might get a perl language warning for a lot of commands, like adduser, psql, etc. Comment out that line. [See Stackoverflow Post](https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl)
```
sudo vi /etc/ssh/ssh_config

#    SendEnv LANG LC_*
```


## users
It's a good idea to not run everything as root. add a personalized user and give your user a password.
Also add the user to the sudoers Group, so that you can execute root commands.
```
adduser my_username
adduser my_username sudo
```

## security
Because your server is in production, the root user should not be able to login via ssh. Other People might try to login as root on your server and Brute Force your password.

Generate your ssh-key if you haven't one yet.
```
ssh-keygen
```

First, login with your new user and add your ssh key, so that you can login without a password. This makes Brute Force attacks unreasonable. You can use ssh-copy-id for this
```
ssh-copy-id my_username@my.server.ip
```

Now, remove the root users ability to login via ssh and password. Also remove your own ability to login via password.
Careful, now the only access you have is your ssh-key! If you set it up with stanard settings, it's located in ~/.ssh/id_rsa
```
sudo vi /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
```
Now, try it out!
```
ssh my_username@my.server.ip
ssh root@my.server.ip
# for root you should get the following message:
root@xxx.xxx.xxx.xx: Permission denied (publickey).
```




## postgresql
If you see this output when running `sudo -u postgres psql`
```
perl: warning: Setting locale failed.
perl: warning: Please check that your locale settings:
	LANGUAGE = "en_US.UTF-8",
	LC_ALL = (unset),
	LC_CTYPE = "UTF-8",
	LANG = "en_US.UTF-8"
    are supported and installed on your system.
perl: warning: Falling back to a fallback locale ("en_US.UTF-8").
```

## How to setup
### Add a user for the ssh login


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

# python setup
apt install git python3.11-venv python3-dev libpq-dev gcc
mkdir -p /srv/www/
cd /srv/www
git clone git@github.com:rubenvoss/rubens_blog.git
cd rubens_blog
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt 

# add this to .bashrc
```
# set production env
export ENV_NAME=production
cd /srv/www/rubens_blog

# activate python env
source /srv/www/rubens_blog/venv/bin/activate
```


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
sudo journalctl -eu webhook.service

# back on prod
apt install postgresql postgresql-contrib


sudo -u postgres psql

CREATE DATABASE rubens_blog;
\connect rubens_blog
CREATE USER ruben WITH PASSWORD 'password';

# psql 15
https://gist.github.com/axelbdt/74898d80ceee51b69a16b575345e8457
CREATE SCHEMA rubens_blog_schema AUTHORIZATION ruben;
ALTER ROLE ruben SET client_encoding TO 'utf8';
ALTER ROLE ruben SET default_transaction_isolation TO 'read committed';
ALTER ROLE ruben SET timezone TO 'CET';

# ?
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

```
cd /srv/www/rubens_blog/rubens_blog && export ENV_NAME=production && python manage.py runserver 0.0.0.0:80
cd /srv/www/rubens_blog/rubens_blog && export ENV_NAME=production && /srv/www/rubens_blog/venv/bin/gunicorn rubens_blog.wsgi
```


# setup letsencrypt certbot
```
sudo apt install certbot python3-certbot-nginx
sudo ufw allow 'Nginx Full'
sudo ufw status

sudo certbot --standalone --nginx
```