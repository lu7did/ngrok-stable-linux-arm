#!/bin/sh
#*--------------------------------------------------------------
#* countDown.sh
#* Este script cuenta hasta un watermark dado por MAXTIME y 
#* mientras esté por debajo ejecuta un comando dado por CMD y al
#* alcanzarlo envia un correo de aviso pasado el watermark no
#* hace nada
#* Dr. Pedro E. Colla (LU7DZ) 2023
#*--------------------------------------------------------------
CMD="sudo reboot"
MAXTIME=3
SCRIPT_PATH=$(dirname "$0")
SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
PWD=$(pwd)


cd $SCRIPT_PATH

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)


#*--- Retrieve persistence file name and content

ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")
CTLFILE=$(echo "$ME.txt")
TMPFILE=$(echo "$ME.tmp")
touch $TMPFILE

if test ! -f $CTLFILE; then
   echo "0" > $CTLFILE
fi

#*--- Increase counter

if [ $(cat $CTLFILE) -gt $MAXTIME ]; then
   q=$(cat $CTLFILE)
else
   q=$(cat $CTLFILE)
   q=$((q+1))
   echo "$q" > $CTLFILE
fi

if [ $((q)) -eq $MAXTIME ]; then
   echo "<$q> Action: Send email" 2>&1 | logger -i -t "countDown"
   echo "\r\nScript($0) control file ($CTLFILE)\r\nReach counter max($MAXTIME)\r\nSending mail to ($TO)\r\nNext action is stalling" 2>&1 | tee -a $TMPFILE
   POST=$(cat $TMPFILE)
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL "countDown Panic @ $SITE" "$POST" 2>&1 | logger -i -t "countDown"
   cat $TMPFILE 2>&1 | logger -i -t "countDown"

else
   if [ $((q)) -gt $MAXTIME ]; then
      echo "<$q> Action: Count exceed maximum. Do nothing"  2>&1 | logger -i -t "countDown"
   else
      echo "<$q> Action: Execute CMD($CMD)"  2>&1 | logger -i -t "countDown"
      echo "\r\nScript($0) control file ($CTLFILE)\r\nCurrent counter reach($q)\r\nSending mail to ($TO)\r\nCountdown activated" 2>&1 | tee -a $TMPFILE
      POST=$(cat $TMPFILE)
      python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL "countDown Alert @ $SITE" "$POST" 2>&1 | logger -i -t "countDown"
      cat $TMPFILE 2>&1 | logger -i -t "countDown"
      sleep 1
      $CMD
   fi
fi

rm -r $TMPFILE
cd $PWD
