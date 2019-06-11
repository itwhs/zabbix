#!/bin/bash
apaconf=/usr/local/apache/conf
ngxconf=/usr/local/nginx
#CA生成一对密钥
cd /etc/pki/CA/
#生成密钥，括号必须要
(umask 077;openssl genrsa -out private/cakey.pem 2048)
#提取公钥
openssl rsa -in private/cakey.pem -pubout
#CA生成自签署证书
#生成自签署证书
openssl req -new -x509 -key private/cakey.pem -out cacert.pem -days 365 <<EOF
CN
HuBei
WuHan
itw.design
itw.design
itw.design
qingjiuyeye@gmail.com
EOF
#读出cacert.pem证书的内容
openssl x509 -text -in cacert.pem
mkdir certs newcerts crl &>/dev/null
touch index.txt && echo 01 > serial
function httpd(){
#客户端（例如httpd服务器）生成密钥
cd $apaconf
mkdir ssl && cd ssl
(umask 077;openssl genrsa -out httpd.key 2048)
#客户端生成证书签署请求
openssl req -new -key httpd.key -days 365 -out httpd.csr <<END
CN
HuBei
WuHan
itw.design
itw.design
itw.design
qingjiuyeye@gmail.com


END
#CA签署客户端提交上来的证书
openssl ca -in httpd.csr -out httpd.crt -days 365 <<ZXC
y
y
ZXC
}
function nginx(){
#客户端（例如httpd服务器）生成密钥
cd $ngxconf
mkdir ssl && cd ssl
(umask 077;openssl genrsa -out nginx.key 2048)
#客户端生成证书签署请求
openssl req -new -key nginx.key -days 365 -out nginx.csr <<END
CN
HuBei
WuHan
itw.design
itw.design
itw.design
qingjiuyeye@gmail.com


END
#CA签署客户端提交上来的证书
openssl ca -in nginx.csr -out nginx.crt -days 365 <<ZXC
y
y
ZXC
}
read -p "客户端生成什么证书[httpd|nginx]" input
$input
