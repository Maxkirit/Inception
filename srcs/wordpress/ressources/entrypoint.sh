#!/bin/sh
set -e

MAX_RETRIES=30
RETRY_COUNT=0

#wait for db to have tables intialized - prevents race condition
until mysql -h"mariadb" -u"root" -p"$(cat /run/secrets/dbrootpassword)" -e "SHOW TABLES IN $MARIA_DB_NAME;" >&2; do
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "database didn't start in time" >&2
        exit 1
    fi
    echo "datbase not ready yet" >&2
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
done


if ! wp core is-installed --allow-root 2>/dev/null; then
#install code here
#db_user is a user with GRANT ALL PRIVILLEGES on the db
#server is name of container on the docker network

php -d memory_limit=256M /usr/local/bin/wp core download --allow-root #raises php archive size limits for extracting wp core install zip
wp config create --allow-root --dbname="$MARIA_DB_NAME" \
                --dbuser="$MARIA_DB_USER" \
                --dbpass="$(cat /run/secrets/dbpassword)" \
                --dbhost="$DB_HOST" 

wp core install --allow-root --url="https://$DOMAIN_NAME" \
                --admin_user="$WP_ADMIN_USER" \
                --admin_password="$(cat /run/secrets/wpadminpwd)" \
                --admin_email="$WP_ADMIN_EMAIL" \
                --title=inception

#create empty page to test for comments
PAGE_ID=$(wp post create --post_type=page --post_title='Test Comments' --post_status=publish --porcelain --allow-root)
wp post update "$PAGE_ID" --comment_status=open --allow-root
fi

if ! wp user get "$WP_USER" --allow-root &> /dev/null; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" --role=author --user_pass=$(cat /run/secrets/wp_user_password) --allow-root
fi

exec php-fpm82 -F