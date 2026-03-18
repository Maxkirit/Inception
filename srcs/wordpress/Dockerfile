FROM alpine:3.22

#update package repos and install basic packages
RUN apk update && apk upgrade && apk curl && \
    apk add bash && \
    apk add php && \
    apk add php-fpm && \
    apk add php-mysql && \
    apk add fcgi && \
    app add php-cgi && \
    rm /var/cache/apk/*

#acts as 'cd' command
WORKDIR /tmp

COPY ./ressources/. .
COPY ../.env .

EXPOSE 443

#this command runs FPM in the foreground 
CMD php-fpm8.2 -F

ENTRYPOINT [ "entrypoint.sh" ]