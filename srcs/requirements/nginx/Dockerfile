FROM debian:bookworm

# update our list & install nginx
RUN apt-get update
RUN apt-get install nginx -y

# copy our config certs over
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./tools/entry_point.sh /

RUN chmod +x /entry_point.sh

# run nginx in the forground
ENTRYPOINT ["/entry_point.sh"]