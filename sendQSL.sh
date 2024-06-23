#!/bin/sh

#*------------------------------------------------------------------------
#* sendQSL
#* Automatic management system
#* Execute ADIF to CSV extraction
#* Inspect all records of new file and check if not already sent
#* $1 New candidate QSL file
#  $2 Previous QSL file (to check for duplicates)
#* Send QSL for all eligible stations
#* (c) Dr. Pedro E. Colla LU7DZ 2023
#*------------------------------------------------------------------------

#*--- Execution environment

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")

NGROK="/home/pi/Downloads/ngrok-stable-linux-arm"

ADI="$NGROK/ADIF"
LCK="$ADI/$ME.lck"
tmpFile="$ADI/$ME.tmp"
CSV="$ADI/$ME.csv"

export DISPLAY=:0.0
cd $NGROK


#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)
QSLINFO=$(python getJason.py sitedata.json qsl.info)
#*--- Processing environment

NODE="$CALL @ $SITE"
MASTER=$CALL"_"$SITE"_MASTER.log"
QFILES=0

#*--- Inet reference
INET="http://google.com"
QNET=0
INETFILE="inetcheck"

QSL="$SCRIPT_PATH/$CALL.csv"


#*----- Check for re-entrancy
if test -f "$LCK"; then
   HOST=$(hostname)
   POST=$(echo "Program processQSL is locked ($HOST) site($SITE), check lock exit")
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py "$TO" "Execution information" "$POST" "" 2>&1 | logger -i -t  "$ME"
   exit 0
fi

if test -f "$QSL"; then
   echo "QSL file found Ok " 2>&1 | logger -i -t "$ME"
else
   touch "$QSL"
   echo "QSL file not found, created" 2>&1 | logger -i -t "$ME"
fi

#*---- Lock in place to prevent re-entrancy (however, if the script fails will prevent further exectution until cleared)
touch $LCK

#*--- Remove previous temporary file
if test -f $tmpFile; then
rm -r $tmpFile 2>&1 > /dev/null 
fi

#*--- Create temporary message file
touch $tmpFile 2>&1 > /dev/null

#*---------------------------------------------------------------------------
#* Process ADIF file, extract all QSO made during the period
#*---------------------------------------------------------------------------

    python3.7 $NGROK/getQRZXML.py $1 2>&1 | tee -a $tmpFile > $CSV
    N=$(cat $CSV | wc -l)
    if [ "$N" -eq "0" ] ; then
       POST=$(echo "$ME: Program $ME found no ADIF file to process. Exit")
       python $NGROK/sendmail.py "$TO" "Empty ADIF file" "$POST" "" 2>&1 | logger -i -t  "$ME"
       rm -r $LCK
       exit 0
    fi


#*---------------------------------------------------------------------------
#* Process entry file with QSO information (CSV format), avoid dupes
#*---------------------------------------------------------------------------
Q=0
S=0

while read line; do

  CALL=$(echo "$line" | cut -f2 -d"," | cut -f2 -d'"')
  BAND=$(echo "$line" | cut -f5 -d"," | cut -f2 -d'"')

  Q=$(cat $QSL | grep "$BAND" | grep "$CALL" | wc -l)

  DATE=$(echo "$line" | cut -f3 -d"," | cut -f2 -d'"')
  UTC=$(echo "$line" | cut -f4 -d"," | cut -f2 -d'"')
  MODE=$(echo "$line" | cut -f6 -d"," | cut -f2 -d'"')
  RST=$(echo "$line" | cut -f7 -d"," | cut -f2 -d'"')

  EMAIL=$(echo "$line" | cut -f8 -d"," | cut -f2 -d'"')

  if [ "$Q" -eq "0" ] && [ ! -z "$EMAIL" ] && [ "$EMAIL" != "EMAIL" ] ; then
     tmpPdf="$(mktemp ./XXXXXXXXX.pdf)"
     $NGROK/postRadioQTH.sh $CALL $DATE $UTC $BAND $MODE $RST "$QSLINFO"> "$tmpPdf"
     MSG=$(echo "QSO information\rStation:$CALL\rBand:$BAND\rDate:$DATE $UTC\rMode:$MODE\rRST:$RST\r")
     python sendmail.py "$EMAIL" "QSO Confirmation" "$MSG" "$tmpPdf"  2>&1 | tee -a $tmpFile
     S=$((S+1))
     echo "$ME: Sending QSL for Radio($CALL) QSO($DATE $UTC) Band($BAND) Mode($MODE) RST($RST)" 2>&1 | tee -a $tmpFile 
     rm -r $tmpPdf 2>&1 | tee -a $tempFile | logger -i -t "$ME"
  else
     if [ "$EMAIL" != "EMAIL" ] ; then
        echo "Q($Q) CALL($CALL) DATE($DATE) UTC($UTC) BAND($BAND) MODE($MODE) RST($RST) EMAIL($EMAIL) invalid data or dupe" 2>&1
     fi
  fi

done < $CSV
rm -r $LCK >&1 > /dev/null

