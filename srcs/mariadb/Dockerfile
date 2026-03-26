FROM alpine:3.22

RUN RUN apk update && apk upgrade && apk curl && \
    apk add mariadb mariadb-client

ARG MARIADB_CONFIG_FILE

WORKDIR /

EXPOSE 3306

# HEALTHCHECK --interval=10s --timeout=30s --start-period=5s --retries=3 CMD mariadb -e 'SELECT @@datadir;' || exit 1

# ENTRYPOINT mariadbd --defaults-file=$MARIADB_CONFIG_FILE
CMD [ "mariadb"]