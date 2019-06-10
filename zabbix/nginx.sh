#!/bin/bash
logdir=/var/log/nginx
nginxdir=/usr/local/nginx
cores=$(grep 'core id' /proc/cpuinfo | sort -u | wc -l)
log=/root/nginxinstall.log
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
if [ $1 -ne 5 ];then
    [ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
    ym
fi
#安装依赖包
yum -y install pcre-devel openssl openssl-devel gd-devel zlib-devel gcc gcc-c++
#创建日志存放目录
id nginx 2>$log
if [ $? != 0 ];then
useradd -r -M -s /sbin/nologin nginx
fi

mkdir -p $logdir
chown -R nginx.nginx $logdir
if [ ! -f Package/nginx-1.16.0.tar.gz ];then
    wget -O Package/nginx-1.16.0.tar.gz http://nginx.org/download/nginx-1.16.0.tar.gz
else
    if [ ! -d /usr/src/nginx-1.16.0 ];then
        tar xf Package/nginx-1.16.0.tar.gz -C /usr/src/
    fi
fi
cd /usr/src/nginx-1.16.0
./configure --prefix=$nginxdir --user=nginx --group=nginx --with-debug --with-http_ssl_module --with-http_realip_module --with-http_image_filter_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_stub_status_module --http-log-path=$logdir/access.log --error-log-path=$logdir/error.log --with-pcre
make -j$cores 2>$log && make install


#添加服务控制脚本
cat >>/etc/init.d/nginx <<'EOF'
#!/bin/bash
nginx="/usr/local/nginx/sbin/nginx"
NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"
pid="/usr/local/nginx/logs/nginx.pid"
case $1 in
	start)
		$nginx -c $NGINX_CONF_FILE
		;;
	stop)
		$nginx -s stop
		;;
	restart)
		$nginx -s stop
		sleep 1
		$nginx -c $NGINX_CONF_FILE
		;;
	reload)
		$nginx -s reload
		;;
	status)
		if [ -f $pid ];then
		    echo "nginx is running"
        else
		    echo "nginx is stoped"
	    fi
		;;
	*)
		echo $"Usage: $0 {start|stop|status|restart|reload}"
		exit 2
		;;
esac
EOF
chmod +x /etc/init.d/nginx

##添加环境变量
echo "export PATH=$nginxdir/sbin:\$PATH" >/etc/profile.d/nginx.sh
echo "请执行 : source /etc/profile.d/nginx.sh 来添加环境变量"
echo  "安装完成"
echo "启动服务方法:service nginx start|stop|status|restart|reload "

