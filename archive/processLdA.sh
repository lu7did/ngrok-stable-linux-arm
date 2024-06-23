#!/bin/sh
#*-----------------------------------------------------------------------*
#* processADIF.sh
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into qrz.com                                                          *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD
export DISPLAY=:0.0

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

tmpFile="tmpFile"
respFile="respFile"

#*--- Get directory to scan for .ADI files
rm -r $tmpFile 2>&1 

if [ "$DIR" = "" ]; then
   DIR="."
fi

#*--- Create temporary message file
touch $tmpFile

#*--- Extract files and process
FILES=$(ls $DIR/*.adi)

echo "$ME: Processing mass import Site($SITE) Call($CALL) Node($NODE) Directory($DIR)" 2>&1 | tee -a  $tmpFile

for R in $FILES
  do
    echo "$ME: Processing LdA file ($R)" | tee -a $tmpFile
    LdApost="python3.7 /home/pi/Downloads/ngrok-stable-linux-arm/ldapost.py FILE $R"
    LdARESP=$($LdApost 2>&1 > $respFile)
    cat $respFile | tee -a $tmpFile
    cat $R 2>&1 >> $DIR/$MASTER 
    rm -r $R 2>&1 
    rm -r $respFile

  done 


echo "$ME: Sending mail to ($TO)" 2>&1 | tee -a $tmpFile
echo "$ME: Storing .adi at $DIR/$MASTER" 2>&1 | tee -a $tmpFile

POST=$(cat $tmpFile)
echo $(python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "$ME: $CALL" "$POST" "") 2>&1 | logger -i -t "processLdA"
cat $tmpFile 2>&1 | logger -i -t "processLdA"

rm -r $tmpFile 2>&1

cd $CURR
