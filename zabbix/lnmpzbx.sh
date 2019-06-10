#!/bin/bash
[ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
#read -p "请看README文件的注意事项,找到正确的口令,请输入口令:" KEY
#if [ $KEY != "W" ] &>/dev/null;then
#	echo "输入错误,请查看README注意事项信息,以便您的操作"
#	exit
#fi
document_root=/usr/local/nginx/html
nginxconf=/usr/local/nginx/conf/nginx.conf
nginxvhost=/usr/local/nginx/conf/vhost.types
log=/root/lnmpinstall.log
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
function ngx(){
bash nginx.sh 5 2>$log
check
}
function zbx(){
bash zabbix.sh 3 2>$log
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
ymu && ngx && sql && php7
check
#创建虚拟主机目录并生成php测试页面
[ ! -d $document_root/wenhs ] && mkdir $document_root/wenhs
cat > $document_root/wenhs/index.php << EOF
<?php
   phpinfo();
?>
EOF
id nginx
if [ $? -ne 0 ];then
    groupadd -r nginx
    useradd -r -g nginx -M -s /sbin/nologin nginx
fi
chown -R nginx.nginx $document_root/ 2>$log
#配置nginx虚拟主机
\cp $nginxconf{.default,}
sed -ri /^http/a"\ \ \ \ include\ \ \ \ \ \ \ vhost.types;" $nginxconf
cat >> $nginxvhost <<'ZXC'
    server {
        listen       80;
		index index.php index.html;
        location ~ \.php$ {
            root           html/wenhs;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
ZXC
#重启nginx服务
/etc/init.d/nginx restart
echo "lnmp安装完成"
zbx
echo "zabbix安装完成"
