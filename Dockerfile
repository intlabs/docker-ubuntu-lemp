#
# Ubuntu Desktop (Gnome) Dockerfile
#
# https://github.com/intlabs/docker-ubuntu-lemp
#

# Install GNOME3 and VNC server.
# (c) Pete Birley


# sudo docker build -t="intlabs/docker-ubuntu-lemp" github.com/intlabs/docker-ubuntu-lemp
# sudo docker run -it --rm -p 80:80 intlabs/docker-ubuntu-lemp


# Pull base image.
FROM ubuntu:14.04

# Setup enviroment variables
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV HOME /root

#Update the package manager and upgrade the system
RUN apt-get update && \
apt-get upgrade -y && \
apt-get update

# Installing fuse filesystem is not possible in docker without elevated priviliges
# but we can fake installling it to allow packages we need to install for GNOME
RUN apt-get install libfuse2 -y && \
cd /tmp ; apt-get download fuse && \
cd /tmp ; dpkg-deb -x fuse_* . && \
cd /tmp ; dpkg-deb -e fuse_* && \
cd /tmp ; rm fuse_*.deb && \
cd /tmp ; echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst && \
cd /tmp ; dpkg-deb -b . /fuse.deb && \
cd /tmp ; dpkg -i /fuse.deb

# Upstart and DBus have issues inside docker.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# Install nginx
RUN apt-get update && apt-get install -y nginx

RUN apt-get install -y php5-fpm php5-cli php5-mysql

RUN apt-get install -y mysql-server

RUN echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/phpinfo.php

RUN rm -f /etc/nginx/sites-available/default
ADD https://raw.githubusercontent.com/intlabs/docker-ubuntu-lemp/master/nginx-default-server /etc/nginx/sites-available/default

RUN sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g’ /etc/php5/fpm/php.ini

# supervisor installation && 
# create directory for child images to store configuration in
RUN apt-get -y install supervisor && \
  mkdir -p /var/log/supervisor && \
  mkdir -p /etc/supervisor/conf.d

# supervisor base configuration
ADD supervisor.conf /etc/supervisor.conf

# default command
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]


# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Expose ports.
EXPOSE 80