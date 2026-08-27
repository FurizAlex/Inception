#!/bin/bash

sed -i "s/\${DOMAIN_NAME}/$DOMAIN_NAME/1" /etc/nginx/nginx.conf

nginx -g "daemon off;"