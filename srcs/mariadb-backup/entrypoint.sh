#!/bin/sh
set -e

rm -rf /backups/full
mkdir -p /backups/full /backups/incremental

#initial full backup
mariadb-backup --backup --target-dir=/backups/full \
    --host="$DB_HOST" \
    --user="$MARIA_DB_BACKUP_USER" \
    --password="$(cat /run/secrets/dbbackuppassword)" \
    --log-error=/var/log/mariabackup.log 2>/dev/null

grep -i "error" /var/log/mariabackup.log >&2 || true
#prepares i guess
mariadb-backup --prepare --target-dir=/backups/full \

#everyday at 1am
echo "0 2 * * * /usr/local/bin/backup.sh incremental >> /var/log/backup.log 2>&1" | crontab -

#start cron daemon, becomes PID1, log level==2 because
echo "backup daemon starting"
exec crond -f -l 2