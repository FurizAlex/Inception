FROM debian:bookworm
 
# update the list of packages & install php-fpm & php-mysql for wp cli we will install later
# (unversioned meta-packages so this doesn't break next time the base image's default PHP version changes)
RUN apt-get update -y
RUN apt-get install -y curl php-fpm php-mysql
 
# make sure these directories exist
RUN mkdir -p /run/php
RUN mkdir -p /var/www
 
# create and modify the permission for the html folder
RUN mkdir /var/www/html
RUN chown :www-data /var/www/html
RUN chmod 775 /var/www/html
 
# remove existing files if there are any for a clean start
RUN rm -rf /var/www/html/*
 
# download the latest wp cli
RUN curl -o /var/www/html/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
 
# modify the permissions so that we can run it
# then move it to user local path where it then can be called like a command
RUN chmod +x /var/www/html/wp-cli.phar
RUN mv /var/www/html/wp-cli.phar /usr/local/bin/wp
 
# copy our files over & change the permission to make scripts runnable
COPY ./tools/entry_point.sh ./tools/wp-install-script.sh /
RUN chown :www-data /entry_point.sh /wp-install-script.sh
RUN chmod 775 /entry_point.sh /wp-install-script.sh
 
# change the php-fpm pool config to listen on 0.0.0.0:9000 instead of a unix socket,
# and allow connections from other containers (default only allows 127.0.0.1).
# found dynamically since the config path is version-specific (e.g. /etc/php/8.3/fpm/...)
RUN PHP_POOL_CONF=$(find /etc/php -path "*/fpm/pool.d/www.conf") && \
    sed -i "s|^listen = .*|listen = 0.0.0.0:9000|" "$PHP_POOL_CONF" && \
    sed -i "s|^listen.allowed_clients|;listen.allowed_clients|" "$PHP_POOL_CONF"
 
# symlink the actual versioned php-fpm binary (e.g. php-fpm8.3) to a stable
# unversioned name so entrypoint.sh doesn't need to hardcode a version either
RUN PHP_FPM_BIN=$(find /usr/sbin -name "php-fpm*") && \
    ln -s "$PHP_FPM_BIN" /usr/local/sbin/php-fpm
 
# create a temp user to install the wordpress-cli
RUN useradd -m -s /bin/bash -G sudo,www-data tempUser
 
# change the working directory to /var/www/html
WORKDIR /var/www/html
 
# run wordpress in the foreground
ENTRYPOINT ["/entry_point.sh"]
