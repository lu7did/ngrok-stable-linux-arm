#!/bin/sh
#*--------------------------------------------------------------------------------------------*
#* Este proceso revisa si WSJT-Z está corriendo en la máquina y de no estarlo lo relanza      *
#* se tiene en cuenta el caso de una terminación  anormal que deje zombie un proceso JT9      *
#*--------------------------------------------------------------------------------------------*
getPID() {
  PID=$(pidof $1)
  echo $PID
}
#*---
getUSER() {
  if [ `pidof $1 | wc -l` -ne 0 ]; then
     USER=$(ps -o user -p `pidof $1` | grep -v "USER")
     echo "$USER"
  else
     echo ""
  fi  
}
#*---
getNumberProcess() {
  echo $(pidof $1 | wc -l)
}

#*----------------------------------------------------------------------*
#* Main program                                                         *
#*----------------------------------------------------------------------*
clear
export DISPLAY=:0.0

#*--- Execution environment

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

#*--- Center execution on the directory where the script is located

cd "$NGROK"

if test -f $LCK; then
   echo "$ME is locked, execution terminated" 2>&1 | logger -i -t "$ME"
   exit
fi

sudo rm -r $tmpFile 2>&1 | logger -i -t "$ME"

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)

#*--- Check if WSJTZ is running

proc="wsjtx"

if [ $(getNumberProcess $proc) -ne 0 ]; then
   echo "Site($SITE) Process $proc  is running normally with pid($(getPID $proc)) under user($(getUSER $proc))" 2>&1 | tee -a $tmpFile
   echo "0" > $CTLFILE
   cat $tmpFile 2>&1 | logger -i -t "$SCRIPT_NAME"
   exit
else
   echo "Site($SITE) $proc not running, recovery started" 2>&1 | tee -a $tmpFile
   USB0=$(ls $USB | wc -l)
   if [ $(USB0) -ne 1 ]; then
      echo "\n\rtSite($SITE) $USB not found, reboot" 2>&1 | tee -a $tmpFile
      $NGROK/$COUNTDOWN.sh 2>&1 | tee -a $tmpFile
      exit
   fi

   echo "0" > $CTLFILE

   JT9="jt9"
   if [ $(getNumberProcess $JT9) -ne 0 ]; then
      echo "\n\r$JT9 found with pid($(getPID $JT9)) user($(getUSER $JT9)), removing it" 2>&1 | tee -a $tmpFile
      kill $(getPID $JT9) 2>&1 | tee -a $tmpFile
      sleep 1
   fi

   #*--- Launch monitored program
   $WSJTZ &
   sleep 1
fi
#*-----------------(Send mail with results)------------------------------------
echo "\r\nSending mail to ($TO) call ($CALL)" 2>&1 | tee -a $tmpFile
echo "\r\nPlease check starting configuration ASAP" 2>&1 | tee -a $tmpFile

POST=$(cat $tmpFile)

python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL "$ME:WSJTZ Failure @ $SITE" "$POST" 2>&1 | logger -i -t "$ME"
cat $tmpFile 2>&1 | logger -i -t "$ME"


