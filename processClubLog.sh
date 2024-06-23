
#!/bin/sh
#*-----------------------------------------------------------------------*
#* processQSL                                                            *
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into different supported QSL platforms                                *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
clear
CURR=$(pwd)
PWD=$(dirname $0)
ADI=$PWD/ADIF
LCK=$PWD/ADIF/processQSL.lck
echo "Current($CURR) PWD($PWD) ADIF($ADI)\n"
cd $PWD

export DISPLAY=:0.0
NGROK="/home/pi/Downloads/ngrok*"
WSJTZ="/home/pi/.local/share/WSJT-X"

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)

#*--- Retrieve site data keys for ClubLog

CODING="Content-Type: application/x-www-form-urlencoded"
CLUBLOG_ID=$(python getJason.py sitedata.json clublog.id)
CLUBLOG_PASS=$(python getJason.py sitedata.json clublog.pass)
CLUBLOG_API=$(python getJason.py sitedata.json clublog.api)
CLUBLOG_URL=$(python getJason.py sitedata.json clublog.url)


#*--- Processing environment

NODE="$CALL @ $SITE"
MASTER=$CALL"_"$SITE"_MASTER.log"
tmpFile="tmpFile"
QFILES=0

#*--- Inet reference
INET="http://google.com"
QNET=0
INETFILE="inetcheck"

#*----- Check for re-entrancy
if test -f "$LCK"; then
   HOST=$(hostname)
   POST=$(echo "Program processQSL re-entrancy detected ($HOST), check lock exit")
   echo "Error message($POST)"
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL $POST 2>&1 | logger -i -t "processQSL"
   exit 0
fi

#*--- Get directory to scan for .ADI files (default to current if none informed)
if test -f $tmpFile; then
rm -r $tmpFile 2>&1 > /dev/null 
fi

#*--- Create temporary message file
touch $tmpFile 2>&1 > /dev/null


echo "Processing activity Site($SITE) Call($CALL) Node($NODE) Directory($ADI)\n\r" 2>&1 | tee -a  $tmpFile
echo $INETMSG 2>&1 | tee -a $tmpFile

FILES=$(ls $ADI/*.adi)

for f in $FILES
do
#*-----------------[Process ClubLog]-------------------------------------------
  echo "\r\nClubLog Upload file($f) Call($CALL) Password($CLUBLOG_PASS) API($CLUBLOG_API) Result\n\r" 2>&1 | tee -a $tmpFile
  
  echo "curl -v -H $CODING  --data-urlencode adif@$f -d email=$CLUBLOG_ID -d callsign=$CALL -d password=$CLUBLOG_PASS -d api=$CLUBLOG_API $CLUBLOG_URL"
  RESULT=$(curl -v -H $CODING  --data-urlencode adif@$f -d email=$CLUBLOG_ID -d callsign=$CALL -d password=$CLUBLOG_PASS -d api=$CLUBLOG_API $CLUBLOG_URL)
  echo $RESULT 2>&1 | tee -a $tmpFile

#*------------------(Archive ADI files)
  echo "\r\nStoring $f at $ADI/$MASTER" 2>&1 | tee -a $tmpFile
  QFILES=$((QFILES+1))
done

if [ "$QFILES" -gt "0" ]; then

#*-----------------(Send mail with results)------------------------------------
   echo "\r\nSending mail to ($TO)" 2>&1 | tee -a $tmpFile
   POST=$(cat $tmpFile)
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL $POST 2>&1 | logger -i -t "processQSL"
   cat $tmpFile 2>&1 | logger -i -t "processQSL"

else
   echo "\r\nNo activity files found" 2>&1 | tee -a $tmpFile
fi

#*----- final clean up ante termination

cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
