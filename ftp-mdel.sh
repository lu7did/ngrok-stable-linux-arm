#!/bin/sh
## Delete files from ftp server
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

HOST=$(python getJason.py sitedata.json qsl.net_host)
USER=$(python getJason.py sitedata.json qsl.net_user)
PWD=$(python getJason.py sitedata.json qsl.net_pswd)

#*--- delete archives
YM=$(date +'%Y%m')
YM=$(( $YM-3 ))
echo YearMonth $YM
ftp -p -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PWD
prompt
cd /tucSPA/images
ls
mdel prefix${YM}*.zip
mdel *.jpg
mdel *.mp4
ls

cd $CURR
exit 0
