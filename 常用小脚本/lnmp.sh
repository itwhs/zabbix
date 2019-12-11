#!/bin/bash
nginx_log_dir=/var/log/nginx
base_nginx=/usr/local/nginx
mysql_package=mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
base_mysql=/usr/local/mysql
data_mysql=/opt/data

# close firewalld
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -ri 's/(SELINUX=).*/\1disabled/g' /etc/sysconfig/selinux

# config yum
cd /etc/yum.repos.d/
curl -o 163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
sed -i 's/\$releasever/7/g' /etc/yum.repos.d/163.repo
sed -i 's/^enabled=.*/enabled=1/g' /etc/yum.repos.d/163.repo
yum clean all
yum -y install epel-release
yum -y install wget gcc gcc-c++

# install nginx
id nginx
if [ $? -ne 0 ];then
    groupadd -r nginx
    useradd -r -M -s /sbin/nologin -g nginx nginx
fi

# install provides packages
yum -y install pcre-devel openssl openssl-devel gd-devel
yum -y groups mark install 'Development Tools'

# create log store directory
if [ ! -d "$nginx_log_dir" ];then
    mkdir -p $nginx_log_dir
fi
chown -R nginx.nginx $nginx_log_dir

if [ ! -f /usr/src/nginx-1.14.0.tar.gz ];then
    cd /usr/src
    wget ftp://seancheng:align2017@172.16.12.1:/sources/source/nginx-1.14.0.tar.gz
fi
tar xf nginx-1.14.0.tar.gz
cd nginx-1.14.0
./configure \
--prefix=$base_nginx \
--user=nginx \
--group=nginx \
--with-debug \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_image_filter_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--http-log-path=$nginx_log_dir/access.log \
--error-log-path=$nginx_log_dir/error.log
make -j $(grep 'processor' /proc/cpuinfo | wc -l) && make install

# after nginx is installed
echo "export PATH=$base_nginx/sbin:\$PATH" > /etc/profile.d/nginx.sh
. /etc/profile.d/nginx.sh
$base_nginx/sbin/nginx
ss -antl


#install and configure mysql
cd /usr/src/
if [ ! -f /usr/src/mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz ];then
    wget ftp://seancheng:align2017@172.16.12.1:/sources/source/mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
fi

if [ -f /etc/my.cnf ];then
    mv /etc/my.cnf /tmp/
fi

#create user and group
id mysql
if [ $? -ne 0 ];then
    groupadd -r mysql
    useradd -r -M -s /sbin/nologin -g mysql mysql
fi
echo 'unarchiving'
tar xf mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
ln -s /usr/local/mysql-5.7.22-linux-glibc2.12-x86_64 $base_mysql
ln -s /usr/local/mysql/include/ /usr/local/include/mysql
echo '/usr/local/mysql/lib' > /etc/ld.so.conf.d/mysql.conf
ldconfig
chown -R mysql.mysql $base_mysql
echo "export PATH=$base_mysql/bin:\$PATH" > /etc/profile.d/mysql.sh
. /etc/profile.d/mysql.sh

if [ ! -d $data_mysql ];then
    mkdir $data_mysql
fi
chown -R mysql.mysql $data_mysql
$base_mysql/bin/mysqld --initialize --user=mysql --datadir=$data_mysql &>/var/log/mysql.log
temp_password=$(grep 'password' /var/log/mysql.log | awk '{print $NF}')

#config file of mysql
cat > /etc/my.cnf <<EOF
[mysqld]
basedir = /usr/local/mysql
datadir = /opt/data
socket = /tmp/mysql.sock
port = 3306
pid-file = /opt/data/mysql.pid
user = mysql
skip-name-resolve
EOF

# config scripts of mysql
cp -a /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
sed -ri 's#^(basedir=).*#\1/usr/local/mysql#g' /etc/init.d/mysqld
sed -ri 's#^(datadir=).*#\1/opt/data#g' /etc/init.d/mysqld

# start service
service mysqld start
ss -antl
ps -ef|grep mysql

# set password
mysql -uroot -p"$temp_password" --connect-expired-password -e 'set password=password("wangqing123!");'


# install and config php
yum -y install libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel mhash mhash-devel

cd /usr/src/
if [ ! -f /usr/src/php-7.2.8.tar.xz ];then
    wget ftp://seancheng:align2017@172.16.12.1:/sources/source/php-7.2.8.tar.xz
fi
tar xf php-7.2.8.tar.xz
cd php-7.2.8
./configure --prefix=/usr/local/php7 \
--with-curl \
--with-freetype-dir \
--with-gd \
--with-gettext \
--with-iconv-dir \
--with-kerberos \
--with-libdir=lib64 \
--with-libxml-dir=/usr \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-openssl \
--with-pcre-regex \
--with-pdo-mysql \
--with-pdo-sqlite \
--with-pear \
--with-jpeg-dir \
--with-png-dir \
--with-xmlrpc \
--with-xsl \
--with-zlib \
--with-config-file-path=/etc \
--with-config-file-scan-dir=/etc/php.d \
--with-bz2 \
--enable-fpm \
--enable-bcmath \
--enable-libxml \
--enable-inline-optimization \
--enable-mbregex \
--enable-mbstring \
--enable-opcache \
--enable-pcntl \
--enable-shmop \
--enable-soap \
--enable-sockets \
--enable-sysvsem \
--enable-xml \
--enable-zip
make -j $(cat /proc/cpuinfo |grep processor|wc -l) && make install

#after install config
echo 'export PATH=/usr/local/php7/bin:$PATH' > /etc/profile.d/php7.sh
. /etc/profile.d/php7.sh
\cp /usr/src/php-7.2.8/php.ini-production /etc/php.ini
\cp /usr/src/php-7.2.8/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
\cp /usr/local/php7/etc/php-fpm.conf.default /usr/local/php7/etc/php-fpm.conf
\cp /usr/local/php7/etc/php-fpm.d/www.conf.default /usr/local/php7/etc/php-fpm.d/www.conf

cat >> /usr/local/php7/etc/php-fpm.conf <<'EOF'
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 8
EOF

service php-fpm start
ss -antl
ps -ef|grep php


# config nginx
\cp /usr/local/nginx/conf/nginx.conf{,-bak}

cat > $base_nginx/conf/nginx.conf <<'EOF'
user  nginx;
worker_processes  4;
error_log  logs/error.log;
pid        logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  logs/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        access_log  logs/host.access.log  main;
        location / {
            root   html;
            index  index.php index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
}
EOF

cat > /usr/local/nginx/html/index.php <<EOF
<?php
    phpinfo();
?>
EOF

nginx -s reload
