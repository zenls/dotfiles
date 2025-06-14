#!/bin/bash
 
sites=(zenembed.com work.zenembed.com cloud.zenembed.com git.zenembed.com)
 
for site in ${sites[@]}
do
    if $(ping -c 1 $site 2>/dev/null | grep -q "1 received, 0% packet loss")
    then
        echo -en " "
    else
        echo -en "  "
    fi
done
echo -en "   "
