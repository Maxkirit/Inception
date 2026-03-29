FROM alpine:3.22

RUN apk upgrade && apk add --no-cache vsftpd shadow

RUN usermod -d /var/www/html/ftp ftp

COPY --chmod=+x ./entrypoint.sh ./
COPY ./vsftpd.conf /etc/vsftpd/vsftpd.conf

EXPOSE 21 21100-21110

ENTRYPOINT [ "./entrypoint.sh" ]