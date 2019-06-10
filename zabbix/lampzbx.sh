#!/bin/bash
[ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
#read -p "请看README文件的注意事项,找到正确的口令,请输入口令:" KEY
#if [ $KEY != "W" ] &>/dev/null;then
#	echo "输入错误,请查看README注意事项信息,以便您的操作"
#	exit
#fi
apachedir=/usr/local/apache
apacheconfdir=/etc/httpd
log=/root/lampinstall.log
function check(){
if [ $? -ne 0 ];then
	echo "执行失败,请看root目录下的错误日志"
	exit
fi
}
function ymu(){
bash yum.sh 2>$log
check
}
function zbx(){
bash zabbix.sh 4 2>$log
check
}
function apa(){
bash apache.sh 7 2>$log
check
}
function sql(){
bash mysql.sh 8 2>$log
check
}
function php7(){
bash php.sh 9 2>$log
check
}
ymu && apa && sql && php7
check
#启用httpd 的相关模块，取消指定两行前面的#
sed -i '/proxy_module/s/#//g' $apacheconfdir/httpd.conf
sed -i '/proxy_fcgi_module/s/#//g' $apacheconfdir/httpd.conf
#创建虚拟主机目录并生成php测试页面
[ ! -d $apachedir/htdocs/wenhs ] && mkdir $apachedir/htdocs/wenhs
cat > $apachedir/htdocs/wenhs/index.php << EOF
<?php
   phpinfo();
?>
EOF
id apache
if [ $? -ne 0 ];then
    groupadd -r apache
    useradd -r -g apache -M -s /sbin/nologin apache
fi
chown -R apache.apache $apachedir/htdocs/ 2>$log
#配置apache访问页面
[ ! -f $apacheconfdir/httpd.conf.back ] && cp $apacheconfdir/httpd.conf{,.back}
\cp $apacheconfdir/httpd.conf{.back,}
cat >>$apacheconfdir/httpd.conf <<ZXC
#修改配置文件，添加以下内容
ServerName www.wenhs.com:80
AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps

<VirtualHost *:80>
    DocumentRoot "$apachedir/htdocs/wenhs"
    ServerName www.wenhs.com
    ProxyRequests Off
    ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000$apachedir/htdocs/wenhs/$1
    <Directory "$apachedir/htdocs/wenhs">
        Options none
        AllowOverride none
        Require all granted
    </Directory>
</VirtualHost>
ZXC
sed -i '/DirectoryIndex/s/index.html/index.php index.html/g' $apacheconfdir/httpd.conf 
#重启apache服务
$apachedir/bin/apachectl stop
$apachedir/bin/apachectl start
echo "lamp安装完成"
zbx
echo "zabbix安装完成"
