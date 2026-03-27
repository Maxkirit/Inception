FROM alpine:3.22

#update package repos and install basic packages
RUN apk update && apk upgrade && apk add curl && apk add netcat-openbsd && \
    apk add php82 \
            php82-fpm \
            php82-pdo_mysql \
            php82-mysqli \
            php82-phar \
            php82-json \
            php82-xml \
            php82-mbstring \
            php82-curl \
            php82-gd \
            php82-zip \
            php82-opcache && \
    rm -rf /var/cache/apk/*

#on Alpine, php is installed as php82 so for the install to work, we make a symlink
RUN ln -s /usr/bin/php82 /usr/bin/php

#acts as 'cd' command
WORKDIR /var/www/html

COPY --chmod=+x ./ressources/build_script.sh ./ressources/entrypoint.sh ./ 

RUN ./build_script.sh

RUN chown -R nobody:nobody /var/www/html

#replaces existing www.conf by yours
COPY ./ressources/www.conf /etc/php82/php-fpm.d/www.conf

HEALTHCHECK --interval=10s --timeout=5s --retries=10 --start-period=30s \
            CMD nc -z localhost 9000 || exit 1

EXPOSE 443

ENTRYPOINT [ "./entrypoint.sh" ]