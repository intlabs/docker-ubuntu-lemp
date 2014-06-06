#startup.sh

# (c) 2014 Pete Birley

#Start memcached d
service memcached start

#Start supervisord
supervisord -c /etc/supervisor/supervisord.conf