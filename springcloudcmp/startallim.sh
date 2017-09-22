#!/bin/bash
#set -x
set -eo pipefail
shopt -s nullglob
source ./colorecho


#---------------可修改配置参数------------------
#安装目录
CURRENT_DIR="/springcloudcmp"
#节点IP组，用空格格开
SSH_H="192.168.3.97"
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
		#启动主控节点1或集中式启动串行启动！
		local k=0
		for i in "${SSH_HOST[@]}"
		do
			echo "启动节点"$i
			ssh -n $i 'su - '$cmpuser' -c '$CURRENT_DIR'/startIM.sh'
		#	ssh $i <<EOF
		#	su - $cmpuser
		#	source /etc/environment
		#	umask 077
		#	cd "$CURRENT_DIR"
		#	./startIM.sh
		#	exit
#EOF
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
	#	 ssh $i <<EOF
	#	 su - $cmpuser
	#	 source /etc/environment
	#	 umask 077
	#	 cd "$CURRENT_DIR"
	#	 ./startIM_BX.sh
	#	 exit
#EOF
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
		echo_green "启动CMP完成..."
}


#关闭im
stop_internode(){
		echo_green "关闭IM开始..."
		
		for i in "${SSH_HOST[@]}"
		do
		echo "关闭节点"$i
		local user=`ssh -n $i cat /etc/passwd | awk -F : '{print \$1}' | grep -w $cmpuser |wc -l`
                if [ "$user" -eq 1 ]; then
			local jars=`ssh $i ps -u $cmpuser | grep -v PID | wc -l`
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
			echo_red "尚未创建$cmpuser用户,请手动关闭进程后，再执行"
			exit
		fi
		done
		echo_green "所有节点IM关闭完成..."
}


#批量启im服务
ssh-interconnect
start_internode
