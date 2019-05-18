#!/bin/bash
phpdir=/usr/local/php7
phpmysql=/usr/local/mysql/bin/mysql_config
cores=$(grep 'core id' /proc/cpuinfo | sort -u | wc -l)
log=/root/phpinstall.log
function ym(){
#配置网络源
#本脚本为配置网络源,会把原有的源文件移动到opt/yum.bak目录下,执行完请自行恢复
if [ -d /opt/yum.bak ];then
	mv /etc/yum.repos.d/* /opt/yum.bak/
else
	mkdir /opt/yum.bak
	mv /etc/yum.repos.d/* /opt/yum.bak/
fi
curl -o /etc/yum.repos.d/CentOS7-Base-163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo 
sed -i 's/\$releasever/7/g' /etc/yum.repos.d/CentOS7-Base-163.repo
sed -i 's/^enabled=.*/enabled=1/g' /etc/yum.repos.d/CentOS7-Base-163.repo
yum clean all 
yum list all |wc -l
[ $? -ne 0 ] && echo "请检查网络或yum仓库" && exit 5
yum groups mark install 'Development Tools'
yum -y remove epel-release
yum -y install epel-release 
}
if [ $1 -ne 9 ];then
    [ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
    ym
fi
#安装依赖包
yum -y install libxml2 libxml2-devel openssl openssl-de vel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel mhash mhash-devel
#解压并编译安装php
[ ! -d php-7.2.8 ] && tar -xf ./Package/php-7.2.8.tar.xz
cd ./php-7.2.8/
./configure --prefix=$phpdir  --with-curl  --with-freetype-dir  --with-gd  --with-gettext  --with-iconv-dir  --with-kerberos  --with-libdir=lib64  --with-libxml-dir=/usr  --with-mysqli=$phpmysql  --with-openssl  --with-pcre-regex  --with-pdo-mysql  --with-pdo-sqlite  --with-pear  --with-jpeg-dir  --with-png-dir  --with-xmlrpc  --with-xsl  --with-zlib  --with-config-file-path=/etc  --with-config-file-scan-dir=/etc/php.d  --with-bz2  --enable-fpm  --enable-bcmath  --enable-libxml  --enable-inline-optimization  --enable-mbregex  --enable-mbstring  --enable-opcache  --enable-pcntl  --enable-shmop  --enable-soap  --enable-sockets  --enable-sysvsem --enable-xml  --enable-zip
make -j$cores 2>$log && make install
[ $? != 0 ] && exit 1
#将路径写入环境变量中
echo "export PATH=$phpdir/bin:\$PATH" >/etc/profile.d/php7.sh
source /etc/profile.d/php7.sh
#配置php-fpm
\cp php.ini-production /etc/php.ini
\cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on
\cp $phpdir/etc/php-fpm.conf.default $phpdir/etc/php-fpm.conf 2>$log
\cp $phpdir/etc/php-fpm.d/www.conf.default  $phpdir/etc/php-fpm.d/www.conf 2>$log
#编辑php-fpm配置文件，新添如下几行
cat >>$phpdir/etc/php-fpm.conf <<END
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 8
END
#启动php-fpm
service php-fpm restart
ss -tnl | grep ':9000' &>/dev/null
[ $? != 0 ] && exit 1
echo "php7成功启动"

