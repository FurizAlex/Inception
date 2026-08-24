FROM debian:bullseye

# Update our list & install nginx
RUN apt-get update
RUN apt-get install nginx -y

# Copy our config certs over
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./tools/entrypoint.sh /

RUN chmod +x /entrypoint.sh

# Run nginx in the forground
ENTRYPOINT ["/entrypoint.sh"]