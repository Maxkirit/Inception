#!/bin/sh
set -e
echo "ftp:$(cat /run/secrets/ftp_password)" | chpasswd
echo "ftp" > /etc/vsftpd/user_list
exec vsftpd /etc/vsftpd/vsftpd.conf