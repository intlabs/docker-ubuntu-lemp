#startup.sh

#Start memcached d
service memcached start

#Start supervisord
supervisord -c /etc/supervisor/supervisord.conf