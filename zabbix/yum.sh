#!/bin/bash
#配置网络源
#本脚本为配置网络源,会把原有的源文件移动到opt/yum.bak目录下,执行完请自行恢复
[ $UID -ne 0 ] && echo "请使用管理员root用户执行此安装脚本" && exit 1
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

