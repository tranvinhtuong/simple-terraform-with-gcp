#! /bin/bash

sudo su
# mount and format data disk
lsblk
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
mkdir -p /data-mount
mount -o discard,defaults /dev/sdb /data-mount
chmod a+w+r /data-mount

# auto mount when reboot vm
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` /data-mount ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
blkid -s UUID -o value /dev/sdb

# install necessary package
dnf install nginx -y
systemctl start nginx
systemctl enable nginx
dnf install mariadb-server mariadb -y
systemctl enable --now mariadb
dnf install php php-mysqlnd php-dom php-simplexml php-xml php-xmlreader php-curl php-exif php-ftp php-gd php-iconv php-json php-mbstring php-posix php-sockets php-tokenizer php-common php-gmp php-intl php-zip unzip -y
dnf install wget vim -y
wget https://wordpress.org/latest.tar.gz
tar xvf latest.tar.gz
mv wordpress /data-mount/wp

cd /data-mount/wp/
cp wp-config-sample.php wp-config.php

# auto config database mysql
sed -i 's/database_name_here/database/' /data-mount/wp/wp-config.php
sed -i 's/username_here/group3/' /data-mount/wp/wp-config.php
sed -i 's/password_here/Group3ACN!/' /data-mount/wp/wp-config.php
sed -i 's/localhost/10.207.0.3/' /data-mount/wp/wp-config.php


# change the owner to NGINX to use this folder.
chown -R nginx:nginx /data-mount/wp/
chmod -R 775 /data-mount/wp/


touch /etc/nginx/conf.d/wp.conf

# create a virtual server
cat << EOF > /etc/nginx/conf.d/wp.conf
server {
        listen 80;
        server_name vinhtuongtran.id.vn www.vinhtuongtran.id.vn;

        root /data-mount/wp;

        index index.html index.php;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index   index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
}
EOF



# change to user & group of nginx
sudo sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf


# restart php-fpm
sudo systemctl restart php-fpm


# check nginx
sudo nginx -t


# restart nginx
systemctl restart nginx 


# config firewall
firewall-cmd --zone=public --permanent --add-port 80/tcp
firewall-cmd --zone=public --permanent --add-port 443/tcp
firewall-cmd --reload



# configure SElinux
sudo setsebool -P httpd_can_network_connect 1

# set SELinux context for wp folder
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/data-mount/wp(/.*)?"
sudo restorecon -Rv /data-mount/wp


# certbox ssl
sudo dnf install epel-release -y
sudo dnf  install python3-certbot-nginx -y
sudo nginx -t
sudo systemctl reload nginx


sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd -reload
certbot --noninteractive --nginx --agree-tos --register-unsafely-without-email -d wwww.vinhtuongtran.id.vn



sudo systemctl reload nginx

















































