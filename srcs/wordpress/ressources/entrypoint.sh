#!/bin/sh
DB_PASSWORD=$(cat /run/secrets/dbpassword)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wpadminpwd)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

MAX_RETRIES=30
RETRY_COUNT=0

#wait for db to have tables intialized - prevents race condition
until mysql -h"mariadb" -u"root" -p"$(cat /run/secrets/dbrootpassword)" -e "SHOW TABLES IN $MARIA_DB_NAME;" &>/dev/null; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        >&2 echo "database didn't start in time"
        exit 1
    fi
    >&2 echo "datbase not ready yet"
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
done


if ! wp core is-installed --allow-root 2>/dev/null; then
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

#create empty page to test for comments
PAGE_ID=$(wp post create --post_type=page --post_title='Test Comments' --post_status=publish --porcelain)
wp post update $PAGE_ID --comment_status=open
fi

if ! wp user get $WP_USER &> /dev/null; then
    wp user create $WP_USER $WP_USER_EMAIL --role=author --user_pass=$WP_USER_PASSWORD
fi

exec php-fpm82 -F