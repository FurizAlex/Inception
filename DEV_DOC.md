**DEVELOPER DOCUMENTATION**

this document covers setting up, building, managing the inception stack
from a devs perspective

===========================================================================================================

# PREREQUISITES

docker engine with compose plugin *[docker compose]*, not the older *[docker-compose]*
check both of these are infact installed

 | docker --version
 | docker compose version

*Docker compose on WSL requires the docker desktop application to be installed*
*Settings -> Resources -> WSL Integration*

To install docker compose simply do:

 | sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

===========================================================================================================

# PROJECT LAYOUT

secrets
src
  requirements
    mariadb
      tools
        entry_point.sh
      Dockerfile
    nginx
      tools
        entry_point.sh
      Dockerfile
    wordpress
      tools
        entry_point.sh
        wp-install-script.sh
      Dockerfile
  .env
  .env.example
  docker-compose.yml
DEV_DOC.md
USER_DOC.md
README.md
Makefile

==========================================================================================================

# CONFIGURATION FILES & SECRETS

.env in the source file is where everything that is required for inception
to even run is stored in

If it doesn't exist yet, running 'make' or 'make env' will create it automatically by copying it from
.env.example. do edit the copy and not the example when changing the local config

**WORDPRESS_ADMIN_USER | WORDPRESS_ADMIN_PASSWORD**
--------------------------------------------------
full administrator account for wordpress dashboard

**WORDPRESS_NORMAL_USER | WORDPRESS_NORMAL_PASS**
---------------------------------------------
a secondary non-administrative account for demonstrating that
the website isn't single user

**DB_USER | DB_PASS**
---------------------
database credentials for wordpress to communicate internally
to mariadb, pretty unneccessary if not working with mariadb

**DB_ROOT_PASS**
----------------
the databases root password for direct administrative database access

if you change any of these above, then you'll need to do a clean wipe
and rebuild the project for it to take effect

the secrets folder holds the generated self-signed certificate
[cert.pem], private key [cert.key] and diffie-hellman parameters [dhparam.pem],

this will be automatically be generated as part of 'make'
tho you can use 'make certs-only' to generate the certificates exclusively

===========================================================================================================

# BUILDING & LAUNCHING

from the project root

'make'

this runs, in order:

**generate_certs**: creates the secrets folder if the cert files aren't already present
**env**: creates .env from the example if missing
**prep**: creates the host-side data directories under $USER_HOME/data/, and adds the DOMAIN_NAME → 127.0.0.1 mapping to /etc/hosts
**docker compose -f src/docker-compose.yml up --build -d**: builds all three images and starts the containers

commands for building or starting a single service

docker compose -f src/docker-compose.yml build <service>
docker compose -f src/docker-compose.yml up <service>

bring services up one at a time (mariadb, then wordpress, then nginx)
rather than all at once when diagnosing a startup problem
each depends on the previous one being healthy
so isolating them narrows down failures faster than reading three interleaved logs at once

===========================================================================================================

# DATA STORAGE & PRESISTANCE

each stateful service has a docker-managed named volume
backed by a bind mount to a fixed path on the host this satisfies the project's requirement that data survive independently of the containers

volume	host path	contents
mariadb volume	$USER_HOME/data/mariadb	MariaDB's full data directory (/var/lib/mysql inside the container) all databases, including the wordpress DB
wordpress volume	$USER_HOME/data/wordpress	WordPress core files, themes, plugins, uploads (/var/www/html inside the container)

because these are bind mounts to real host paths (not anonymous docker volumes), you can inspect the data directly

 | ls $USER_HOME/data/mariadb
 | ls $USER_HOME/data/wordpress

important behavioral note: both entrypoint scripts detect a fresh, empty mount and initialize it on first boot only

mariadb's entrypoint runs mysql_install_db only if /var/lib/mysql/mysql doesn't already exist, and only runs the one-time dbInit.sql (database/user creation, root password change) if a marker file /var/lib/mysql/.inception_initialized is absent

wordpress's entrypoint runs wp core install via wp-install-script.sh; wp-cli itself detects an existing wp-config.php/install & skips re-downloading/re-installing on subsequent boots

this means make down / make (without fclean in between) preserves all site content and the database across restarts, while make fclean genuinely wipes it back to zero by deleting the host directories and the associated named volumes

full wipe of a single service's data, if ever needed without a full fclean

 | docker compose -f src/docker-compose.yml down
 | docker volume rm -f src_mariadb   # or src_wordpress
 | sudo rm -rf $USER_HOME/data/mariadb   # or /wordpress

removing both the docker volume record and the host directory is necessary
removing only one leaves a stale reference that causes a mount error on the next up