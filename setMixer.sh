#!/bin/sh
#*-----------------------------------------------------------------------*
#* processQSL                                                            *
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into different supported QSL platforms                                *
#*-----------------------------------------------------------------------*
#*---
getNumberProcess() {
  echo $(pidof $1 | wc -l)
}

#*---- Retrieve execution environment

clear
CURR=$(pwd)
PWD=$(dirname $0)
ADI=$PWD/ADIF
LCK=$PWD/ADIF/processQSL.lck
NGROK="/home/pi/Downloads/ngrok-stable-linux-arm"
WSJTZ="/home/pi/.local/share/WSJT-X"
tmpFile="tmpFilesetMixer.tmp"

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")
COUNTDOWN="countDown"
PWD=$(pwd)
WSJTZ="wsjtx"
NGROK="$SCRIPT_PATH"
ADI=$SCRIPT_PATH/ADIF
LCK=$ADI/"$ME.lck"
USB="/dev/ttyUSB0"
tmpFile=$ADI/"$ME.tmp"
CTLFILE=$COUNTDOWN.txt
QFILES=0
rm -r $tmpFile


cd $NGROK

export DISPLAY=:0.0
echo "Processing Mixer Level set path($NGROK)" 2>&1 | tee -a $tmpFile

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)

#*--- Set audio level
amixer -c 3 sset 'Mic' 35% 2>&1 | tee -a $tmpFile
cat $tmpFile 2>&1 | logger -i -t "$ME"

#*--- Send mail (to be removed)
#POST=$(cat $tmpFile)
#python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL "Audio level @ $SITE" "$POST" 2>&1 | logger -i -t "$ME"

