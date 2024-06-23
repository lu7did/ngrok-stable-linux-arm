#!/bin/sh
#*-----------------------------------------------------------------------*
#* processHamQTH.sh                                                      *
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into HamQTH, this process is stand alone to process imports           *
#* to process individual logs use processADIF.sh instead                 *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

#*--- Retrieve keys
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)

NODE="$CALL @ $SITE"
HAMQTH_USER=$(python getJason.py sitedata.json hamqth_user)
HAMQTH_PSWD=$(python getJason.py sitedata.json hamqth_pswd)
HAMQTH_URL=$(python getJason.py sitedata.json hamqth_url)
MASTER=$CALL"_"$SITE"_MASTER.log"

#*--- Get directory to scan for .ADI files
if [ "$DIR" = "" ]; then
   DIR="."
fi

#*--- Extract files and process
FILES=$(ls $DIR/*.adi)
echo "Processing QSL to HamQTH.com" 2>&1 | logger -i -t "HamQTH.com"
POST=$(echo "\n\rProcess ADIF files at node($NODE)\n\rdirectory($DIR)\n\r")

for F in $FILES
do
   HAMQTHpost="curl -k -F f=$F -F send_log=OK -F u=$HAMQTH_USER -F p=$HAMQTH_PSWD $HAMQTH_URL"
   echo "Executing ($HAMQTHpost)"
   RESP=$($HAMQTHpost)
   POST=$(echo "\n\r ADIF("$F")\n\rResponse("$RESP")\n\r")
   echo "$(date) processed HamQTH post $POST" 2>&1 | logger -i -t "HamQTH.com"
   echo "$(date) processed HamQTH post $POST" 2>&1 | tee -a HamQTH.log 
done
cd $CURR
