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
ADD https://raw.githubusercontent.com/intlabs/docker-ubuntu-lemp/master/nginx-default-server /etc/nginx/sites-available/default

#Install memcache
RUN sudo apt-get install -y php5-memcache memcached php-pear netcat build-essential php5-memcached

# supervisor base configuration
ADD supervisor.conf /etc/supervisor.conf

# supervisor services configuration
ADD supervisor_conf/php.conf /etc/supervisor/conf.d/php.conf
ADD supervisor_conf/nginx.conf /etc/supervisor/conf.d/nginx.conf

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

# Create our site
RUN rm /usr/share/nginx/html/index.html
#RUN echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/index.php
RUN apt-get install git -y

#Install grunt
RUN sudo apt-get install -y nodejs npm
RUN ln -s /usr/bin/nodejs /usr/local/bin/node
RUN npm install -g grunt-cli

RUN git clone https://github.com/symbiose/symbiose.git && cd symbiose && npm install && grunt build && mv build/* /usr/share/nginx/html && cd .. && rm -r -f symbiose
RUN apt-get purge git -y
RUN cd /usr/share/nginx/html/ && chown -R www-data .


RUN echo '<?php phpinfo(); ?>' > /usr/share/nginx/html/info.php