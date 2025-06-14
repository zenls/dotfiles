#! /bin/bash

# nextcloudcmd use ~/.netrc to get login and pass
if $(nextcloudcmd -n -s --path nextcloud ~/nextcloud "https://cloud.zenembed.com")
then
    echo "󰅠"
else
    echo "󰧠"
fi