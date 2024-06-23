
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

#*--- Extract files and process, would process the file from WSJT-X plus any other placed in the directory with .adi extension

FILES=$(ls $ADI/*.adi)

for f in $FILES
do
  echo "\r\nProcessing file ($f)\r\n" 2>&1 | tee -a $tmpFile

#*-----------------[Process ClubLog]-------------------------------------------
  echo "\r\nClubLog Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  
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

rm -r $tmpFile 2>&1 > /dev/null
rm -r $ADI/wsjtx.new 2>&1 > /dev/null
rm -r $LCK
cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
