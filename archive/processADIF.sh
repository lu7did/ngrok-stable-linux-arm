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

echo "Processing activity Site($SITE) Call($CALL) Node($NODE) Directory($DIR)\n\r" 2>&1 | tee -a  $tmpFile

echo "LoTW Upload\n\r" 2>&1 | tee -a $tmpFile
for L in $FILES
do
  echo "Processing file $L not performed" 2>&1 | tee -a $tmpFile
  #LINE=$(tqsl -c $CALL -d -u -q -a all -x -d  $L 2>&1)
  #echo "LoTW Result($LINE)\n\r" 2>&1 | tee -a  $tmpFile
done

for R in $FILES
  do
    echo "Processing LdA file ($R)" | tee -a $tmpFile
    LdApost="python3.7 /home/pi/Downloads/ngrok-stable-linux-arm/ldapost.py FILE $R"
    LdARESP=$($LdApost 2>&1 > $respFile)
    cat $respFile | tee -a $tmpFile
  done 

for F in $FILES
do
   while IFS= read -r line
   do
     M=$(echo $line | cut -d " " -f 1)
     if [ "$M" != "ADIF" ]; then
        H=$(echo "$line" | cut -d ":" -f 1 | tr -d '\r' | tr -d '\n')
        if [ $H = "<call" ]; then
           CALL=$(echo $line | cut -d "<" -f 2 | cut -d ">" -f 2)
           CALL=$(echo $CALL | tr -d '\r')
           QRZpost="python /home/pi/Downloads/ngrok-stable-linux-arm/qrzpost.py INSERT '$line'"
           RESP=$($QRZpost)
           LINE=$(echo "\r\nQSO("$CALL") Response from QRZ.com"$RESP"\n\r")
           echo $LINE 2>&1 | tee -a $tmpFile

           eQSLpost="python /home/pi/Downloads/ngrok-stable-linux-arm/eqslpost.py INSERT '$line'"
           eQSLRESP=$($eQSLpost)
           echo $eQSLRESP 2>&1 > $respFile
           RESP=$(python3.7 /home/pi/Downloads/ngrok-stable-linux-arm/eqslparse.py $respFile)
           LINE=$(echo "\r\nQSO("$CALL") Response from eQSL.cc\n\r"$RESP"\n\r")
           echo $LINE 2>&1 | tee -a $tmpFile
           rm -r $respFile 2>&1 

        else
           echo "$(date) rejected QSO with ($CALL) record ignored\n\r" 2>&1 
        fi
     fi
   done < "$F"





   echo "\r\nSending mail to ($TO)" 2>&1 | tee -a $tmpFile
   echo "\r\nStoring .adi at $DIR/$MASTER" 2>&1 | tee -a $tmpFile

   POST=$(cat $tmpFile)
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail_qrz.py $TO $CALL $POST 2>&1 | logger -i -t "processADIF"
   cat $tmpFile 2>&1 | logger -i -t "processADIF"

   cat $F 2>&1 >> $DIR/$MASTER 
   rm -r $F 2>&1 
   rm -r $tmpFile 2>&1
done

cd $CURR
