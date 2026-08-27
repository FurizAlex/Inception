FROM debian:trixie

# Update our list & install nginx
RUN apt-get update
RUN apt-get install nginx -y

# Copy our config certs over
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./tools/entry_point.sh /

RUN chmod +x /entry_point.sh

# Run nginx in the forground
ENTRYPOINT ["/entry_point.sh"]