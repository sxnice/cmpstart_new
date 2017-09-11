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
                        echo_red "尚未创建$cmpuser用户,请手动关闭服务"
                 #       exit
                fi
                done
                echo_green "所有节点IM关闭完成..."
}


#批量关cmpim服务
ssh-interconnect
stop_internode
