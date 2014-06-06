#startup.sh

# (c) 2014 Pete Birley

#Start memcached d
service memcached start

#Start supervisord
supervisord -c /etc/supervisor/supervisord.conf

#Install sshfs
apt-get install -y fuse sshfs

#Mount dropbox
mkdir -p ~/.ssh && ssh -p 222 -o 'StrictHostKeyChecking no' -o "BatchMode yes" 172.16.0.147 cat /etc/ssh/ssh_host_dsa_key.pub >>~/.ssh/known_hosts
mkdir -p /usr/share/nginx/html/home/admin/dropbox && echo acoman | sshfs -p 222 root@172.16.0.147:/mnt/dropbox /usr/share/nginx/html/home/admin/dropbox -o allow_root -o password_stdin
