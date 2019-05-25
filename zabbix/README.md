### 环境:

```.
zabbix
├── apache.sh
├── lampzbx.sh
├── mysql.sh
├── Package
│   ├── apr-1.6.5.tar.gz
│   ├── apr-util-1.6.1.tar.gz
│   ├── httpd-2.2.9.tar.gz
│   ├── httpd-2.4.39.tar.gz
│   ├── mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz
│   ├── php-7.2.8.tar.xz
│   └── zabbix-4.2.1.tar.gz
├── php.sh
├── README.md
├── yum.sh
└── zabbix.sh
```

### 注意事项:

本脚本用来安装httpd-2.2.9或者httpd-2.4.39,mysql-5.7.25,php-7.2.8简称lamp,随后部署zabbix监控服务

MySQL二进制包太大,请自行官网下载,放入Package目录,注意版本和名称要一样
wget https://downloads.mysql.com/archives/get/file/mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz

主要测试环境为centos7或Redhat7,如其他环境,请自行修改

请使用root用户执行此脚本
该脚本开始执行口令KEY是"W"

数据库密码可自行设置,默认为"itwhsgithubio"

zabbix默认数据库是zabbix,库是zabbix,密码zabbix123!

web登录账号Admin密码zabbix

zabbix.sh自带有4个告警媒介脚本,如需使用,请先更改脚本变量,至于使用方法,可参考:
https://blog.csdn.net/wenhs5479

使用此脚本请进入本脚本的目录下,否则无法成功

使用教程:
    bash lampzbx.sh

安装时会在root目录下,生成一些log或者其他配置文件,这些都是无关紧要的,可以删除

如需修改脚本内容,请注意路径关系
另外,强调,各个脚本里面的变量路径要求一致,否则无法成功

如需使用下列功能,请复制下列对应参数,写入configure_info,注意换行符号
常用编译参数一览:

```
./configure   //配置源代码树
–-prefix=/usr/local/apache   //体系无关文件的顶级安装目录PREFIX ，也就Apache的安装目录。
–enable-module=so   //打开 so 模块，so 模块是用来提 DSO 支持的 apache 核心模块
–enable-deflate=shared   //支持网页压缩
–enable-expires=shared   //支持 HTTP 控制
–enable-rewrite=shared   //支持 URL 重写
–enable-cache //支持缓存
–enable-file-cache //支持文件缓存
–enable-mem-cache //支持记忆缓存
–enable-disk-cache //支持磁盘缓存
–enable-static-support   //支持静态连接(默认为动态连接)
–enable-static-htpasswd   //使用静态连接编译 htpasswd – 管理用于基本认证的用户文件
–enable-static-htdigest   //使用静态连接编译 htdigest – 管理用于摘要认证的用户文件
–enable-static-rotatelogs   //使用静态连接编译 rotatelogs – 滚动 Apache 日志的管道日志程序
–enable-static-logresolve   //使用静态连接编译 logresolve – 解析 Apache 日志中的IP地址为主机名
–enable-static-htdbm   //使用静态连接编译 htdbm – 操作 DBM 密码数据库
–enable-static-ab   //使用静态连接编译 ab – Apache HTTP 服务器性能测试工具
–enable-static-checkgid   //使用静态连接编译 checkgid
–disable-cgid   //禁止用一个外部 CGI 守护进程执行CGI脚本
–disable-cgi   //禁止编译 CGI 版本的 PHP
–disable-userdir   //禁止用户从自己的主目录中提供页面
–with-mpm=worker // 让apache以worker方式运行
–enable-authn-dbm=shared // 对动态数据库进行操作。Rewrite时需要。

以下是分门别类的更多参数注解，与上面的会有重复
用于apr的configure脚本的选项：
可选特性
--enable-experimental-libtool    //启用试验性质的自定义libtool
--disable-libtool-lock    //取消锁定(可能导致并行编译崩溃)
--enable-debug    //启用调试编译，仅供开发人员使用。
--enable-maintainer-mode    //打开调试和编译时警告，仅供开发人员使用。
--enable-profile    //打开编译profiling(GCC)
--enable-pool-debug[=yes|no|verbose|verbose-alloc|lifetime|owner|all]    //打开pools调试
--enable-malloc-debug    //打开BeOS平台上的malloc_debug
--disable-lfs    //在32-bit平台上禁用大文件支持(large file support)
--enable-nonportable-atomics    //若只打算在486以上的CPU上运行Apache ，那么使用该选项可以启用更加高效的基于互斥执行的原子操作。
--enable-threads    //启用线程支持，在线程型的MPM上必须打开它
--disable-threads    //禁用线程支持，如果不使用线程化的MPM ，可以关闭它以减少系统开销。
--disable-dso    //禁用DSO支持
--enable-other-child    //启用可靠子进程支持
--disable-ipv6    //禁用IPv6支持
可选的额外程序包
--with-gnu-ld    //指定C编译器使用 GNU ld
--with-pic    //只使用 PIC/non-PIC 对象[默认为两者都使用]
--with-tags[=TAGS]    //包含额外的配置
--with-installbuilddir=DIR    //指定APR编译文件的存放位置(默认值为：’${datadir}/build’)
--without-libtool    //禁止使用libtool连接库文件
--with-efence[=DIR]    //指定Electric Fence的安装目录
--with-sendfile    //强制使用sendfile(译者注：Linux2.4/2.6内核都支持)
--with-egd[=DIR]    //使用EDG兼容的socket
--with-devrandom[=DEV]    //指定随机设备[默认为：/dev/random]

用于apr-util的configure脚本的选项：
可选的额外程序包
--with-apr=PATH    //指定APR的安装目录(–prefix选项值或apr-config的路径)
--with-ldap-include=PATH    //ldap包含文件目录(带结尾斜线)
--with-ldap-lib=PATH    //ldap库文件路径
--with-ldap=library    //使用的ldap库
--with-dbm=DBM    //选择使用的DBM类型DBM={sdbm,gdbm,ndbm,db,db1,db185,db2,db3,db4,db41,db42,db43,db44}
--with-gdbm=PATH    //指定GDBM的位置
--with-ndbm=PATH    //指定NDBM的位置
--with-berkeley-db=PATH    //指定Berkeley DB的位置
--with-pgsql=PATH    //指定PostgreSQL的位置
--with-mysql=PATH    //参看INSTALL.MySQL文件的内容
--with-sqlite3=PATH    //指定sqlite3的位置
--with-sqlite2=PATH    //指定sqlite2的位置
--with-expat=PATH    //指定Expat的位置或’builtin’
--with-iconv=PATH    //iconv的安装目录
这里只列举了常用的配置选项,如需更多,请自行查找
```

如有问题请留言,如果看到,我会尽快改正:

csdn博客:https://blog.csdn.net/wenhs5479

GitHub:https://github.com/itwhs/zabbix
