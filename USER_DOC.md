**USER DOCUMENTATION**

this document explains how to use the Inception's stack as an end user or administrator
what it does, where to start and how to stop it as well, how to access it and so on..

*What this 'Stack' provides*

inception runs a self-contained wordpress website behind a HTTPS reverse proxy
made up of 3 services.

## Nginx
the only entry point, serves the site over HTTPS (port 443) and forwards PHP request to wordpress

## WordPress
is the website itself, which is run via php-fpm
it isn't reachable directly from outside the stack - only nginx actually talks to it

## MariaDB
the database backing wordpress [post, pages, users, settings]

all 3 of these run in separate isolated containers on the same private docker network,
each keeping its data on disk so nothing is lost when containers restart

==========================================================================================================

# STARTING & STOPPING THE PROJECT

run all commands from project root *(ofc)* where the Makefile is located

'make' will start everything until all 3 services are built & done

*to stop everything*:

'make down'

make down will stop everything and the containers will be removed, tho the data will be kept.

'make fclean'

make fclean will fully reset everything including data. **ONLY** use make fclean if you
want to fully get rid of everything

'make re'

rebuilds everything from scratch as said in the README

=========================================================================================================

# ACCESSING THE SITE

once make is fully finished successfully, open a browser and copy this on to its URL

https://alechin.42.fr/

you'll see a browser warning about a certificate. This is expected, since the project
uses a self-signed certificate rather than one that is publically avaliable

just click 'Advanced' -> 'Proceed' or whatever your equivelant is.

if the page isn't loading at all thenn the domain likely isn't mapped to your machine yet

**Administration Panel**
the wordpress admin link below

https://alechin.42.fr/wp-admin

log in with the administrator credientials

=========================================================================================================

# CREDENTIALS

all credentials are defined in one file only [.env]. this file is not commited to the git repo
excluded via .gitignore since it contains a real password & info which is obviously a security
risk so it copies from an .env.example file

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

=======================================================================================================

# STATUS

'make status': *checking the status of the containers + docker volumes & networks*

look for all 3 containers listed as up & healthy once past their startup grace period *(around ~20 seconds or so)*. If a container shows somethings been exited or unhealthy than something has gone wrong

check **'make logs'** to see the status of a container

press **ctrl + c** to stop watching

confirm the domain resolves. The project maps alechin.42.fr to 127.0.0.1 in your system's hosts file automatically when you run make. you can confirm this took effect with:

**grep alechin /etc/hosts**

if nothing is returned, the mapping didn't get added
try rerunning make, or add the line manually: 127.0.0.1 alechin.42.fr in your systems folder

*if ran on WSL then add the line above to this folder in your windows directory*
*C:\Windows\System32\drivers\etc\hosts*