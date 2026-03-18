#!/bin/bash

#write the CLI commands to setup wordpress here

#create conditions to if file /usr/local/bin/wp exists. If it doesnt exit, do the install. else, dont reinstall on top in volume
if [ ! -f "wp-cli.phar"]; then
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#creates the wp exec instead of calling php wp-cli.phar each time
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
fi

if [ ! -f "wp-config.php"]; then
#install code here
#db_user is a user with GRANT ALL PRIVILLEGES on the db
#secret is a "var" declared in the docker-compose file ?
#server is name of container on the docker network
wp core download
wp config create --dbname=$MARIA_DB_NAME \
                --dbuser=$MARIA_DB_USER \
                --dbpass=secret_db_password \ 
                --dbhost=server

#do database init stuff here

#http or https here ?
wp core install --url=https://server \
                --admin_user=admin \
                --admin_password=secret_admin_password \
                --admin_email=admin@example.com
fi