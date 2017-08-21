# cmpstart
**********准备工作***************
1、packages放依赖包，jdk1.8(需上传解压后的文件),mysql5.7.19(需上传解压后的文件),jce(需上传jce文件);
2、将springcloudcmp下的my.cnf放至mysql_5.7.19/support-files目录下，并命名为my-default.cnf
3、修改init2.sh的标记为配置参数,init2.sh为初装版，init3.sh为测试版，init5.sh为升级版。
4、如数据库未安装配置，先按5自动安装及配置数据库。
5、支持centos6,centos7,ubuntu14.04的一键安装。

********************************
安装平台流程-----------------------
1、建立ssh互信；
2、检测依赖包及JDK1.8；
2、创建普通用户；
3、复制文件到各节点；
4、配置环境变量；
5、配置权限；
6、配置iptables；
7、启动cmp。
安装数据库流程---------------------
按5一键安装配置数据库。
安装数据库主备准备工作-------------
1、把mysqlha目录下的*.cnf放到mysql_5.7.19/support-files目录下；
2、把mysqlha目录下的mysql.server放到mysql_5.7.19/support-files目录下；
3、修改mysqlha目录下的*.sh的权限为755;
