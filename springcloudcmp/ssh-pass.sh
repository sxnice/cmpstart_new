#!/bin/bash
cmpuser='cmpimuser'
for i in "$@"
do
 echo =======$i=======
 ssh $i <<EOF
 groupadd $cmpuser
 useradd -m -s  /bin/bash -g $cmpuser $cmpuser
 usermod -G $cmpuser $cmpuser
 exit
EOF
done
exit 0
