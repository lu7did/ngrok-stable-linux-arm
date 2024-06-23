
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
echo "Current($CURR) PWD($PWD) ADIF($ADI)\n"
cd $PWD

export DISPLAY=:0.0
NGROK="/home/pi/Downloads/ngrok*"
WSJTZ="/home/pi/.local/share/WSJT-X"

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)

#*--- Processing environment

NODE="$CALL @ $SITE"
MASTER=$CALL"_"$SITE"_MASTER.log"
tmpFile="tmpFile"
QFILES=0

#*--- Inet reference
INET="http://google.com"
QNET=0
INETFILE="inetcheck"

#*--- Check Inet availability
wget -q --spider $INET
if [ $? -eq 0 ]; then
   QNET=1
   INETMSG=$(echo "Internet connectivity site ($SITE) found ok $(date) ")
   echo $INETMSG
else
   INETMSG=$(echo "Internet connection site($SITE) failed at $(date)")
   echo $INETMSG 2>&1  | tee -a $INETFILE
   cd $CURR
   exit 1
fi

#*--- Process the WSJT-X.adi file recovering the new data 
if test -f $ADI/wsjtx.old; then
   echo "File ($ADI/wsjtx.old) not found creating it"
   touch $ADI/wsjtx.old 2>&1 > /dev/null 
fi
#*--- Copy ADIF from activity
cp $WSJTZ/wsjtx_log.adi $ADI/wsjtx.new
echo "Copying ($WSJTZ/wsjtx_log.adi) into ($ADI/wsjtx.new)"

#*--- Detect differences between current ADIF and previous one, cut the difference only
python3 $PWD/compareADIF.py $ADI/wsjtx.new $ADI/wsjtx.old > $ADI/wsjtx.adi

#*--- Rotate the reference
cp $ADI/wsjtx.new $ADI/wsjtx.old 2>&1 > /dev/null 

#*--- Get directory to scan for .ADI files (default to current if none informed)
if test -f $tmpFile; then
rm -r $tmpFile 2>&1 > /dev/null 
fi

#*--- Create ADI 
if [ "$ADI" = "" ]; then
   ADI="."
fi

#*--- Create temporary message file
touch $tmpFile 2>&1 > /dev/null

#*--- Extract files and process
FILES=$(ls $ADI/*.adi)

echo "Processing activity Site($SITE) Call($CALL) Node($NODE) Directory($ADI)\n\r" 2>&1 | tee -a  $tmpFile
echo $INETMSG 2>&1 | tee -a $tmpFile

#*--  Verify if previous Internet issues happened, if so include a message in the mail (and force a mail)
if test -f "$INETFILE"; then

    echo "\r\n" 2>&1 | tee -a $tmpFile
    echo "*************************************************\r\n" 2>&1 | tee -a $tmpFile
    echo "---               WARNING                     ---\r\n" 2>&1 | tee -a $tmpFile
    echo "--- Previous Internet unavailability detected ---\r\n" 2>&1 | tee -a $tmpFile
    echo "*************************************************\r\n" 2>&1 | tee -a $tmpFile
    cat $INETFILE >> $tmpFile
    echo "\r\n*************************************************\r\n" 2>&1 | tee -a $tmpFile

    QFILES=$((QFILES+1))
    rm -r $INETFILE 2>&1 > /dev/null 

fi

for f in $FILES
do
  echo "\r\nProcessing file ($f)\r\n" 2>&1 | tee -a $tmpFile
#*-----------------(Process LoTW using TQSL)-----------------------------------
#* Certificate of trust from ARRL must be availble for the CALL used
#*-----------------------------------------------------------------------------
  #echo "\r\nLoTW Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  #LINE=$(tqsl -c $CALL -d -u -q -a all -x -d  $f 2>&1)
  #echo "\r\n$LINE\n\r" 2>&1 | tee -a  $tmpFile

#*-----------------(Process Log de Argentina (LdA)-----------------------------
  echo "\r\nLdA Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postLdA.py $f 2>&1 | tee -a $tmpFile 

#*-----------------(Process QRZ.com)-------------------------------------------
  echo "\r\nQRZ.com Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postQRZ.py $f 2>&1 | tee -a $tmpFile 

#*-----------------(Process eQSL.cc)-------------------------------------------
  echo "\r\neQSL.cc Upload file($f) Result\n\r" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postEQSL.py $f 2>&1 | tee -a $tmpFile 

#*------------------(Archive ADI files)
  echo "\r\nStoring $f at $ADI/$MASTER" 2>&1 | tee -a $tmpFile

  cat $f 2>&1 >> $ADI/$MASTER 
  rm -r $f 2>&1 > /dev/null
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
rm -r $tmpFile 2>&1 > /dev/null
rm -r $ADI/wsjtx.new 2>&1 > /dev/null
cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
