#!/bin/sh
#*---------------------------------------------------------------------------
#* Upload an .html file
#*---------------------------------------------------------------------------
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

#*---- Get keys

HOST=$(python getJason.py sitedata.json qsl.net_host)
USERNAME=$(python getJason.py sitedata.json qsl.net_user)
PASSWORD=$(python getJason.py sitedata.json qsl.net_pswd)
DIR=$(python getJason.py sitedata.json qsl.net_dir)
SITE=$(python getJason.py sitedata.json site)
FILE="$(pwd)/$SITE/$SITE.html"

#echo "uploading  ($FILE) to $HOST/$DIR using id($USERNAME)" 
#ftp-upload -h $HOST  -u $USERNAME --password $PASSWORD -d $DIR $FILE 

echo "uploading  (./$SITE/$SITE) site($SITE) to $HOST/$SITE using id($USERNAME) password($PASSWORD)" 
#ftp-upload -h $HOST  -u $USERNAME --password $PASSWORD -d $DIR $FILE 
curl -T ./$SITE/$SITE.html ftp://$HOST/$SITE/$SITE.html --user $USERNAME:$PASSWORD


#*----
cd $CURR
