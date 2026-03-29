#!/bin/sh
set -e
mkdir -p /var/www/html/ftp
chown root:root /var/www/html/ftp
chmod 755 /var/www/html/ftp

#main upload dir
mkdir -p /var/www/html/ftp/uploads
chown ftp:ftp /var/www/html/ftp/uploads
chmod 755 /var/www/html/ftp/uploads

echo "ftp:$(cat /run/secrets/ftp_password)" | chpasswd
echo "ftp" > /etc/vsftpd/user_list
exec vsftpd /etc/vsftpd/vsftpd.conf