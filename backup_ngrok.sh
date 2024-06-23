#!/bin/sh
#*----------------------------------------------*
#* Backup ngrok environment files               *
#*----------------------------------------------*
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD
SITE=$(python getJason.py sitedata.json site)
cd ..
FILE=$SITE_backup.tar.gz
tar -cvvzf $FILE --exclude="ngrok" --no-recursion ./ngrok-stable-linux-arm/*
mv $FILE ./ngrok-stable-linux-arm/$SITE/backup_ngrok.tar.gz
echo "$(date) backup of $FILE completed" 2>&1 | logger -i -t "Backup" 

