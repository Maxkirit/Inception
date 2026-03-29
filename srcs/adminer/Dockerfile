FROM alpine:3.22

RUN apk update && apk upgrade && \
    apk add --no-cache php82 \
                    php82-fpm \
                    php82-pdo \
                    php82-pdo_mysql \
                    php82-session

COPY ./adminer.php /var/www/html/adminer.php

RUN sed -i 's/^listen = .*/listen = 9000/' /etc/php82/php-fpm.d/www.conf

CMD [ "php-fpm82", "-F"]