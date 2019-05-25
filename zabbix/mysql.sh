#!/bin/bash
log=/root/mysqlinstall.log
mysqlpass=itwhsgithubio
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
if [ $1 -ne 8 ];then
    [ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
    ym
fi
#安装依赖包
yum -y install ncurses-devel openssl-devel openssl cmake mariadb-devel
#创建mysql用户和组
id mysql
if [ $? != 0 ];then
groupadd -r mysql
useradd -r -M -s /sbin/nologin -g mysql mysql
fi
#解压二进制包，并创建连接修改属主和属组
[ -d /usr/local/mysql-5.7.25-linux-glibc2.12-x86_64 ] || tar -xf ./Package/mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
cd /usr/local/
chown -R mysql.mysql mysql-5.7.25-linux-glibc2.12-x86_64
ln -sv mysql-5.7.25-linux-glibc2.12-x86_64/ mysql
#添加环境变量
echo 'export PATH=/usr/local/mysql/bin:$PATH' > /etc/profile.d/mysql.sh
echo "请执行: source /etc/profile.d/mysql.sh 来添加环境变量"
#创建存放数据的目录并修改属主
[ -d /opt/data ] || mkdir /opt/data
chown mysql.mysql /opt/data
#初始化数据库(密码在root目录下)
/usr/local/mysql/bin/mysqld --initialize --user=mysql --datadir=/opt/data/ &> /root/password
#安装后配置
ln -sv /usr/local/mysql/include/ /usr/local/include/mysql
echo '/usr/local/mysql/lib' > /etc/ld.so.conf.d/mysql.conf
ldconfig
#生成配置文件
cat >/etc/my.cnf <<EOF
[mysqld]
datadir=/opt/data
basedir = /usr/local/mysql
socket = /tmp/mysql.sock
port = 3306
pid-file = /opt/data/mysql.pid
user = mysql 
skip-name-resolve
EOF
#配置服务启动脚本
cp -a /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
sed -ri 's#^(basedir=).*#\1/usr/local/mysql#g' /etc/init.d/mysqld
sed -ri 's#^(datadir=).*#\1/opt/data#g' /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on
#启动mysql
/etc/init.d/mysqld start
ss -tnl | grep ':3306' &>/dev/null && [ $? != 0 ] && exit 1
echo "mysql启动成功,正在修改密码"
passwd0=$(tail -1 /root/password |awk '{print $NF}')
echo "默认设置的新密码为$mysqlpass" 
/usr/local/mysql/bin/mysqladmin -uroot -p"$passwd0" password "$mysqlpass"
