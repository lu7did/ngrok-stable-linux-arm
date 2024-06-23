
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

#*----- Check for re-entrancy
if test -f "$LCK"; then
   HOST=$(hostname)
   POST=$(echo "re-entrancy detected ($HOST), check lock exit")
   echo "$ME: Error message($POST) Node ($NODE) uptime($UTIME))"
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "$ME Lock detected @ $SITE" $POST "" 2>&1 | logger -i -t "$ME"
   exit 0
fi

#*---- Lock in place to prevent re-entrancy (however, if the script fails will prevent further exectution until cleared)
touch $LCK

#*--- Check Inet availability
wget -q --spider $INET
if [ $? -eq 0 ]; then
   QNET=1
   INETMSG=$(echo "$ME: Internet connectivity site ($SITE) found ok $(date) ")
   echo $INETMSG
else
   INETMSG=$(echo "$ME: Internet connection site($SITE) failed at $(date)")
   echo $INETMSG 2>&1  | tee -a $INETFILE
   cd $CURR
   rm -r $LCK >&1 > /dev/null
   exit 1
fi


#*--- Remove previous temporary file
if test -f $tmpFile; then
rm -r $tmpFile 2>&1 > /dev/null 
fi

#*--- Create temporary message file
touch $tmpFile 2>&1 > /dev/null


echo "$ME: Site($SITE) Call($CALL) Node($NODE) Directory($ADI)" 2>&1 | tee -a  $tmpFile
echo "$ME: Uptime($UTIME)" 2>&1 | tee -a  $tmpFile
echo $INETMSG 2>&1 | tee -a $tmpFile

#*--  capture telemetry data
echo "$ME: Telemetry data" 2>&1 | tee -a $tmpFile
echo "$ME: $($NGROK/setTelemetry.sh)" 2>&1 | tee -a $tmpFile
echo " " 2>&1 | tee -a $tmpFile

#
#*--  Verify if previous Internet issues happened, if so include a message in the mail (and force a mail)
if test -f "$INETFILE"; then

    echo "*************************************************" 2>&1 | tee -a $tmpFile
    echo "---               WARNING                     ---" 2>&1 | tee -a $tmpFile
    echo "--- Previous Internet unavailability detected ---" 2>&1 | tee -a $tmpFile
    echo "*************************************************" 2>&1 | tee -a $tmpFile
    cat $INETFILE >> $tmpFile
    echo "*************************************************" 2>&1 | tee -a $tmpFile

    QFILES=$((QFILES+1))
    rm -r $INETFILE 2>&1 > /dev/null 

fi


#*--- Copy ADIF from WSJT-X activity and log directory

if test ! -f $WSJTZ/wsjtx_log.adi; then
   echo "$ME: File ($WSJTZ/wsjtx_log.adi) not found, process terminated" 2>&1 | tee -a $tmpFile
   if [ "$QFILES" -gt "0" ]; then
      echo "$ME: Sending mail to ($TO)" 2>&1 | tee -a $tmpFile
      POST=$(cat $tmpFile)
      python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "No ADIF @ $SITE" $POST "" 2>&1 | logger -i -t "$ME"
   else
      echo "$ME: No pending activity"
   fi
   rm -r $LCK >&1 > /dev/null
   exit 0  
fi

#*--- Process the WSJT-X.adi file recovering the new data
 
if test ! -f $ADI/wsjtx.old; then
   echo "$ME: File ($ADI/wsjtx.old) not found creating it" 2>&1 | tee -a $tmpFile
   touch $ADI/wsjtx.old 2>&1 > /dev/null 
fi

#*--- Store the last adif file into the old to prevent further processing
if test -f $WSJTZ/wsjtx_log.adi; then
   cp $WSJTZ/wsjtx_log.adi $ADI/wsjtx.new
   echo "$ME: Copying ($WSJTZ/wsjtx_log.adi) into ($ADI/wsjtx.new)" 2>&1 | tee -a $tmpFile
fi

#if test -f $ROOT/wsjtx_log.adi; then
#   sudo cat $ROOT/wsjtx_log.adi >> $ADI/wsjtx.new 
#   echo "$ME: Appending ($ROOT/wsjtx_log.adi) into ($ADI/wsjtx.new)" 2>&1 | tee -a $tmpFile
#fi

#*--- Detect differences between current ADIF and previous one, cut the difference only
python3 $PWD/compareADIF.py $ADI/wsjtx.new $ADI/wsjtx.old > $ADI/wsjtx.adi

#*--- Rotate the reference
cat $ADI/wsjtx.adi > $ADI/wsjtx.adi.bup
cp $ADI/wsjtx.new $ADI/wsjtx.old 2>&1 > /dev/null 

#*--- Prevent execution if the ADIF file is empty

SADI=$(stat -c %s "$ADI/wsjtx.adi")
if [ "$SADI" -eq "0" ]; then
   echo "$ME: File ($WSJTZ/wsjtx.adi) empty, process terminated" 2>&1 | tee -a $tmpFile
   if [ "$QFILES" -gt "0" ]; then
      echo "$ME: Sending mail to ($TO)" 2>&1 | tee -a $tmpFile
      POST=$(cat $tmpFile)
      python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "No ADIF activity @ $SITE" $POST ""  2>&1 | logger -i -t "$ME"
   else
      echo "$ME: No pending activity"
   fi
   rm -r $LCK >&1 > /dev/null
   exit 0  
fi

#*--- Extract files and process, would process the file from WSJT-X plus any other placed in the directory with .adi extension

FILES=$(ls $ADI/*.adi)

for f in $FILES
do
  echo "$ME: Processing file ($f) $(date)" 2>&1 | tee -a $tmpFile
#*-----------------(Process LoTW using TQSL)-----------------------------------
#* Certificate of trust from ARRL must be availble for the CALL used
#*-----------------------------------------------------------------------------
  #echo "$ME: LoTW Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  #LINE=$(tqsl -c $CALL -d -u -q -a all -x -d -p $PASS  $f 2>&1)
  #echo "$LINE" 2>&1 | tee -a  $tmpFile

  echo "$ME: LoTW Upload suspended because of ARRL issues" 2>&1 | tee -a $tmpFile

#*-----------------(Process Log de Argentina (LdA)-----------------------------
  echo "\n$ME: LdA Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postLdA.py $f 2>&1 | tee -a $tmpFile 

#*-----------------(Process QRZ.com)-------------------------------------------
  echo "\n$ME: QRZ.com Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postQRZ.py $f 2>&1 | tee -a $tmpFile 

#*-----------------(Process eQSL.cc)-------------------------------------------
  echo "\n$ME: eQSL.cc Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  python3.7 $NGROK/postEQSL.py $f 2>&1 | tee -a $tmpFile 

#*-----------------[Process ClubLog]-------------------------------------------
  echo "\n$ME: ClubLog Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  $NGROK/postClubLog.sh $f 2>&1 | tee -a $tmpFile 
  echo " " 2>&1 | tee -a $tmpFile 

#*-----------------[Process HRDLog]-------------------------------------------
  echo "$ME: HRDLog Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  $NGROK/postHRDLog.sh $f 2>&1 | tee -a $tmpFile 
  echo " " 2>&1 | tee -a $tmpFile 

#*-----------------[Send QSL information]-------------------------------------------

#  echo "$ME: QSL image send file ($f) $(date)" 2>&1 | tee -a $tmpFile
#  $NGROK/sendQSL.sh $f | tee -a $tmpFile
#  echo " " 2>&1 | tee -a $tmpFile 

   echo "$ME: QSL image suspended ($f) $(date)" 2>&1 | tee -a $tmpFile

#*------------------(Archive ADI files)
  echo "$ME: Storing $f at $ADI/$MASTER $(date)" 2>&1 | tee -a $tmpFile

  cat $f 2>&1 >> $ADI/$MASTER 
  rm -r $f 2>&1 > /dev/null
  QFILES=$((QFILES+1))
done

if [ "$QFILES" -gt "0" ]; then

#*-----------------(Send mail with results)------------------------------------
   echo "$ME: Sending mail to ($TO) $(date)" 2>&1 | tee -a $tmpFile
   POST=$(cat $tmpFile)
   python /home/pi/Downloads/ngrok-stable-linux-arm/sendmail.py $TO "ADIF Upload @ $SITE" "$POST" "" 2>&1 | logger -i -t "$ME"
   cat $tmpFile 2>&1 | logger -i -t "$ME"

else
   echo "$ME: No activity files found" 2>&1 | tee -a $tmpFile
fi

#*----- final clean up ante termination

rm -r $tmpFile 2>&1 > /dev/null
rm -r $ADI/wsjtx.new 2>&1 > /dev/null
rm -r $LCK
cd $CURR
#*-----------------------------------------------[End of Script]-----------------------------------------------------
