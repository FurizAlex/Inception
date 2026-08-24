#!/bin/bash

# runs our wp install script as tempUser for security reasons
su tempUser -c "/wp-install-script.sh"

# runs php-fpm in the forground
/usr/sbin/php-fpm7.4 -F