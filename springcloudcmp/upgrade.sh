#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho

nodetyper=1
nodeplanr=1
nodenor=1
eurekaipr=localhost
dcnamer=DC1
JDK_DIR="/usr/java/jdk1.8.0_131"


#---------------可修改配置参数------------------
#安装目录
CURRENT_DIR="/springcloudcmp"
#用户名，密码
cmpuser="cmpimuser"
cmppass="Pbu4@123"
#节点IP组，用空格格开
SSH_H="10.143.132.187"
#MYSQLIP
MYSQL_H="10.143.132.187"
#MYSQL相关密码
MYSQL_ROOT_PASSWORD="Pbu4@123"
MYSQL_EVUSER_PASSWORD="Pbu4@123"
MYSQL_IM_PASSWORD="Pbu4@123"
#-----------------------------------------------
declare -a SSH_HOST=($SSH_H)

#检测操作系统
check_ostype(){
	local ostype=`ssh $1 head -n 1 /etc/issue | awk '{print $1}'`
	if [ "$ostype" == "Ubuntu" ]; then
		local version=`ssh $1 head -n 1 /etc/issue | awk  '{print $2}'| awk -F . '{print $1}'`
		echo ubuntu_$version
	else
		local centos=`ssh $1 rpm -qa | grep sed | awk -F . '{print $4}'`
		if [ "$centos" == "el6" ]; then
			echo centos_6
		elif [ "$centos" == "el7" ]; then
			echo centos_7
		fi
	fi
}
#检测安装软件
install-interpackage(){
	echo_green "环境检测开始..."
	for i in "${SSH_HOST[@]}"
            do
		echo "安装依赖包到"$i
		local ostype=`check_ostype $i`
		local os=`echo $ostype | awk -F _ '{print $1}'`
		if [ "$os" == "centos" ]; then
        		local iptables=`ssh  "$i" rpm -qa |grep iptables |wc -l`
       			 if [ "$iptables" -gt 0 ]; then
                		echo "iptables 已安装"
        		else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_iptables/* "$i":/root/
                         		 ssh $i rpm -Uvh ~/iptables-1.4.7-16.el6.x86_64.rpm
               			 elif [ "${ostype}" == "centos_7" ]; then
                        		 scp ../packages/centos7_iptables/* "$i":/root/
                        		 ssh $i rpm -Uvh ~/iptables-1.4.21-17.el7.x86_64.rpm ~/libnetfilter_conntrack-1.0.6-1.el7_3.x86_64.rpm ~/libmnl-1.0.3-7.el7.x86_64.rpm ~/libnfnetlink-1.0.1-4.el7.x86_64.rpm ~/iptables-services-1.4.21-17.el7.x86_64.rpm
               			 fi
        		fi
	        	local lsof=`ssh  "$i" rpm -qa |grep lsof |wc -l`
                	 if [ "$lsof" -gt 0 ]; then
                        	echo "lsof 已安装"
               		 else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_lsof/* "$i":/root/
                         		 ssh $i rpm -Uvh ~/lsof-4.82-5.el6.x86_64.rpm
               			 elif [ "${ostype}" == "centos_7" ]; then
                        		 scp ../packages/centos7_lsof/* "$i":/root/
                         		 ssh $i rpm -Uvh ~/lsof-4.87-4.el7.x86_64.rpm
               			 fi
               		 fi
		elif [ "$os" == "ubuntu" ]; then
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype"暂不提供安装
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
                                ssh $i dpkg -i ~/lsof_4.86+dfsg-1ubuntu2_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype"暂不提供安装                                
                                exit
			else
				echo_red "$ostype"暂不提供安装
                                exit
			fi
		fi
                echo "安装jdk1.8到节点"$i
		ssh "$i" mkdir -p "$JDK_DIR"
			
		scp -r ../packages/jdk1.8.0_131/* "$i":"$JDK_DIR"
		scp ../packages/jce/* "$i":"$JDK_DIR"/jre/lib/security/
		ssh $i  <<EOF
			chmod 755 "$JDK_DIR"/bin/*
		    sed -i /JAVA_HOME/d /etc/profile
		    echo JAVA_HOME="$JDK_DIR" >> /etc/profile
		    echo PATH='\$JAVA_HOME'/bin:'\$PATH' >> /etc/profile
		    echo CLASSPATH='\$JAVA_HOME'/jre/lib/ext:'\$JAVA_HOME'/lib/tools.jar >> /etc/profile
  	            echo export PATH JAVA_HOME CLASSPATH >> /etc/profile
	            source /etc/profile
		    exit
		
EOF
                echo "系统配置节点"$i
                ssh "$i" <<EOF
                    sed -i /$cmpuser/d /etc/security/limits.conf
                    echo $cmpuser soft nproc unlimited >>/etc/security/limits.conf
                    echo $cmpuser hard nproc unlimited >>/etc/security/limits.conf
                    sed -i /limits/d /etc/security/limits.conf
                    echo session required pam_limits.so >>/etc/pam.d/login
                    exit
EOF
		echo "complete..." 
	done
	echo_green "检测安装环境完成..."
}

#建立对等互信
ssh-interconnect(){
    echo_green "建立对等互信开始..."
	local ssh_init_path=./ssh-init.sh
        $ssh_init_path $SSH_H
	echo_green "建立对等互信完成..."
}

#创建普通用户cmpimuser
user-internode(){
	echo_green "建立普通用户cmpimuser开始..."
	local ssh_pass_path=./ssh-pass.sh
        $ssh_pass_path $SSH_H
	for i in "${SSH_HOST[@]}"
        do
        	ssh $i <<EOF
        	echo "$cmpuser:$cmppass" | chpasswd
EOF
        done
	echo_green "建立普通用户cmpimuser完成..."
        
}

#复制文件到各节点
copy-internode(){
     echo_green "复制文件到各节点开始..."
     
     case $nodeplanr in
	  [1-4]) #部署
	    for i in "${SSH_HOST[@]}"
		do
		echo "复制文件到"$i 
		#放根目录下
		scp -r ./ "$i":$CURRENT_DIR
		#赋权
		ssh $i <<EOF
		rm -rf /tmp/*
		chown -R $cmpuser.$cmpuser $CURRENT_DIR
		chmod 740 "$CURRENT_DIR"
 	        chmod 740 "$CURRENT_DIR"/*.sh
		chmod 740 "$CURRENT_DIR"/background
		chmod 640 "$CURRENT_DIR"/background/*.jar
		chmod 740 "$CURRENT_DIR"/config
		chmod 740 "$CURRENT_DIR"/im
		chmod 640 "$CURRENT_DIR"/im/*.jar
		chmod 740 "$CURRENT_DIR"/background/*.sh
		chmod 740 "$CURRENT_DIR"/im/*.sh
		chmod 640 "$CURRENT_DIR"/im/*.war
		chmod 600 "$CURRENT_DIR"/my.cnf
                chmod 600 "$CURRENT_DIR"/colorecho
		chmod 600 "$CURRENT_DIR"/config/*.yml
		su $cmpuser
		umask 077
	#	rm -rf "$CURRENT_DIR"/data
		mkdir  "$CURRENT_DIR"/data
	#	rm -rf "$CURRENT_DIR"/activemq-data
		mkdir  "$CURRENT_DIR"/activemq-data
		rm -rf "$CURRENT_DIR"/logs
		mkdir  "$CURRENT_DIR"/logs
		rm -rf "$CURRENT_DIR"/temp
                mkdir  "$CURRENT_DIR"/temp
		exit
EOF
        echo_green "complete"
		done
	    ;;
	  0) 
	    echo "nothing to do...."
	    ;;
	 esac
	echo_green "复制文件到各节点完成..."
}

#配置各节点环境变量
env_internode(){
        
		echo_green "配置各节点环境变量开始..."
		for j in "${SSH_HOST[@]}"
			do
			echo "配置节点"$j
			ssh $j <<EOF			
			source /etc/environment
			su - $cmpuser
			
			sed -i /nodeplan/d ~/.bashrc
         		sed -i /nodetype/d ~/.bashrc
           	 	sed -i /nodeno/d ~/.bashrc
            		sed -i /eurekaip/d ~/.bashrc
            		sed -i /dcname/d ~/.bashrc
			
			echo "umask 077" >> ~/.bashrc
			echo "CURRENT_DIR=$CURRENT_DIR" >> ~/.bashrc
			sed -n /nodeplan/p /etc/environment>>~/.bashrc 
			echo "export nodeplan">>~/.bashrc
			sed -n /nodetype/p /etc/environment>>~/.bashrc
			echo "export nodetype">>~/.bashrc
			sed -n /nodeno/p /etc/environment>>~/.bashrc
			echo "export nodeno">>~/.bashrc
			sed -n /eurekaip/p /etc/environment>>~/.bashrc
			echo "export eurekaip">>~/.bashrc
			sed -n /dcname/p /etc/environment>>~/.bashrc 
			echo "export dcname">>~/.bashrc
			source ~/.bashrc
			exit
EOF
		
		echo "complete..." 
		done
		echo_green "配置各节点环境变量结束..."
	
}

#配置iptables
iptable_internode(){
        echo_green "配置各节点iptables开始..."
        local iptable_path=./iptablescmp.sh
        $iptable_path $SSH_H
		echo_green "配置各节点iptables结束..."
}

#启动cmp
start_internode(){
		echo_green "启动CMP开始..."
		#启动主控节点1或集中式启动串行启动！
		local k=0
		for i in "${SSH_HOST[@]}"
		do
			echo "启动节点"$i
			ssh $i <<EOF
			su - $cmpuser
			umask 077
			cd "$CURRENT_DIR"
			./startIM.sh
			exit
EOF
			echo "节点"$i"启动完成"
			break
		done
		
		#启动其他节点!
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" $eq 0 ];then
			let k=k+1
			continue
		fi
		echo "启动节点"$i
		 ssh $i <<EOF
		 su - $cmpuser
		 umask 077
		 cd "$CURRENT_DIR"
		 ./startIM_BX.sh
		 exit
EOF
		let k=k+1
		echo "发启启动指令成功"
		done
		
		#检测其他节点服务是否成功!
		k=0
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" $eq 0 ];then
			let k=k+1
			continue
		fi
		echo "启动节点"$i
		 ssh $i <<EOF
		 su - $cmpuser
		 umask 077
		 cd "$CURRENT_DIR"
		 ./imstart_chk.sh
		 exit
EOF
		let k=k+1
		echo "节点启动成功"
		done
		echo_green "启动CMP完成..."
}

#安装单机版mysql5.7
ssh-mysqlconnect(){
    echo_green "建立对等互信开始..."
        local ssh_init_path=./ssh-init.sh
        $ssh_init_path $MYSQL_H
        echo_green "建立对等互信完成..."
        sleep 1
}

mysql_install(){
	# echo_yellow "仅限于初始于安装！！"
	echo_green "安装单机版mysql5.7.19开始"
	local ostype=`check_ostype $MYSQL_H`
	local os=`echo $ostype | awk -F _ '{print $1}'`
        if [ "$os" == "centos" ]; then
		local result=`ssh $MYSQL_H ps -ef | grep mysql | wc -l`
		if [ "$result" -gt 1 ]; then
			local mysql_v=`ssh $MYSQL_H mysql --version | sed -n '/5.7/p' | wc -l`
			if [ "$mysql_v" -eq 1 ]; then
				echo "mysql 5.7已安装"
				exit
			else
				echo "请删除低版本备份好数据后，再执行最新版本的mysql安装"
				exit
			fi
		fi
		echo_yellow "安装依赖包"
		local libaio=`ssh  "$MYSQL_H" rpm -qa |grep libaio |wc -l`
		if [ "$libaio" -eq 1 ]; then
			echo "libaio 已安装"
		else
			if [ "$ostype" == "centos_6" ]; then
				 scp  ../packages/centos6_libaio/* "$MYSQL_H":/root/
               			 ssh $MYSQL_H rpm -Uvh ~/libaio-0.3.107-10.el6.x86_64.rpm
			elif [ "$ostype" == "centos_7" ]; then
		        	 scp ../packages/centos7_libaio/* "$MYSQL_H":/root/
                	 	 ssh $MYSQL_H rpm -Uvh ~/libaio-0.3.109-13.el7.x86_64.rpm
			fi
		fi
		local numactl=`ssh "$MYSQL_H" rpm -qa |grep numactl |wc -l`
		if [ "$numactl" -gt 0 ]; then
                	echo "numactl 已安装"
        	else
                	if [ "$ostype" == "centos_6" ]; then
               			scp ../packages/centos6_numactl/* "$MYSQL_H":/root/
             		       	ssh $MYSQL_H rpm -Uvh ~/numactl-2.0.9-2.el6.x86_64.rpm
               		 elif [ "$ostype" == "centos_7" ]; then
				 scp ../packages/centos7_numactl/* "$MYSQL_H":/root/
               			 ssh $MYSQL_H rpm -Uvh ~/numactl-2.0.9-6.el7_2.x86_64.rpm ~/numactl-libs-2.0.9-6.el7_2.x86_64.rpm
               		 fi
        	fi
		local openssl=`ssh "$MYSQL_H" rpm -qa |grep openssl |wc -l`
		if [ "$openssl" -gt 0 ]; then
                	echo "openssl 已安装"
        	else
			if [ "$ostype" == "centos_6" ]; then
         	        	scp ../packages/centos6_openssl/* "$MYSQL_H":/root/
                		ssh $MYSQL_H rpm -Uvh ~/openssl-1.0.1e-57.el6.x86_64.rpm            
			elif [ "$ostype" == "centos_7" ]; then
    		        	scp ../packages/centos7_openssl/* "$MYSQL_H":/root/
                		ssh $MYSQL_H rpm -Uvh ~/make-3.82-23.el7.x86_64.rpm  ~/openssl-1.0.1e-60.el7_3.1.x86_64.rpm  ~/openssl-libs-1.0.1e-60.el7_3.1.x86_64.rpm
                	fi
        	fi
        	local iptables=`ssh  "$MYSQL_H" rpm -qa |grep iptables |wc -l`
        	if [ "$iptables" -gt 0 ]; then
                	echo "iptables 已安装"
        	else
                	if [ "$ostype" == "centos_6" ]; then
                        	 scp  ../packages/centos6_iptables/* "$MYSQL_H":/root/
                        	 ssh $MYSQL_H rpm -Uvh ~/iptables-1.4.7-16.el6.x86_64.rpm
                	elif [ "$ostype" == "centos_7" ]; then
                        	 scp ../packages/centos7_iptables/* "$MYSQL_H":/root/
     				 ssh $MYSQL_H rpm -Uvh ~/iptables-1.4.21-17.el7.x86_64.rpm ~/libnetfilter_conntrack-1.0.6-1.el7_3.x86_64.rpm ~/libmnl-1.0.3-7.el7.x86_64.rpm ~/libnfnetlink-1.0.1-4.el7.x86_64.rpm
                	fi
        	fi
	elif [ "$os" == "ubuntu" ]; then
                        if [ "$ostype" == "ubuntu_12" ]; then
                                echo_red "$ostype"暂不提供安装
                                exit
                        elif [ "$ostype" == "ubuntu_14" ]; then
                                scp  ../packages/ubuntu14/* "$MYSQL_H":/root/
           			ssh $MYSQL_H dpkg -i ~/libaio1_0.3.109-4_amd64.deb  ~/libnuma1_2.0.9~rc5-1ubuntu3.14.04.2_amd64.deb  ~/openssl_1.0.1f-1ubuntu2.22_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb
                        elif [ "$ostype" == "ubuntu_16" ]; then
                                echo_red "$ostype"暂不提供安装
                                exit
                        else
                                echo_red "$ostype"暂不提供安装
                                exit
                        fi
        fi
		echo_green "复制文件"
	scp -r ../packages/mysql-5.7.19 "$MYSQL_H":/usr/local
	ssh $MYSQL_H <<EOF
		echo "创建mysql用户"
		mv /usr/local/mysql-5.7.19 /usr/local/mysql
		groupadd mysql
		useradd -r -g mysql -s /bin/false mysql
		echo "修改文件权限"
		chown -R mysql.mysql /usr/local/mysql
		chmod 744 /usr/local/mysql/bin/*
		cp /usr/local/mysql/support-files/my-default.cnf /etc/my.cnf
		cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
		chmod 744 /etc/init.d/mysql
		echo "初始化MYSQL"
		cd /usr/local/mysql/bin
		./mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
		echo "给数据库加密"
		./mysql_ssl_rsa_setup --user=mysql --datadir=/usr/local/mysql/data
		chmod 644 /usr/local/mysql/data/server-key.pem
		echo "第一次启动MYSQL"
		/etc/init.d/mysql restart
		#./mysqld_safe --user=mysql &
		echo "配置开机启动"
		chkconfig --add mysql
		echo "配置环境变量"
		sed -i /mysql/d /etc/profile
		echo export PATH=/usr/local/mysql/bin:'\$PATH' >>/etc/profile
		source /etc/profile
		exit
EOF
		scp ./init_mysql.sh "$MYSQL_H":/root/
		#分别为ROOT密码，EVUSER密码，IM密码。
		MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD")
		ssh $MYSQL_H /root/init_mysql.sh "${MYSQL_PASS[@]}"
		 
		
	
	echo_green "安装完成"
}
#mysql服务器iptables配置
iptables-mysql(){
  	echo_green "配置iptables开始..."
        local iptable_path=./iptablesmysql.sh
        $iptable_path $MYSQL_H
	echo_green "配置iptables完成..."
}

echo_yellow "-----------一键安装（增量）说明-------------------"
echo_yellow "1、可安装JDK1.8.0_131软件;"
#echo_yellow "2、可安装MYSQL5.7.19软件;"
echo_yellow "2、可安装有iptables lsof软件;"
echo_yellow "3、初始化时，建议使用root用户安装;"
echo_yellow "4、确保.sh有执行权限，并且使用 ./xxx.sh执行;"
echo_yellow "5、可配置数据库连接,并更新jce;"
echo_yellow "-------------------------------------------"
echo_green "控制节点节点方案，请输入编号：" 
sleep 3
clear
echo "1-----allinone服务器,每台32G内存." 
echo "2-----3台服务器,每台16G内存.2台控制节点，1台采集节点"  
echo "3-----4台服务器,每台16G内存.3台控制节点，1台采集节点"  
echo "4-----6台服务器,每台8G内存.5台控制节点，1台采集节点"
#echo "5-----安装单机版mysql5.7"

while read item
do
  case $item in
    [1])
        nodeplanr=1
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_internode
		iptable_internode
		start_internode
        break
        ;;
    [2])
        nodeplanr=2
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_internode
		iptable_internode
		start_internode
        break
        ;;
    [3])
        nodeplanr=3
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_internode
		iptable_internode
		start_internode
        break
        ;;
    [4])
        nodeplanr=4
		ssh-interconnect
		user-internode
		install-interpackage
		copy-internode
		env_internode
		iptable_internode
		start_internode
        break
        ;;
     0)
        echo "退出"
        exit 0
        ;;
     *)
        echo_red "输入有误，请重新输入！"
        ;;
  esac
done