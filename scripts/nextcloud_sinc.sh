#! /bin/bash
 
# nextcloudcmd use ~/.netrc to get login and pass
if $(nextcloudcmd --path obsidian ~/obsidian "https://cloud.zenembed.com" &> /dev/null)
then
    echo -en "    "
else
    echo -en "     "
fi
