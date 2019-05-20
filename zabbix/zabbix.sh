#!/bin/bash
zbmysqlName=zabbix
zbmysqlUser=zabbix
zbmysqlPass=zabbix123!
zbserverconf=/usr/local/etc/zabbix_server.conf
apachedir=/usr/local/apache
mysqlpass=itwhsgithubio
mysqlDir=/usr/local/mysql/
log=/root/zabbix.log
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
if [ $1 -ne 6 ];then
    [ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
    ym
fi
#安装依赖包
yum -y install net-snmp-devel libevent-devel libxml2-devel curl-devel pcre* OpenIPMI OpenIPMI-devel perl-ZMQ-LibZMQ3 libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel newt dialog wget vim

#创建zabbix用户和组
id zabbix
if [ $? -ne 0 ];then
groupadd -r zabbix
useradd -r -g zabbix -M -s /sbin/nologin zabbix
fi
function fwd(){
#配置zabbix数据库
/usr/local/mysql/bin/mysql -uroot -p$mysqlpass <<< "
CREATE DATABASE $zbmysqlName CHARACTER SET utf8 collate utf8_bin;
GRANT ALL privileges on $zbmysqlName.* TO '$zbmysqlUser'@'localhost' IDENTIFIED BY '$zbmysqlPass';
USE mysql;
SELECT user,host FROM user;
FLUSH PRIVILEGES;"

#编译安装zabbix
[ -d /usr/src/zabbix-4.2.1 ] || tar xf Package/zabbix-4.2.1.tar.gz -C /usr/src/
for i in schema.sql images.sql data.sql;do
   /usr/local/mysql/bin/mysql -u$zbmysqlUser -p$zbmysqlPass $zbmysqlName < /usr/src/zabbix-4.2.1/database/mysql/$i
done
cd /usr/src/zabbix-4.2.1
./configure --enable-server --enable-agent --with-mysql=$(find ${mysqlDir} -name "mysql_config") --with-net-snmp --with-libcurl --with-libxml2
make install 2>$log

#zabbix服务端配置
sed -ri /^DBName=/d $zbserverconf
sed -ri /^DBUser=/d $zbserverconf
sed -ri /^DBPassword=/d $zbserverconf
sed -ri "s/(DBName=)/&\n\1$zbmysqlName/" $zbserverconf
sed -ri "s/(DBUser=)/&\n\1$zbmysqlUser/" $zbserverconf
sed -ri "s/.*(DBPassword=).{0,}/&\n\1$zbmysqlPass/" $zbserverconf
zabbix_server
zabbix_agentd
sed -ri 's/(post_max_size =).*/\1 16M/g' /etc/php.ini
sed -ri 's/(max_execution_time =).*/\1 300/g' /etc/php.ini
sed -ri 's/(max_input_time =).*/\1 300/g' /etc/php.ini
sed -i '/;date.timezone/a date.timezone = Asia/Shanghai' /etc/php.ini
service php-fpm restart
[ ! -d $apachedir/htdocs/zabbix ] && mkdir $apachedir/htdocs/zabbix
\cp -a /usr/src/zabbix-4.2.1/frontends/php/* $apachedir/htdocs/zabbix/
id apache
if [ $? -ne 0 ];then
    groupadd -r apache
    useradd -r -g apache -M -s /sbin/nologin apache
fi
chown -R apache.apache $apachedir/htdocs

#配置apache虚拟主机
cat >>/etc/httpd/httpd.conf <<WHS
#在配置文件的末尾加如下内容
ServerName zabbix.wenhs.com:80
<VirtualHost *:80>
    DocumentRoot "$apachedir/htdocs/zabbix"
    ServerName zabbix.wenhs.com
    ProxyRequests Off
    ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000$apachedir/htdocs/zabbix/$1
    <Directory "$apachedir/htdocs/zabbix">
        Options none
        AllowOverride none
        Require all granted
    </Directory>
</VirtualHost>
WHS
#设置zabbix/conf目录的权限，让zabbix有权限生成配置文件zabbix.conf.php
chmod 777 $apachedir/htdocs/zabbix/conf
#重启服务,去web端安装
$apachedir/bin/apachectl stop 2>$log
$apachedir/bin/apachectl start 2>$log
echo "请访问web:http://zabbix.wenhs.com完成安装"
echo "安装完成,自行恢复zabbix/conf目录的权限为755"
echo "chmod 755 /usr/local/apache/htdocs/zabbix/conf"
echo "zabbix默认登录用户名和密码：Admin和zabbix"
}
function khd(){
PET=$(whiptail --title "Server IP Address Input" --inputbox "Please Input Zabbix Server IP Address" 10 60 172.16.41.163 3>&1 1>&2 2>&3)
if [ $? -eq 0 ]; then
    ZabbixServerIp=$PET
    echo $ZabbixServerIp
fi
[ ! -f zabbix-4.2.1.tar.gz ] && wget https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/4.2.1/zabbix-4.2.1.tar.gz
[ ! -d /usr/src/zabbix-4.2.1 ] && tar xf zabbix-4.2.1.tar.gz -C /usr/src/
cd /usr/src/zabbix-4.2.1
./configure --enable-agent
make install 2>$log
[ $? != 0 ] && exit 1
sed -ri "s/(Server=)127.0.0.1/\1$ZabbixServerIp/" /usr/local/etc/zabbix_agentd.conf
sed -ri "s/(ServerActive=).*/\1$ZabbixServerIp/" /usr/local/etc/zabbix_agentd.conf
sed -ri "s/(Hostname=).*/\1$(hostname)/" /usr/local/etc/zabbix_agentd.conf
#启动zabbix_agentd
zabbix_agentd
echo "启动zabbix_agentd"
}
if (whiptail --title "install server or client" --yes-button "Server" --no-button "client"  --yesno "What do you want to install?" 10 60) then
    fwd
else
    khd
fi

