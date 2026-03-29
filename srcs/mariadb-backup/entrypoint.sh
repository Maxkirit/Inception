#!/bin/sh
set -e

#initial full backup
mariadb-backup --backup --target-dir=/backup/full \
    --host="$DB_HOST" \
    --user="root" \
    --password=$(cat /run/secrets/dbrootpassword)

#prepares i guess
mariadb-backup --prepare --target-dir=/backup/full \

#everyday at 1am
echo "0 2 * * * /usr/local/bin/backup.sh incremental >> /var/log/backup.log 2>&1" | crontab -

#start cron daemon, becomes PID1, log level==2 because
echo "backup daemon starting"
exec crond -f -l 2