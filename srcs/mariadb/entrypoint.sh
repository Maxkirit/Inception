#!/bin/sh
set -e #exits on errors

if [ ! -f "/var/lib/mysql/ibdata1" ]; then #space is important for shell between [ and !
DB_PASSWORD=$(cat /run/secrets/dbpassword)
DB_ROOT_PASSWORD=$(cat /run/secrets/dbrootpassword)
mkdir /run/mysqld
chown -R mysql:mysql /run/mysqld #mysql becomes owner of dir mysqld
mariadb-install-db --user=mysql --datadir=/var/lib/mysql
#& to force daemon to run in background
/usr/bin/mariadbd-safe --datadir=/var/lib/mysql --port=3306 &
# security for daemon to launch
sleep 10 
mariadb-secure-installation <<EOF

n
Y
$DB_ROOT_PASSWORD
$DB_ROOT_PASSWORD
Y
Y
Y
Y
EOF
mariadb -u root -p"$DB_ROOT_PASSWORD" <<EOF #restarts the mariadb monitor

CREATE DATABASE IF NOT EXISTS $MARIA_DB_NAME;
CREATE USER IF NOT EXISTS '$MARIA_DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $MARIA_DB_NAME.* TO '$MARIA_DB_USER'@'%';
FLUSH PRIVILEGES;
EOF
mariadb-admin -u root -p"$DB_ROOT_PASSWORD" shutdown
fi
#creates runtime dir for the connection sockets. ensures it exists at every runtime not just first install
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
exec mariadbd --user=mysql # replaces the sh process with mariadbd the daemon not the monitor