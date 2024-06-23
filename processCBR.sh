
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

export DISPLAY=:0.0

#*--- Execution environment

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")

export DISPLAY=:0.0
NGROK="/home/pi/Downloads/ngrok-stable-linux-arm"
ADI="$NGROK/ADIF"
LCK="$ADI/$ME.lck"
tmpFile="$ADI/$ME.tmp"
CSV="$ADI/$ME.csv"
UTIME=$(uptime | sed -E 's/^[^,]*up *//; s/, *[[:digit:]]* users.*//; s/min/minutes/; s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/' )

cd $NGROK

WSJTZ="/home/pi/.local/share/WSJT-X"
ROOT="/root/.local/share/WSJT-X"

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

rm -r cbrData.adi
FILES=$(ls $ADI/*.cbr)

for f in $FILES
do
  echo "$ME: Processing file ($f)" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/cbr2adif.py LT7D $f >> cbrData.adi
  QFILES=$((QFILES+1))
done

if [ "$QFILES" -gt "0" ]; then

#*-----------------(Send mail with results)------------------------------------
   echo "$ME: Sending mail to ($TO)" 2>&1 | tee -a $tmpFile
   POST=$(cat $tmpFile)
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "ADIF Upload @ $SITE" "$POST" "" 2>&1 | logger -i -t "$ME"
   cat $tmpFile 2>&1 | logger -i -t "$ME"

else
   echo "$ME: No activity files found" 2>&1 | tee -a $tmpFile
fi

#*----- final clean up ante termination

rm -r $tmpFile 2>&1 > /dev/null
cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
