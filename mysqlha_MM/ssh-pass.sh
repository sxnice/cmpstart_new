#!/bin/bash

for i in "$@"
do
 echo =======$i=======
 ssh $i <<EOF
 groupadd cmpimuser
 useradd -m -s  /bin/bash -g cmpimuser cmpimuser
 usermod -G cmpimuser cmpimuser
 exit
EOF
done
exit 0
