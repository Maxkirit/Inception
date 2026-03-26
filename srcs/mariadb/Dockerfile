FROM alpine:3.22

RUN apk update && \
    apk upgrade && \
    apk add curl && \
    apk add mariadb mariadb-client


#adds the confing file that binds the right IP for the DB to its expected place before install
COPY my.cnf /etc/mysql/.
COPY --chmod=+x entrypoint.sh .

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=30s --start-period=5s --retries=3 \
             CMD mariadb -e 'SELECT @@datadir;' || exit 1

ENTRYPOINT [ "./entrypoint.sh" ]