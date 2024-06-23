
#!/bin/sh
#*-----------------------------------------------------------------------*
#* processQSL                                                            *
#* Process all ADIF files (.ADI) on a given directory and upload them    *
#* into different supported QSL platforms                                *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
clear
CURR=$(pwd)
export DISPLAY=:0.0
tmpFile="tmpFile"
QFILES=0
echo "Temp File($tmpFile)"

PWD=$(pwd)
ADI=$PWD/ADIF

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)

#*--- Processing environment

#*--- Extract files and process, would process the file from WSJT-X plus any other placed in the directory with .adi extension

FILES=$(ls $ADI/*.adi)

for f in $FILES
do
  echo "\r\nProcessing file ($f)\r\n" 2>&1 | tee -a $tmpFile
#*-----------------(Process LoTW using TQSL)-----------------------------------
#* Certificate of trust from ARRL must be availble for the CALL used
#*-----------------------------------------------------------------------------
  echo "\r\nLoTW Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  echo "CALL($CALL)"
  echo "PASS($PASS)"
  LINE=$(tqsl -c $CALL -d -u -q -a all -x -d -p $PASS  $f 2>&1)
  echo "\r\n$LINE\n\r" 2>&1 | tee -a  $tmpFile

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
cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
