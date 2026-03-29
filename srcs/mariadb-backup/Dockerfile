FROM alpine:3.22

RUN apk update --no-cache && apk add --no-cache mariadb-backup \
                    dcron

#mkdir here but build first backup at runtime otherwise no DB access !
RUN mkdir -p /backups/full

#needs to be in bin to be found in cron
COPY --chmod=+x ./entrypoint.sh ./backup.sh /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]