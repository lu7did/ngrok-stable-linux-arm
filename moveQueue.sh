#!/bin/sh
#*---------------------------------------------------------------------*
#* moveQueue
#* Script to manage events from the camera and handle files generated
#*---------------------------------------------------------------------*
cd /home/pi/Downloads/ngrok-stable-linux-arm

#*--- Define variables
#*--- Arguments
#*--- (1) Filename if event=on_movie_end or event name
#*--- (2) Event name if !on_movie_end or blank otherwise
#*---
FILE=$(echo  $1 | cut -f 5 -d \/)
DELIM=$(echo $FILE  | cut  -d . -f 2)
EXT="lck"

HOST=$(python getJason.py sitedata.json qsl.net_host)
USERNAME=$(python getJason.py sitedata.json qsl.net_user)
PASSWORD=$(python getJason.py sitedata.json qsl.net_pswd)
QSLDIR=$(python getJason.py sitedata.json qsl.net_dir)
TO=$(python getJason.py sitedata.json mail)

DIR="$QSLDIR/images"
JPG="jpg"
MP4="mp4"

#*--- Look for a .lck file (any) and take it as a blocking signal
#*--- SCAN=0 not blocked SCAN>0 blocked

SCAN=$(ls -la *.$EXT 2> /dev/null | wc -l)

#*--- Always ignore on_event_end events

if [ "$1" = "on_event_end" ]; then
   echo "File ($1) detected as event, ignored" 2>&1 | logger -i -t "moveQueue"
   exit 0
fi

#*--- If blocked then do not send mail alarms nor write movement events (mp4)

if [ "$SCAN" != "0" ]; then
   if [ "$DELIM" =  "$MP4"  ];
   then
      rm -r $1 2>&1 | logger -i -t "moveQueue"
      echo "Motion detection is blocked, file ($1) deleted" 2>&1 | logger -i -t "moveQueue"
      exit 0
   fi
fi

#*--- Log activity, it should be a regular snap picture only if blocked
#*--- and all files received if !blocked

echo "User ($(whoami)) File ($1) Event($2)"  2>&1 | logger -i -t "moveQueue"

#*--- Transfer to OneDrive folder
./rclone.motion

#*--- Upload to qsl.net site
echo "upload  ($1) to host($HOST/$DIR) using id($USERNAME)" 2>&1  | logger -i -t "moveQueue"
ftp-upload -h $HOST  -u $USERNAME --password $PASSWORD -d $DIR $1 2>&1 | logger -i -t "moveQueue"

#*----- If it is a motion detection video then send mail alarm
if [ "$DELIM" =  "$MP4" ];
then
   echo "Motion detected sent URL for $FILE to $TO" 2>&1 | logger -i -t "moveQueue"
   python sendmail.py $TO $FILE
   exit 0
fi
cd $CURR
