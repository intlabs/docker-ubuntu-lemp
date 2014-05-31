#
# Ubuntu Desktop (Gnome) Dockerfile
#
# https://github.com/intlabs/docker-ubuntu-lemp
#

# Install GNOME3 and VNC server.
# (c) Pete Birley

# Pull base image.
FROM ubuntu:14.04

# Setup enviroment variables
ENV DEBIAN_FRONTEND noninteractive

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

# Define mountable directories.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

# Define default command.
CMD bash -C 'bash'

# Expose ports.
EXPOSE 5901
EXPOSE 6080
