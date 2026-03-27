#!/bin/sh

DB_PASSWORD=$(cat /run/secrets/dbpassword)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wpadminpwd)


if ! wp core is-installed --allow-root; then
#install code here
#db_user is a user with GRANT ALL PRIVILLEGES on the db
#server is name of container on the docker network

php -d memory_limit=256M /usr/local/bin/wp core download --allow-root #raises php archive size limits for extracting wp core install zip
wp config create --allow-root --dbname=$MARIA_DB_NAME \
                --dbuser=$MARIA_DB_USER \
                --dbpass=$DB_PASSWORD \
                --dbhost=$DB_HOST \

wp core install --allow-root --url=https://$DOMAIN_NAME \
                --admin_user=$WP_ADMIN_USER \
                --admin_password=$WP_ADMIN_PASSWORD \
                --admin_email=$WP_ADMIN_EMAIL \
                --title=inception
fi

exec php-fpm82 -F