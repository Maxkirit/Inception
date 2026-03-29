FROM alpine:3.22

RUN apk update && \
    apk upgrade && \
    apk add curl && \
    apk add mariadb mariadb-client && \
    rm -rf /var/cache/apk/*


#adds the confing file that binds the right IP for the DB to its expected place before install
COPY my.cnf /etc/my.cnf
COPY --chmod=+x entrypoint.sh .

EXPOSE 3306

HEALTHCHECK --interval=10s --timeout=30s --start-period=60s --retries=5 \
    CMD mariadb -u root -p"$(cat /run/secrets/dbrootpassword)" \
        -e "SHOW DATABASES LIKE '${MARIA_DB_NAME}';" | grep -q "${MARIA_DB_NAME}" || exit 1

#creates socket directory at runtime so restarts work
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

ENTRYPOINT [ "./entrypoint.sh" ]