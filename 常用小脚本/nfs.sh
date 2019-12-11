#!/bin/bash
CLIENT_IP=$1
MOUNT_POINT=$2
STOREAGE=/data
SERVER_IP=$(ip a|grep 'inet '|egrep -v '127.0.0.1|grep'|awk -F '[ /]+' '{print $3}')



#close firewalld and selinux
setenforce 0
sed -ri 's/^(SELINUX=).*/\1disabled/g' /etc/sysconfig/selinux
systemctl stop firewalld
systemctl disable firewalld

#install software
yum clean all &>/dev/null
if [ $? -ne 0 ];then
    cd /etc/yum.repos.d/
    curl -o 163.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
    sed -i 's/\$releasever/7/g' /etc/yum.repos.d/163.repo
else
    yum install nfs‐utils ‐y &>/dev/null
    yum install rpcbind ‐y &>/dev/null
fi
echo "$STORAGE ${CLIENT_IP}(rw,async)" > /etc/exports 
if [ ! -d $STORAGE ];then 
    mkdir -p $STORAGE
    chmod 777 $STORAGE
    chown ‐R nfsnobody.nfsnobody $STORAGE
fi
systemctl start nfs‐server &>/dev/null
ssh root@$CLIENT_IP 'yum -y install nfs-utils'
ssh root@$CLIENT_IP "showmount ‐e $SERVER_IP"
ssh root@$CLIENT_IP "mkdir -p $MOUNT_POINT"
ssh root@$CLIENT_IP "mount ‐t nfs ${SERVER_IP}:$STORAGE $MOUNT_POINT"
