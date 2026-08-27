#!/bin/bash
set -e

chown -R mysql:mysql /var/lib/mysql

sed -i "s/\= 127\.0\.0\.1/\= 0\.0\.0\.0/1" /etc/mysql/mariadb.conf.d/50-server.cnf

# On a fresh bind-mounted volume, /var/lib/mysql is empty and has no system
# tables yet - so initialize it if missing.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start mariadb directly as the mysql user, in the background, so we can
# wait for it to actually be ready before touching it.
mysqld --user=mysql &
pid="$!"

until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

# Only run the init SQL once, ever - not on every container restart.
if [ ! -f /var/lib/mysql/.inception_initialized ]; then
    echo "CREATE DATABASE IF NOT EXISTS $DB_NAME ;" > /tmp/dbInit.sql
    echo "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS' ;" >> /tmp/dbInit.sql
    echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' ;" >> /tmp/dbInit.sql
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASS' ;" >> /tmp/dbInit.sql
    echo "FLUSH PRIVILEGES; " >> /tmp/dbInit.sql

    mariadb < /tmp/dbInit.sql
    rm -f /tmp/dbInit.sql

    touch /var/lib/mysql/.inception_initialized
fi

# Hand off to the already-running mysqld process instead of killing it.
wait "$pid"