source /etc/environment
PRG="$0"
sleeptime=2

while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
PRGDIR=`dirname "$PRG"`
  
CURRENT_DIR=`cd "$PRGDIR" >/dev/null; pwd`

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "1" ]; then
#启动检测-----------------------------start-------------------------------------

echo "check taskengine"
pIDtaskengine=`lsof -i :$porttaskengine|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDtaskengine" = "" ]
  do
  sleep $sleeptime
  pIDtaskengine=`lsof -i :$porttaskengine|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDtaskengine &>/dev/null &
  echo -n "."
done
echo "taskengine start success!"

echo "check activemqserver"
pIDactivemq=`lsof -i :$portactivemq|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDactivemq" = "" ]
  do
  sleep $sleeptime
  pIDactivemq=`lsof -i :$portactivemq|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDactivemq &>/dev/null &
  echo -n "."
done
echo "activemqserver start success!"

echo "check messageserver"
pIDmessage=`lsof -i :$portmessage|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDmessage" = "" ]
  do
  sleep $sleeptime
  pIDmessage=`lsof -i :$portmessage|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDmessage &>/dev/null &
  echo -n "."
done
echo "messageserver start success!"
#启动检测--------------------------------end---------------------------------
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "1" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "2" ]; then
#启动检测-----------------------------start-------------------------------------
echo "check i18nserver"
pIDi18nserver=`lsof -i :$porti18nserver|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDi18nserver" = "" ]
  do
  sleep $sleeptime
  pIDi18nserver=`lsof -i :$porti18nserver|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDi18nserver &>/dev/null &
  echo -n "."
done
echo "i18nserver start success!"

echo "check cmdb"
pIDcmdb=`lsof -i :$portcmdb|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDcmdb" = "" ]
  do
  sleep $sleeptime
  pIDcmdb=`lsof -i :$portcmdb|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDcmdb &>/dev/null &
  echo -n "."
done
echo "cmdb start success!"

echo "check vsphereagent"
pIDvsphereagent=`lsof -i :$portvsphereagent|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDvsphereagent" = "" ]
  do
  sleep $sleeptime
  pIDvsphereagent=`lsof -i :$portvsphereagent|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDvsphereagent &>/dev/null &
  echo -n "."
done
echo "vphereagent start success!"

echo "check vspheremanage"
pIDvspheremanage=`lsof -i :$portvspheremanage|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDvspheremanage" = "" ]
  do
  sleep $sleeptime
  pIDvspheremanage=`lsof -i :$portvspheremanage|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDvspheremanage &>/dev/null &
  echo -n "."
done
echo "vspheremanage start success!"
#启动检测-----------------------------end-------------------------------------
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "3" ]; then
#启动检测-----------------------------start-------------------------------------
echo "check alarmcenter"
pIDalarmcenter=`lsof -i :$portalarmcenter|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDalarmcenter" = "" ]
  do
  sleep $sleeptime
  pIDalarmcenter=`lsof -i :$portalarmcenter|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDalarmcenter &>/dev/null &
  echo -n "."
done
echo "alarmcenter start success!"

echo "check taskjob"
pIDtaskjob=`lsof -i :$porttaskjob|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDtaskjob" = "" ]
  do
  sleep $sleeptime
  pIDtaskjob=`lsof -i :$porttaskjob|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDtaskjob &>/dev/null &
  echo -n "."
done
echo "taskjob start success!"
#启动检测-----------------------------end-------------------------------------
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "4" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "4" ]; then
#启动检测-----------------------------------------------------------
echo "check servicemonitor"
pIDservicemonitor=`lsof -i :$portservicemonitor|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDservicemonitor" = "" ]
  do
  sleep $sleeptime
  pIDservicemonitor=`lsof -i :$portservicemonitor|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDservicemonitor &>/dev/null &
  echo -n "."
done
echo "servicemonitor start success!"

echo "check im-task-start"
pIimtask=`lsof -i :$portimtask|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIimtask" = "" ]
  do
  sleep $sleeptime
  pIimtask=`lsof -i :$portimtask|grep  "LISTEN" | awk '{print $2}'`
  echo $pIimtask &>/dev/null &
  echo -n "."
done
echo "im-task-start success!"

echo "check im-provider-start"
pIimprovider=`lsof -i :$portimprovider|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIimprovider" = "" ]
  do
  sleep $sleeptime
  pIimprovider=`lsof -i :$portimprovider|grep  "LISTEN" | awk '{print $2}'`
  echo $pIimprovider &>/dev/null &
  echo -n "."
done
echo "im-provider-start success!"

echo "check im-3rdinf-start"
pI3rdinf=`lsof -i :$portim3rdinf|grep  "LISTEN" | awk '{print $2}'`
while [ "$pI3rdinf" = "" ]
  do
  sleep $sleeptime
  pI3rdinf=`lsof -i :$portim3rdinf|grep  "LISTEN" | awk '{print $2}'`
  echo $pI3rdinf &>/dev/null &
  echo -n "."
done
echo "im-3rdinf-start success!"
#启动检测-----------------------------end-------------------------------------
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "1" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "1" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "1" -a "$nodeplan" = "4" -a "$nodeno" = "5" ] || [ "$nodetype" = "3" -a "$nodeplan" = "2" -a "$nodeno" = "2" ] || [ "$nodetype" = "3" -a "$nodeplan" = "3" -a "$nodeno" = "3" ] || [ "$nodetype" = "3" -a "$nodeplan" = "4" -a "$nodeno" = "5" ]; then
#启动检测-----------------------------start-------------------------------------
echo "check im-web-start"
pIimweb=`lsof -i :$portimweb|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIimweb" = "" ]
  do
  sleep $sleeptime
  pIimweb=`lsof -i :$portimweb|grep  "LISTEN" | awk '{print $2}'`
  echo $pIimweb &>/dev/null &
  echo -n "."
done
echo "im-web-start success!"

echo "check esee-manager"
pIesee=`lsof -i :$porteseemanager|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIesee" = "" ]
  do
  sleep $sleeptime
  pIesee=`lsof -i :$porteseemanager|grep  "LISTEN" | awk '{print $2}'`
  echo $pIesee &>/dev/null &
  echo -n "."
done
echo "esee-manager success!"

echo "check gmcc-manager"
pIgmcc=`lsof -i :$portgmccmanager|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIgmcc" = "" ]
  do
  sleep $sleeptime
  pIgmcc=`lsof -i :$portgmccmanager|grep  "LISTEN" | awk '{print $2}'`
  echo $pIgmcc &>/dev/null &
  echo -n "."
done
echo "gmcc-manager success!"
#启动检测-----------------------------end---------------------------------------
fi

if [ "$nodeplan" = "1" ] || [ "$nodetype" = "2" ] || [ "$nodetype" = "3" ]; then
#启动检测-----------------------------start-------------------------------------
echo "check gatherframe"
pIDgatherframe=`lsof -i :$portgatherframe|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDgatherframe" = "" ]
  do
  sleep $sleeptime
  pIDgatherframe=`lsof -i :$portgatherframe|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDgatherframe &>/dev/null &
  echo -n "."
done
echo "gatherframe start success!"

echo "check zuulmanager"
pIDzuulmanager=`lsof -i :$portzuulmanager|grep  "LISTEN" | awk '{print $2}'`
while [ "$pIDzuulmanager" = "" ]
  do
  sleep $sleeptime
  pIDzuulmanager=`lsof -i :$portzuulmanager|grep  "LISTEN" | awk '{print $2}'`
  echo $pIDzuulmanager &>/dev/null &
  echo -n "."
done
echo "zuulmanager start success!"

#启动检测-----------------------------end---------------------------------------
fi