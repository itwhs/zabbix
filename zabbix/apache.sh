#!/bin/bash
#安装路径,如需要更改,请自行修改下列路径,请用绝对路径
apachedir=/usr/local/apache
apacheconfdir=/etc/httpd
aprdir=/usr/local/apr
aprutil=/usr/local/apr-util
log=/root/apacheinstall.log
cores=$(grep 'core id' /proc/cpuinfo | sort -u | wc -l)
echo "请等待15-30分钟即可安装完成,切勿CTRL+C终止"
function ym(){
#配置网络源
#本脚本为配置网络源,会把原有的源文件移动到opt/yum.bak目录下,执行完请自行恢复
#单独执行该脚本把注释去掉,可以选择安装httpd2.2或者2.4
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
if [ $1 -ne 7 ];then
    [ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
    ym
fi	
##准备环境
echo "安装开发环境"
yum -y install make gcc gcc-c++ gzip bzip2 openssl-devel pcre-devel expat-devel libtool
function check(){
	if [ $? -ne 0 ];then
		echo "执行失败,请看root目录下的错误日志"
		exit
	fi
}
#function httpd2.4(){
##解压源码包
    [ -d apr-1.6.5 ] || tar xf Package/apr-1.6.5.tar.gz
    [ -d apr-util-1.6.1 ] || tar xf Package/apr-util-1.6.1.tar.gz
    [ -d httpd-2.4.39 ] || tar xf Package/httpd-2.4.39.tar.gz	
    echo "完成解压,进入apr-1.6.5"
##源码安装apr
	cd apr-1.6.5
	echo "正在编译安装apr,请稍等"
	sed -i 's/$RM "$cfgfile"/#$RM "$cfgfile"/g' configure
	./configure --prefix=$aprdir 2>$log
	check 
	make -j$cores 2>$log && make install
	echo "安装完成并进入apr-util-1.6.1"
	##源码安装apr-util
	cd ../apr-util-1.6.1/
	echo "正在编译安装apr-util"
	./configure --prefix=$aprutil --with-apr=$aprdir 2>$log
	check 
	make -j$cores 2>$log && make install
	echo "安装完成并进入httpd-2.4.39"
	##源码安装httpd
	cd ../httpd-2.4.39/
	echo "正在编译安装httpd-2.4.39,请等待"
	./configure --prefix=$apachedir --sysconfdir=$apacheconfdir --enable-so --enable-ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-apr=$aprdir --with-apr-util=$aprutil --enable-modules=most  --enable-mpms-shared=all --with-mpm=prefork 2>$log
	check 
#}
#function httpd2.2(){
#	tar xf Package/httpd-2.2.9.tar.gz
#	echo "解压中,准备进入编译,请等待"
#	cd ./httpd-2.2.9/
#	./configure --prefix=$apachedir 2>$log
#	check
#}
#sleep 2
#read -p "请输入你要安装的httpd版本,(输入"2.2"则安装httpd-2.2.9,警告,此脚本装2.2httpd的lamp会失败,切勿尝试,输入其他或空则安装2.4.39): " input
#sleep 5
#if [ $input == "2.2" ] 2>$log;then
#	httpd2.2
#else
#	httpd2.4
#fi
make -j$cores 2>$log && make install
echo "源码编译成功，正在添加环境变量"
##添加man文档
man_apache=$(sed -n '/apache/p' /etc/man_db.conf |wc -l)
if [ $man_apache -eq 0 ];then
echo "MANDATORY_MANPATH $apachedir/man" >> /etc/man_db.conf
man httpd &>/dev/null
check
fi
##添加环境变量
echo "export PATH=$apachedir/bin:\$PATH" >/etc/profile.d/httpd.sh
echo "请执行 : source /etc/profile.d/httpd.sh 来添加环境变量"
echo  "安装完成"
#清理
#安装完成后,可以删除这个httpd.tar,已经不需要了
