#!/bin/bash
 
# download all the core wordpress
wp core download
 
# create the config file with our database
wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=mariadb
 
# creates the admin user & sets-up the database with the tables and fields
wp core install --url=$DOMAIN_NAME/ --title=$WORDPRESS_TITLE --admin_user=$WORDPRESS_ADMIN_USER --admin_password=$WORDPRESS_ADMIN_PASSWORD --admin_email=$WORDPRESS_ADMIN_EMAIL --skip-email
 
# create a user using the wordpress cli
wp user create $WORDPRESS_NORMAL_USER $WORDPRESS_NORMAL_EMAIL --user_pass=$WORDPRESS_NORMAL_PASS --role=author
