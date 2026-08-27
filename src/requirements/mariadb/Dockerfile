FROM debian:trixie

# install mariadb
RUN apt-get update
RUN apt-get install mariadb-server -y

# create and change the permission for mysqld
RUN mkdir /var/run/mysqld
RUN chown :mysql /var/run/mysqld
RUN chmod 775 /var/run/mysqld

# copy our script & chande the permissions to allow it to run
# this script is for creating a init.sql
COPY ./tools/entry_point.sh /
RUN chmod 775 ./entry_point.sh

# run our script
ENTRYPOINT ["/entry_point.sh"]