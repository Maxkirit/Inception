FROM alpine:3.22

#update package repos and install basic packages
RUN apk update && apk upgrade && apk add curl && \
    apk add php && \
    apk add php-fpm && \
    apk add php-mysql && \
    apk add fcgi && \
    app add php-cgi && \
    rm -rf /var/cache/apk/*

#acts as 'cd' command
WORKDIR /tmp

COPY --chmod=+x ./ressources/build_script.sh ./ressources/entrypoint.sh ./ 

RUN ./build_script.sh

#replaces existing www.conf by yours
COPY ./ressources/www.conf /etc/php82/php-fpm.d/www.conf

EXPOSE 443

ENTRYPOINT [ "/tmp/entrypoint.sh" ]