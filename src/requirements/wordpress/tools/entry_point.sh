#!/bin/bash

chown -R :www-data /var/www/html
chmod -R 775 /var/www/html

# runs our wp install script as tempUser for security reasons
su -m tempUser -c "/wp-install-script.sh"

# runs php-fpm in the forground
php-fpm -F