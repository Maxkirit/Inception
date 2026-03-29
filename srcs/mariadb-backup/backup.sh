#!/bin/sh
set -e

BACKUP_DIR="/backups"
FULL_DIR="$BACKUP_DIR/full"
INC_DIR="$BACKUP_DIR/incremental/$(date +%Y%m%d_%H%M%S)"

if [ ! -d "$FULL_DIR/backup_logfile" ]; then
    echo "No full backup found"
    exit 1
fi

mkdir -p "$INC_DIR"
mariadb-backup --backup \
    --host="$DB_HOST" \
    --user="root" \
    --password="$(cat /run/secrets/dbrootpassword)" \
    --target-dir="$INC_DIR" \
    --incremental-basedir="$FULL_DIR"