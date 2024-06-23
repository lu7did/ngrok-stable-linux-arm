#!/bin/sh
#!/bin/sh
#*--------------------------------------------------------------------------------------------*
#* Este proceso revisa si WSJT-Z está corriendo en la máquina y de no estarlo lo relanza      *
#* se tiene en cuenta el caso de una terminación  anormal que deje zombie un proceso JT9      *
#*--------------------------------------------------------------------------------------------*
#*----------------------------------------------------------------------*
#*getADIF
#*Extract a token value from an ADIF stream
#*----------------------------------------------------------------------*
getADIF() {

text="$1"
arg1="$2"

token="${text#*${arg1}}"    ## trim through $ssa from the front (left)
echo $(echo "$token" | cut -f2 -d">" | cut -f1 -d"<" | cut -f1 -d" ")


   
}
postLog() {
   echo "$1" 2>&1 | logger -i -t "$ME"
   echo "$1"

}
#*----------------------------------------------------------------------*
#* Main program                                                         *
#*----------------------------------------------------------------------*
export DISPLAY=:0.0

#*--- Execution environment

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")

PWD=$(pwd)
WSJTZ="wsjtx"
NGROK="$SCRIPT_PATH"
ADI="$NGROK/ADIF"
LCK=$ADI/"$ME.lck"
QFILES=0

#*--- Center execution on the directory where the script is located

cd "$NGROK"

if test -f $LCK; then
   postLog "$ME is locked, execution terminated $(date)"
   exit
fi


#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)

#*---- Format and send QSL creation request to RadioQTH

HRDLOG=$(python getJason.py sitedata.json HRDLog.url)
CALL=$(python getJason.py sitedata.json HRDLog.call)
APP=$(python getJason.py sitedata.json HRDLog.app)
CODE=$(python getJason.py sitedata.json HRDLog.token)


tmpFile=$ADI/$ME.tmp 
logFile=$ADI/$ME.log
adiFile=$ADI/$ME.txt

rm -r $tmpFile 2>&1 > /dev/null
rm -r $logFile 2>&1 > /dev/null
rm -r $adiFile 2>&1 > /dev/null

touch $tmpFile
touch $logFile
touch $adiFile
touch $LCK

postLog "$ME: Running HRDLog posting script ($ME) file ($1) $(date)"
QTOT=0
QFAIL=0

#*---- Filter headers from the ADIF file
cat $1 | grep "<call" > $adiFile

#*--- Loop thru the ADIF file recovering the QSO parameters

while read -r f; 
do 

RADIO=$(getADIF "$f" "call")
MODE=$(getADIF "$f" "mode")
BAND=$(getADIF "$f" "band")

#*---- Post data
x=$(echo "  "$f)

curl -k -s --location --request POST "$HRDLOG" \
--form 'Callsign='"$CALL" \
--form 'ADIFData='"$x" \
--form 'Code='"$CODE" \
--form 'App='"$APP"  > $tmpFile

QSO=$(cat $tmpFile | grep "<insert>" | cut -f2 -d">" | cut -f1 -d"<")
ID=$(cat $tmpFile | grep "<id>" | cut -f2 -d">" | cut -f1 -d"<")

if [ "$QSO" -ne "1" ]; then
   QFAIL=$((QFAIL+1))
fi
QTOT=$((QTOT+1))

echo "$ME: Processed RADIO($RADIO) MODE($MODE) BAND($BAND) QSO($QSO) records <$ID>" 2>&1 >> $logFile

done < $adiFile
QOK=$((QTOT-QFAIL))

echo "$ME: Processed OK($QOK) Fail($QFAIL) Total de Registros($QTOT)" 2>&1 >> $logFile 
echo "$ME: Processed OK($QOK) Fail($QFAIL) Total de Registros($QTOT)" 2>&1 | logger -i -t $ME

#*--- Print information and terminate 

cat $logFile
rm -r $LCK




