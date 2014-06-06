#
# Ubuntu Desktop (Gnome) Dockerfile
#
# https://github.com/intlabs/docker-ubuntu-lemp
#

# Install GNOME3 and VNC server.
# (c) 2014 Pete Birley


# sudo docker build -t="intlabs/docker-ubuntu-lemp" github.com/intlabs/docker-ubuntu-lemp
# sudo docker run -it --rm -p 81:80 --privileged=true --lxc-conf="native.cgroup.devices.allow = c 10:229 rwm" intlabs/docker-ubuntu-lemp


# Pull base image.
FROM ubuntu:14.04

# Setup enviroment variables
ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root

#Update the package manager and upgrade the system
RUN apt-get update && \
apt-get upgrade -y && \
apt-get update

# Upstart and DBus have issues inside docker.
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

# supervisor installation && 
# create directory for child images to store configuration in
RUN apt-get -y install supervisor && \
  mkdir -p /var/log/supervisor && \
  mkdir -p /etc/supervisor/conf.d

# Install nginx
RUN apt-get update && apt-get install -y nginx

# Install php5
RUN apt-get install -y php5-fpm php5-cli php5-mysql

# Install mysql
#RUN apt-get install -y mysql-server

#setup php ini file
RUN sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini

#Configure nginx for php
RUN rm -f /etc/nginx/sites-available/default
ADD nginx-default-server /etc/nginx/sites-available/default

#Install memcache
RUN sudo apt-get install -y php5-memcache memcached php-pear netcat build-essential php5-memcached

# supervisor base configuration
ADD supervisor.conf /etc/supervisor.conf

# supervisor services configuration
ADD supervisor_conf/php.conf /etc/supervisor/conf.d/php.conf
ADD supervisor_conf/nginx.conf /etc/supervisor/conf.d/nginx.conf

# Move into site root
WORKDIR /usr/share/nginx/html

# Clear the deafult site
RUN rm -r -f *
RUN chown -R www-data .

# Put in a php info file
RUN echo '<?php phpinfo(); ?>' > info.php

# Pull in latest version of symbiose
WORKDIR /tmp
RUN apt-get install git -y
RUN git clone https://github.com/symbiose/symbiose.git

#Install grunt
RUN sudo apt-get install -y nodejs npm
RUN ln -s /usr/bin/nodejs /usr/local/bin/node
RUN npm install -g grunt-cli

# Build symbiose
WORKDIR /tmp/symbiose
RUN npm install
RUN grunt build

# Move built system into place
RUN mv build/* /usr/share/nginx/html

# Fix Permissions
WORKDIR /usr/share/nginx/html
RUN chown -R www-data .

# Cleanup after install
WORKDIR /tmp
RUN rm -r -f symbiose

# Purge git
RUN apt-get purge git -y

#Bring In startup script
ADD startup.sh /etc/startup.sh
RUN chmod +x /etc/startup.sh

# default command
CMD bash -C '/etc/startup.sh';'bash'

# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Expose ports.
EXPOSE 80