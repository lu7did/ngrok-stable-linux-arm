#!/bin/sh
#*------------------------------------------------------------------
#* ftp-upload.sh
#* FTP upload
#*------------------------------------------------------------------
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

HOST=$(python getJason.py sitedata.json qsl.net_host)
USERNAME=$(python getJason.py sitedata.json qsl.net_user)
PASSWORD=$(python getJason.py sitedata.json qsl.net_pswd)
DIR=$(python getJason.py sitedata.json qsl.net_dir)

#*--- upload the file
echo "upload  ($1) to $HOST/$DIR using id($USERNAME)"
ftp-upload -h $HOST  -u $USERNAME --password $PASSWORD -d $DIR $1
