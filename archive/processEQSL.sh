#!/bin/sh
#*-----------------------------------------------------------------------*
#* processEQSL.sh                                                        *
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into eQSL.cc, this process is stand alone to process imports          *
#* to process individual logs use processADIF.sh instead                 *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD

#*--- Execution environment

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")


#*--- Retrieve keys
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
NODE="$CALL @ $SITE"
MASTER=$CALL"_"$SITE"_MASTER.log"

#*--- Get directory to scan for .ADI files
if [ "$DIR" = "" ]; then
   DIR="."
fi

#*--- Extract files and process
FILES=$(ls $DIR/*.adi)
echo "Processing QSL to eQSL.com" 2>&1 | logger -i -t "eQSL.cc"
POST=$(echo 'Process ADIF files at node("$NODE") directory("$DIR")')

for F in $FILES
do
   while IFS= read -r line
   do
     M=$(echo $line | cut -d " " -f 1)
     if [ "$M" != "ADI" ]; then
        H=$(echo "$line" | cut -d ":" -f 1 | tr -d '\r' | tr -d '\n')
        if [ "$H" = "<call" ]; then
           CALL=$(echo $line | cut -d "<" -f 2 | cut -d ">" -f 2)
           QRZpost="python /home/pi/Downloads/ngrok-stable-linux-arm/eqslpost.py INSERT '$line'"
           RESP=$($QRZpost)
           POST=$(echo '$POST QSO($CALL) Response($RESP)') 2>&1 | logger -i -t "eQSL.cc"
           RESOK=$(echo "$RESP" | grep "Information: ")
           RESNOK=$(echo "$RESP" | grep "Warning: ")
           echo "$ME: $(date) processed QSO with ($CALL) ResponseOk($RESOK) ResponseNOk($RESNOK)" 2>&1 | logger -i -t "eQSL.cc"
           echo "$ME: $(date) processed QSO with ($CALL) ResponseOk($RESOK) ResponseNOk($RESNOK)" 
        else
           echo "$ME: $(date) rejected QSO with ($CALL) record ignored" 2>&1 | logger -i -t "eQSL.cc"
        fi
     fi
   done < "$F"
done
cd $CURR
