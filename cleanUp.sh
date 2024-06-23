#!/bin/sh
#*-------------------------------------------------------------------------------------------------
#* cleanUp.sh
#* Keep the nth ($2) oldest files on a directory ($1) 
#*-------------------------------------------------------------------------------------------------
#*---- Retrieve execution environment
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

#*--- Now delete all files older than 7 days
#find $1 -type f -mtime +7 -delete
SITE=$(python getJason.py sitedata.json site)
CAMDIR="/home/pi/Downloads/ngrok*/$SITE/cam"
cd $CAMDIR
tar -zcvf $SITE_cam_$(date +"%FT%H%M").tar.gz /var/lib/motion
sudo rm -r /var/lib/motion/*.mp4
sudo rm -r /var/lib/motion/*.jpg
sudo cp /home/pi/.config/rclone/rclone.conf /var/lib/motion/rclone.conf

cd $PWD
./rclone.capture 2>&1 | logger -i -t "cleanUp"
./ftp-mdel.sh 2>&1 | logger -i -t "cleanUp"

ch $CURR
