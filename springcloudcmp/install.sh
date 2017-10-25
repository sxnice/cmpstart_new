#!/bin/bash
#set -x
#set -eo pipefail
shopt -s nullglob
source ./colorecho

nodetyper=1
nodeplanr=1
nodenor=1
eurekaipr=localhost
dcnamer="DC1"
JDK_DIR="/usr/java"
MYSQL_DIR="/usr/local/mysql"


#---------------可修改配置参数------------------
#安装目录
CURRENT_DIR="/springcloudcmp"
#用户名，密码
cmpuser="cmpimuser"
cmppass="Pbu4@123"
#节点IP组，用空格格开
SSH_H="192.168.3.97"
#MYSQLIP 单机
MYSQL_H="10.143.132.187"
#MYSQL相关密码
MYSQL_ROOT_PASSWORD="Pbu4@123"
MYSQL_EVUSER_PASSWORD="Pbu4@123"
MYSQL_IM_PASSWORD="Pbu4@123"
#-----------------------------------------------
declare -a SSH_HOST=($SSH_H)

#检测操作系统
check_ostype(){
	local ostype=`ssh -n $1 head -n 1 /etc/issue | awk '{print $1}'`
	if [ "$ostype" == "Ubuntu" ]; then
		local version=`ssh -n $1 head -n 1 /etc/issue | awk  '{print $2}'| awk -F . '{print $1}'`
		echo ubuntu_$version
	else
		local centos=`ssh -n $1 rpm -qa | grep sed | awk -F . '{print $4}'`
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
        		local iptables=`ssh -n "$i" rpm -qa |grep iptables |wc -l`
       			 if [ "$iptables" -gt 0 ]; then
                		echo "iptables 已安装"
        		else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_iptables/* "$i":/root/
                         		 ssh -n $i rpm -Uvh ~/iptables-1.4.7-16.el6.x86_64.rpm
               			 elif [ "${ostype}" == "centos_7" ]; then
                        		 scp ../packages/centos7_iptables/* "$i":/root/
                        		 ssh -n $i rpm -Uvh ~/iptables-1.4.21-17.el7.x86_64.rpm ~/libnetfilter_conntrack-1.0.6-1.el7_3.x86_64.rpm ~/libmnl-1.0.3-7.el7.x86_64.rpm ~/libnfnetlink-1.0.1-4.el7.x86_64.rpm ~/iptables-services-1.4.21-17.el7.x86_64.rpm
               			 fi
        		fi
	        	local lsof=`ssh -n "$i" rpm -qa |grep lsof |wc -l`
                	 if [ "$lsof" -gt 0 ]; then
                        	echo "lsof 已安装"
               		 else
                		if [ "${ostype}" == "centos_6" ]; then
                        		 scp  ../packages/centos6_lsof/* "$i":/root/
                         		 ssh -n $i rpm -Uvh ~/lsof-4.82-5.el6.x86_64.rpm
               			 elif [ "${ostype}" == "centos_7" ]; then
                        		 scp ../packages/centos7_lsof/* "$i":/root/
                         		 ssh -n $i rpm -Uvh ~/lsof-4.87-4.el7.x86_64.rpm
               			 fi
               		 fi
			 local psmisc=`ssh -n "$i" rpm -qa |grep psmisc |wc -l`
                         if [ "$psmisc" -gt 0 ]; then
                                echo "psmisc 已安装"
                         else
                                if [ "${ostype}" == "centos_6" ]; then
                                         scp  ../packages/centos6_psmisc/* "$i":/root/
                                         ssh -n $i rpm -Uvh ~/psmisc-22.6-24.el6.x86_64.rpm
                                 elif [ "${ostype}" == "centos_7" ]; then
                                         scp ../packages/centos7_psmisc/* "$i":/root/
                                         ssh -n $i rpm -Uvh ~/psmisc-22.20-11.el7.x86_64.rpm
                                 fi
                         fi
		elif [ "$os" == "ubuntu" ]; then
			if [ "$ostype" == "ubuntu_12" ]; then
				echo_red "$ostype"暂不提供安装
				exit
			elif [ "$ostype" == "ubuntu_14" ]; then
				scp  ../packages/ubuntu14/* "$i":/root/
                                ssh -n $i dpkg -i ~/lsof_4.86+dfsg-1ubuntu2_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb ~/psmisc_22.20-1ubuntu2_amd64.deb
			elif [ "$ostype" == "ubuntu_16" ]; then
				echo_red "$ostype"暂不提供安装                                
                                exit
			else
				echo_red "$ostype"暂不提供安装
                                exit
			fi
		fi
                echo "安装jdk1.8到节点"$i
		ssh -n "$i" mkdir -p "$JDK_DIR"
		scp -r ../packages/jdk/* "$i":"$JDK_DIR"
		scp ../packages/jce/* "$i":"$JDK_DIR"/jre/lib/security/
		ssh $i  <<EOF
		    chmod 755 "$JDK_DIR"/bin/*
		    sed -i /JAVA_HOME/d /etc/profile
		    echo JAVA_HOME="$JDK_DIR" >> /etc/profile
		    echo PATH='\$JAVA_HOME'/bin:'\$PATH' >> /etc/profile
		    echo CLASSPATH='\$JAVA_HOME'/jre/lib/ext:'\$JAVA_HOME'/lib/tools.jar >> /etc/profile
  	            echo export JAVA_HOME CLASSPATH PATH >> /etc/profile
	            source /etc/profile
		    su - $cmpuser
                    sed -i /JAVA_HOME/d ~/.bashrc
                    echo JAVA_HOME="$JDK_DIR" >> ~/.bashrc
                    echo PATH='\$JAVA_HOME'/bin:'\$PATH' >> ~/.bashrc
                    echo CLASSPATH='\$JAVA_HOME'/jre/lib/ext:'\$JAVA_HOME'/lib/tools.jar >> ~/.bashrc
                    echo export JAVA_HOME CLASSPATH PATH>> ~/.bashrc
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
	echo_green "建立普通用户开始..."
	for i in "${SSH_HOST[@]}"
	do
	echo =======$i=======
	ssh $i <<EOF
	groupadd $cmpuser
 	useradd -m -s  /bin/bash -g $cmpuser $cmpuser
 	usermod -G $cmpuser $cmpuser
	echo "$cmpuser:$cmppass" | chpasswd
EOF
	done
	echo_green "建立普通用户完成..."
        
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
                        ssh -n $i mkdir -p $CURRENT_DIR
                        scp -r ./background ./im ./config startIM.sh startIM_BX.sh stopIM.sh imstart_chk.sh "$i":$CURRENT_DIR
                        #赋权
                        ssh $i <<EOF
                        rm -rf /tmp/spring.log
                        rm -rf /tmp/modelTypeName.data
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
                        chmod 600 "$CURRENT_DIR"/config/*.yml
                        su $cmpuser
                        umask 077
        #               rm -rf "$CURRENT_DIR"/data
                        mkdir  "$CURRENT_DIR"/data
        #               rm -rf "$CURRENT_DIR"/activemq-data
                        mkdir  "$CURRENT_DIR"/activemq-data
                        rm -rf "$CURRENT_DIR"/logs
                        mkdir  "$CURRENT_DIR"/logs
                        rm -rf "$CURRENT_DIR"/temp
                        mkdir  "$CURRENT_DIR"/temp
                        exit
EOF
                echo "complete..."
            done
            ;;
          0)
            echo "nothing to do...."
            ;;
         esac
}

#配置各节点环境变量
env_internode(){
        
		echo_green "配置各节点环境变量开始..."
		for j in "${SSH_HOST[@]}"
			do
			echo "配置节点"$j
			
			if [ $nodeplanr -ne 1 ]; then
			echo "节点类型，请输入编号："  
			echo "1-----控制节点."  
			echo "2-----采集节点."    
			echo "3-----控制以及采集节点."    
			read nodetyper 
			
			if [ $nodetyper -eq 1 ]; then
			echo "当前控制节点编号请按照1,2,3等顺序编写："  
			read nodenor
			fi
			
			echo "1号控制节点IP："  
			read eurekaipr 
			fi
			
			if [ $nodetyper -eq 2 ] || [ $nodetyper -eq 3 ]; then
			read -t 5 -p "请输入采集节点名称，如DC1:" dcnamer
                        dcnamer=${dcnamer:-"DC1"}
			fi
			

			
			
			echo "设置nodeplan="$nodeplanr
			echo "设置nodetype="$nodetyper
			echo "设置nodeno="$nodenor	
			echo "设置eurekaip="$eurekaipr
			echo "设置dcname="$dcnamer

			echo "节点："$j
			
			ssh $j <<EOF
                        sed -i /nodeplan/d /etc/environment
			sed -i /nodetype/d /etc/environment
			sed -i /nodeno/d /etc/environment
			sed -i /eurekaip/d /etc/environment
			sed -i /eurekaiprep/d /etc/environment
			sed -i /dcname/d /etc/environment
			sed -i /CMP_DIR/d /etc/environment
			
			echo "nodeplan=$nodeplanr export nodeplan">>/etc/environment
			echo "nodetype=$nodetyper export nodetype">>/etc/environment
			echo "nodeno=$nodenor export nodeno">>/etc/environment 
			echo "eurekaip=$eurekaipr export eurekaip">>/etc/environment
			echo "eurekaiprep=$eurekaipr export eurekaiprep">>/etc/environment
			echo "dcname=$dcnamer export dcname">>/etc/environment 
			echo "CMP_DIR=$CURRENT_DIR export CMP_DIR" >>/etc/environment	
			source /etc/environment

			su - $cmpuser
			sed -i /nodeplan/d ~/.bashrc
                        sed -i /nodetype/d ~/.bashrc
                        sed -i /nodeno/d ~/.bashrc
                        sed -i /eurekaip/d ~/.bashrc
			sed -i /eurekaiprep/d ~/.bashrc
                        sed -i /dcname/d ~/.bashrc
			sed -i /CMP_DIR/d  ~/.bashrc
			
			echo "umask 077" >> ~/.bashrc
			echo "CMP_DIR=$CURRENT_DIR export CMP_DIR" >> ~/.bashrc
			echo "nodeplan=$nodeplanr export nodeplan">>~/.bashrc
                        echo "nodetype=$nodetyper export nodetype">>~/.bashrc
                        echo "nodeno=$nodenor export nodeno">>~/.bashrc 
                        echo "eurekaip=$eurekaipr export eurekaip">>~/.bashrc
			echo "eurekaiprep=$eurekaipr export eurekaiprep">>~/.bashrc
                        echo "dcname=$dcnamer export dcname">>~/.bashrc 
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

#启动im
start_internode(){
		echo_green "启动IM开始..."
		#启动主控节点1或集中式启动串行启动！
		local k=0
		for i in "${SSH_HOST[@]}"
		do
			echo "启动节点"$i
			ssh -n $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM.sh'
			echo "节点"$i"启动完成"
			break
		done
		
		#启动其他节点!
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "启动节点"$i
		ssh -nf $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM_BX.sh > /dev/null'
		let k=k+1
		echo "发启启动指令成功"
		done
		
		#检测其他节点服务是否成功!
		k=0
		for i in "${SSH_HOST[@]}"
		do
		if [ "$k" -eq 0 ];then
			let k=k+1
			continue
		fi
		echo "检测节点"$i
		 ssh $i <<EOF
		 su - $cmpuser
		 source /etc/environment
		 umask 077
		 cd "$CURRENT_DIR"
		 ./imstart_chk.sh
		 exit
EOF
		let k=k+1
		echo "节点检测成功"
		done
		echo_green "启动IM完成..."
}

#关闭im
stop_internode(){
		echo_green "关闭IM开始..."
		
		for i in "${SSH_HOST[@]}"
		do
		echo "关闭节点"$i
		local user=`ssh -n $i cat /etc/passwd | awk -F : '{print \$1}' | grep -w $cmpuser |wc -l`
                if [ "$user" -eq 1 ]; then
			local jars=`ssh -n $i ps -u $cmpuser | grep -v PID | wc -l`
			if [ "$jars" -gt 0 ]; then
				ssh $i <<EOF
				killall -9 -u $cmpuser
				exit
EOF
				echo "complete"
			else
				echo "IM已关闭"
			fi
		else
			echo_red "尚未创建$cmpuser用户,请手动关闭服务"
			exit
		fi
		done
		echo_green "所有节点IM关闭完成..."
}

#清空安装
uninstall_internode(){
		echo_green "清空安装开始..."
		for i in "${SSH_HOST[@]}"
		do
		echo "删除节点"$i
		ssh $i <<EOF
		rm -rf "$CURRENT_DIR"
		rm -rf /home/cmpimuser/
		rm -rf /usr/java/
		rm -rf /tmp/*
		userdel cmpimuser
		iptables -P INPUT ACCEPT
		iptables -D INPUT -j cmp
		iptables -F cmp
		iptables -X cmp
		iptables-save > /etc/iptables
		iptables-save > /etc/sysconfig/iptables
		exit
EOF
		echo "complete"
		done
		echo_green "清空安装完成..."
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
	echo_green "安装单机版mysql5.7开始"
	local ostype=`check_ostype $MYSQL_H`
	local os=`echo $ostype | awk -F _ '{print $1}'`
        if [ "$os" == "centos" ]; then
		local result=`ssh -n $MYSQL_H ps -ef | grep mysql | wc -l`
		if [ "$result" -gt 1 ]; then
			local mysql_v=`ssh -n $MYSQL_H mysql --version | sed -n '/5.7/p' | wc -l`
			if [ "$mysql_v" -eq 1 ]; then
				echo_yellow "mysql 5.7已安装"
				exit
			else
				echo_red "请删除低版本备份好数据后，再执行最新版本的mysql安装"
				exit
			fi
		fi
		echo_yellow "安装依赖包"
		local libaio=`ssh -n "$MYSQL_H" rpm -qa |grep libaio |wc -l`
		if [ "$libaio" -eq 1 ]; then
			echo "libaio 已安装"
		else
			if [ "$ostype" == "centos_6" ]; then
				 scp  ../packages/centos6_libaio/* "$MYSQL_H":/root/
               			 ssh -n $MYSQL_H rpm -Uvh ~/libaio-0.3.107-10.el6.x86_64.rpm
			elif [ "$ostype" == "centos_7" ]; then
		        	 scp ../packages/centos7_libaio/* "$MYSQL_H":/root/
                	 	 ssh -n $MYSQL_H rpm -Uvh ~/libaio-0.3.109-13.el7.x86_64.rpm
			fi
		fi
		local numactl=`ssh -n "$MYSQL_H" rpm -qa |grep numactl |wc -l`
		if [ "$numactl" -gt 0 ]; then
                	echo "numactl 已安装"
        	else
                	if [ "$ostype" == "centos_6" ]; then
               			scp ../packages/centos6_numactl/* "$MYSQL_H":/root/
             		       	ssh -n $MYSQL_H rpm -Uvh ~/numactl-2.0.9-2.el6.x86_64.rpm
               		elif [ "$ostype" == "centos_7" ]; then
				scp ../packages/centos7_numactl/* "$MYSQL_H":/root/
               			ssh -n $MYSQL_H rpm -Uvh ~/numactl-2.0.9-6.el7_2.x86_64.rpm ~/numactl-libs-2.0.9-6.el7_2.x86_64.rpm
               		fi
        	fi
		local openssl=`ssh -n "$MYSQL_H" rpm -qa |grep openssl |wc -l`
		if [ "$openssl" -gt 0 ]; then
                	echo "openssl 已安装"
        	else
			if [ "$ostype" == "centos_6" ]; then
         	        	scp ../packages/centos6_openssl/* "$MYSQL_H":/root/
                		ssh -n $MYSQL_H rpm -Uvh ~/openssl-1.0.1e-57.el6.x86_64.rpm            
			elif [ "$ostype" == "centos_7" ]; then
    		        	scp ../packages/centos7_openssl/* "$MYSQL_H":/root/
                		ssh -n $MYSQL_H rpm -Uvh ~/make-3.82-23.el7.x86_64.rpm  ~/openssl-1.0.1e-60.el7_3.1.x86_64.rpm  ~/openssl-libs-1.0.1e-60.el7_3.1.x86_64.rpm
                	fi
        	fi
        	local iptables=`ssh -n "$MYSQL_H" rpm -qa |grep iptables |wc -l`
        	if [ "$iptables" -gt 0 ]; then
                	echo "iptables 已安装"
        	else
                	if [ "$ostype" == "centos_6" ]; then
                        	 scp  ../packages/centos6_iptables/* "$MYSQL_H":/root/
                        	 ssh -n $MYSQL_H rpm -Uvh ~/iptables-1.4.7-16.el6.x86_64.rpm
                	elif [ "$ostype" == "centos_7" ]; then
                        	 scp ../packages/centos7_iptables/* "$MYSQL_H":/root/
     				 ssh -n $MYSQL_H rpm -Uvh ~/iptables-1.4.21-17.el7.x86_64.rpm ~/libnetfilter_conntrack-1.0.6-1.el7_3.x86_64.rpm ~/libmnl-1.0.3-7.el7.x86_64.rpm ~/libnfnetlink-1.0.1-4.el7.x86_64.rpm
                	fi
        	fi
	elif [ "$os" == "ubuntu" ]; then
			local result=`ssh -n $MYSQL_H ps -ef | grep mysql | wc -l`
               		if [ "$result" -gt 1 ]; then
                        	 local mysql_v=`ssh -n $MYSQL_H mysql --version | sed -n '/5.7/p' | wc -l`
                       		 if [ "$mysql_v" -eq 1 ]; then
                                	echo_yellow "mysql 5.7已安装"
                                	exit
                       		 else
                                        echo_red "请删除低版本备份好数据后，再执行最新版本的mysql安装"
                                        exit
                                 fi
               		fi
                        if [ "$ostype" == "ubuntu_12" ]; then
                                echo_red "$ostype"暂不提供安装
                                exit
                        elif [ "$ostype" == "ubuntu_14" ]; then
                                scp  ../packages/ubuntu14/* "$MYSQL_H":/root/
           			ssh -n $MYSQL_H dpkg -i ~/libaio1_0.3.109-4_amd64.deb  ~/libnuma1_2.0.9~rc5-1ubuntu3.14.04.2_amd64.deb  ~/openssl_1.0.1f-1ubuntu2.22_amd64.deb ~/iptables_1.4.21-1ubuntu1_amd64.deb ~/libnfnetlink0_1.0.1-2_amd64.deb ~/libxtables10_1.4.21-1ubuntu1_amd64.deb
                        elif [ "$ostype" == "ubuntu_16" ]; then
                                echo_red "$ostype"暂不提供安装
                                exit
                        else
                                echo_red "$ostype"暂不提供安装
                                exit
                        fi
        fi
		echo_green "复制文件"
		ssh -n "$MYSQL_H" mkdir -p "$MYSQL_DIR"
		scp -r ../packages/mysql/* "$MYSQL_H":"$MYSQL_DIR"
		ssh $MYSQL_H <<EOF
		echo "创建mysql用户"
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
		sed -i /mysql/d ~/.bashrc
		echo export PATH=/usr/local/mysql/bin:'\$PATH' >> ~/.bashrc
		source ~/.bashrc
		exit
EOF
		scp ./init_mysql.sh "$MYSQL_H":/root/
		#分别为ROOT密码，EVUSER密码，IM密码。
		MYSQL_PASS=("$MYSQL_ROOT_PASSWORD" "$MYSQL_EVUSER_PASSWORD" "$MYSQL_IM_PASSWORD")
		ssh -n $MYSQL_H /root/init_mysql.sh "${MYSQL_PASS[@]}"
		 
		
	
	echo_green "安装完成"
}

#mysql服务器iptables配置
iptables-mysql(){
  	echo_green "配置iptables开始..."
        local iptable_path=./iptablesmysql.sh
        $iptable_path $MYSQL_H
	echo_green "配置iptables完成..."
}


echo_yellow "-----------一键安装说明-------------------"
echo_yellow "1、安装前，请确认是否安装mysql;"
echo_yellow "2、可安装JDK1.8软件;"
echo_yellow "3、可安装有iptables lsof软件;"
echo_yellow "4、初始化时，建议使用root用户安装;"
echo_yellow "5、确保.sh有执行权限，并且使用 ./xxx.sh执行;"
echo_yellow "6、可清空部署环境。"

echo_yellow "-------------------------------------------"
echo_green "单机版（小规模）方案，请输入编号：" 
sleep 3
clear
echo "1-----3台服务器,每台16G内存.2台控制节点，1台采集节点"  
echo "2-----清空部署(数据库不受影响，但升级环境禁止使用)"

while read item
do
  case $item in
    [1])
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
     [2])
		ssh-interconnect
		stop_internode
		uninstall_internode
	break;
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
