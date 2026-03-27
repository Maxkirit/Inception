FROM alpine:3.22

RUN apk update && apk upgrade && \
    apk add nginx && \
    rm -rf /var/cache/apk/*

EXPOSE 443

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./ssl_cert.pem /etc/nginx/ssl/ssl_cert.pem

RUN adduser -D -g 'www' www && \
    mkdir /www && \
    chown -R www:www /var/lib/nginx && \
    chown -R www:www /www

# prevents nginx to run as a daemon and the container to exit immediately
CMD ["nginx", "-g", "daemon off;"]