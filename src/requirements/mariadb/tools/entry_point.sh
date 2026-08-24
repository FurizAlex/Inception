#!/bin/bash

sed -i "s/\= 127\.0\.0\.1/\= 0\.0\.0\.0/1" /etc/mysql/mariadb.conf.d/50-server.cnf

service mariadb start

echo "CREATE DATABASE IF NOT EXISTS $DB_NAME ;" > dbInit.sql
echo "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS' ;" >> dbInit.sql
echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' ;" >> dbInit.sql
echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS' ;" >> dbInit.sql
echo "FLUSH PRIVILEGES; " >> dbInit.sql

mariadb < dbInit.sql

kill $(cat /var/run/mysqld/mysqld.pid)
mysqld