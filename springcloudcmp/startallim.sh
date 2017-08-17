#!/bin/bash
#set -x
set -eo pipefail
shopt -s nullglob
source ./colorecho


#---------------可修改配置参数------------------
#安装目录
CURRENT_DIR="/springcloudcmp"
#节点IP组，用空格格开
SSH_H="10.143.132.187"
#用户名
cmpuser="cmpimuser"
#-----------------------------------------------
declare -a SSH_HOST=($SSH_H)

#建立对等互信
ssh-interconnect(){
    echo_green "建立对等互信开始..."
	local ssh_init_path=./ssh-init.sh
        $ssh_init_path $SSH_H
	echo_green "建立对等互信完成..."
}

#启动cmp
start_internode(){
		echo_green "启动CMP开始..."
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
		echo "complete"
		done
		echo_green "启动CMP完成..."
}


#关闭cmp
stop_internode(){
		echo_green "关闭CMP开始..."
		
		for i in "${SSH_HOST[@]}"
		do
		echo "关闭节点"$i
		local user=`ssh $i cat /etc/passwd | sed -n /$cmpuser/p |wc -l`
		if [ "$user" -eq 1 ]; then
			local jars=`ssh $i ps -u $cmpuser | grep -v PID | wc -l`
			if [ "$jars" -gt 0 ]; then
				ssh $i <<EOF
				killall -9 -u $cmpuser
				exit
EOF
				echo "complete"
			else
				echo "CMP已关闭"
			fi
		else
			echo_red "尚未创建$cmpuser用户,请手动关闭服务"
			exit
		fi
		done
		echo_green "所有节点CMP关闭完成..."
}


#批量启cmpim服务
ssh-interconnect
start_internode