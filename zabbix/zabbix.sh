#!/bin/bash
zbmysqlName=zabbix
zbmysqlUser=zabbix
zbmysqlPass=zabbix123!
zbserverconf="/usr/local/etc"    #zabbix配置文件路径
#钉钉
atmobiles=xxxxxxxxxxx    #@群里的手机号用户
atall=False    #Ture为@所有人,False则不@
webhook="https://oapi.dingtalk.com/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"    #钉钉机器人的webhook
#微信
corpid=xxxxxxxxxxxxxxxxxxx   # CorpID是企业号的标识
secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    # Secret是管理组凭证密钥
agentid=xxxxxxxxx   # 应用ID
partyid=2        # 部门ID	
apachedir="/usr/local/apache"
document_root="/usr/local/nginx/html"
nginxconf="/usr/local/nginx/conf/nginx.conf"
nginxvhost="/usr/local/nginx/conf/vhost.type"
mysqlpass=itwhsgithubio
mysqlDir="/usr/local/mysql/"
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
yum -y install net-snmp-devel libevent-devel libxml2-devel curl-devel pcre* OpenIPMI OpenIPMI-devel perl-ZMQ-LibZMQ3 libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel newt dialog wget vim python-pip python-wheel python-setuptools
pip install requests
pip install --upgrade requests
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
sed -ri /^DBName=/d $zbserverconf/zabbix_server.conf
sed -ri /^DBUser=/d $zbserverconf/zabbix_server.conf
sed -ri /^DBPassword=/d $zbserverconf/zabbix_server.conf
sed -ri "s/(DBName=)/&\n\1$zbmysqlName/" $zbserverconf/zabbix_server.conf
sed -ri "s/(DBUser=)/&\n\1$zbmysqlUser/" $zbserverconf/zabbix_server.conf
sed -ri "s/.*(DBPassword=).{0,}/&\n\1$zbmysqlPass/" $zbserverconf/zabbix_server.conf

sed -ri 's/(post_max_size =).*/\1 16M/g' /etc/php.ini
sed -ri 's/(max_execution_time =).*/\1 300/g' /etc/php.ini
sed -ri 's/(max_input_time =).*/\1 300/g' /etc/php.ini
sed -i '/;date.timezone/a date.timezone = Asia/Shanghai' /etc/php.ini
service php-fpm restart
function apq(){
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
}
function ngx(){
[ ! -d $document_root/zabbix ] && mkdir $document_root/zabbix
\cp -a /usr/src/zabbix-4.2.1/frontends/php/* $document_root/zabbix/
id nginx
if [ $? -ne 0 ];then
    groupadd -r nginx
    useradd -r -g nginx -M -s /sbin/nologin nginx
fi
chown -R nginx.nginx $document_root
#配置nginx虚拟主机
sed -ri /^http/a"\ \ \ \ include\ \ \ \ \ \ \ vhost.type;" $nginxconf
cat >> $nginxvhost <<'WHS'
    server {
        listen       80;
        server_name  zabbix.wenhs.com;
        access_log  logs/zabbix.log;
        location ~ \.php$ {
            root           html/zabbix;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }
WHS
#设置zabbix/conf目录的权限，让zabbix有权限生成配置文件zabbix.conf.php
chmod 777 $document_root/zabbix/conf
}
if [ $1 -eq 3 ];then
    ngx
else
    if [ $1 -eq 4 ];then
        apq
	else
	    echo "执行失败,没有成功调用函数"
    fi
fi
[ -d $zbserverconf/scripts ] || mkdir $zbserverconf/scripts
sed -ri /^AlertScriptsPath=/d $zbserverconf/zabbix_server.conf
sed -ri "s#.*(AlertScriptsPath=).{0,}#&\n\1$zbserverconf/scripts#" $zbserverconf/zabbix_server.conf
cat >/usr/local/etc/scripts/ding.py <<DIN
#!/usr/bin/python
# -*- coding: utf-8 -*-
import requests
import json
import sys
import os
headers = {'Content-Type': 'application/json;charset=utf-8'}
#api_url后跟告警机器人的webhook
api_url = "$webhook"
def msg(text):
   json_text= {
    "msgtype": "text",
    "text": {
        "content": text
    },
    "at": {
        "atMobiles": [
            "$atmobiles"
        ],
        "isAtAll": $atall
    }
   }
   print(requests.post(api_url,json.dumps(json_text),headers=headers).content)
if __name__ == '__main__':
   text = sys.argv[1]
   msg(text)
DIN
cat >/usr/local/etc/scripts/dingding.py <<DIY
#!/usr/bin/env python
#coding:utf-8
import requests,json,sys,os,datetime
webhook="$webhook"
user=sys.argv[1]
text=sys.argv[3]
data={
    "msgtype": "text",
    "text": {
        "content": text
    },
    "at": {
        "atMobiles": [
            user
        ],
        "isAtAll": False
    }
}
headers = {'Content-Type': 'application/json'}
x=requests.post(url=webhook,data=json.dumps(data),headers=headers)
if os.path.exists("/tmp/ding.log"):
    f=open("/tmp/ding.log","a+")
else:
    f=open("tmp/ding.log","w+")
f.write("\n"+"--"*30)
if x.json()["errcode"] == 0:
    f.write("\n"+str(datetime.datetime.now())+"    "+str(user)+"    "+"发送成功"+"\n"+str(text))
    f.close()
else:
    f.write("\n"+str(datetime.datetime.now()) + "    " + str(user) + "    " + "发送失败" + "\n" + str(text))
    f.close()
DIY
cat >/usr/local/etc/scripts/wechat.py <<END
#!/usr/bin/python2.7
#_*_coding:utf-8 _*_

import requests,sys,json
import urllib3
urllib3.disable_warnings()

reload(sys)
sys.setdefaultencoding('utf-8')

def GetTokenFromServer(Corpid,Secret):
    Url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken"
    Data = {
        "corpid":Corpid,
        "corpsecret":Secret
    }
    r = requests.get(url=Url,params=Data,verify=False)
    print(r.json())
    if r.json()['errcode'] != 0:
        return False
    else:
        Token = r.json()['access_token']
        file = open('/tmp/zabbix_wechat_config.json', 'w')
        file.write(r.text)
        file.close()
        return Token

def SendMessage(User,Agentid,Subject,Content):
    try:
        file = open('/tmp/zabbix_wechat_config.json', 'r')
        Token = json.load(file)['access_token']
        file.close()
    except:
        Token = GetTokenFromServer(Corpid, Secret)

    n = 0
    Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
    Data = {
        "touser": User,
        "totag": Tagid,
        "toparty": Partyid,
        "msgtype": "text",
        "agentid": Agentid,
        "text": {
            "content": Subject + '\n' + Content
        },
        "safe": "0"
    }
    r = requests.post(url=Url,data=json.dumps(Data),verify=False)
    while r.json()['errcode'] != 0 and n < 4:
        n+=1
        Token = GetTokenFromServer(Corpid, Secret)
        if Token:
            Url = "https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s" % Token
            r = requests.post(url=Url,data=json.dumps(Data),verify=False)
            print(r.json())

    return r.json()


if __name__ == '__main__':
    User = sys.argv[1]              # zabbix传过来的第一个参数
    Subject = str(sys.argv[2])      # zabbix传过来的第二个参数
    Content = str(sys.argv[3])      # zabbix传过来的第三个参数

    Corpid = "$corpid" 
    Secret = "$secret" 
    Tagid = "zabbix"    # 通讯录标签ID
    Agentid = "$agentid"
    Partyid = "$partyid"

    Status = SendMessage(User,Agentid,Subject,Content)
    print Status
END

cat >/usr/local/etc/scripts/sendmail.sh <<'MIL'
#!/bin/bash
#$1是{ALERT.SENDTO}收件人邮箱
#$2是{ALERT.SUBJECT}主题
#$3是{ALERT.MESSAGE}正文信息
subject=$(echo $2 |tr "\r\n" "\n")
message=$(echo $3 |tr "\r\n" "\n")
echo "$message" | /usr/bin/mail -s "$subject" $1 &>/tmp/sm.log
MIL
chown -R zabbix.zabbix $zbserverconf/scripts
chmod +x $zbserverconf/scripts/*
zabbix_server
zabbix_agentd
#重启服务,去web端安装
function apqon(){
$apachedir/bin/apachectl stop 2>$log
$apachedir/bin/apachectl start 2>$log
}
function ngxon(){
/etc/init.d/nginx restart
}
if [ $1 -eq 3 ];then
    ngxon
else
    if [ $1 -eq 4 ];then
        apqon
        else
            echo "执行失败,没有成功调用函数"
    fi
fi

echo "请访问web:http://zabbix.wenhs.com完成安装"
echo "安装完成,自行恢复zabbix/conf目录的权限为755"
echo "chmod 755 /usr/local/apache/htdocs/zabbix/conf"
echo "zabbix默认登录用户名和密码：Admin和zabbix"
echo "告警媒介有3个脚本,名称:ding.py , dingding.py , wechat.py , sendmail.sh,自行添加"
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

