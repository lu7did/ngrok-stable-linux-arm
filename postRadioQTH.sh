#!/bin/sh
#!/bin/sh
#*--------------------------------------------------------------------------------------------*
#* Este proceso revisa si WSJT-Z está corriendo en la máquina y de no estarlo lo relanza      *
#* se tiene en cuenta el caso de una terminación  anormal que deje zombie un proceso JT9      *
#*--------------------------------------------------------------------------------------------*
getPID() {
  PID=$(pidof $1)
  echo $PID
}
#*---
getUSER() {
  if [ `pidof $1 | wc -l` -ne 0 ]; then
     USER=$(ps -o user -p `pidof $1` | grep -v "USER")
     echo "$USER"
  else
     echo ""
  fi  
}

#*----------------------------------------------------------------------*
#* Main program                                                         *
#*----------------------------------------------------------------------*
clear
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
ADI=$SCRIPT_PATH/ADIF
LCK=$ADI/"$ME.lck"
USB="/dev/ttyUSB0"
tmpFile=$ADI/"$ME.tmp"
CTLFILE=$COUNTDOWN.txt
QFILES=0

#*--- Center execution on the directory where the script is located

cd "$NGROK"

if test -f $LCK; then
   echo "$ME is locked, execution terminated" 2>&1 | logger -i -t "$ME"
   exit
fi


#*--- Processing arguments

QSO_RADIO=$1
QSO_DATE=$2
QSO_UTC=$3
QSO_MHZ=$4
QSO_MODE=$5
QSO_RST=$6
QSO_MISC=$7


if [ -z "$QSO_RADIO" ]; then
   echo "$ME: Falta argumento RADIO" 2>&1 | logger -i -t "$ME"
   exit 0
fi

if [ -z "$QSO_DATE" ]; then
   echo "$ME: Falta argumento DATE" 2>&1 | logger -i -t "$ME"
   exit 0
fi

if [ -z "$QSO_UTC" ]; then
   echo "$ME: Falta argumento UTC" 2>&1 | logger -i -t "$ME"
   exit 0
fi

if [ -z "$QSO_MHZ" ]; then
   echo "$ME: Falta argumento MHZ" 2>&1 | logger -i -t "$ME"
   exit 0
fi

if [ -z "$QSO_MODE" ]; then
   echo "$ME: Falta argumento MODE" 2>&1 | logger -i -t "$ME"
   exit 0
fi

if [ -z "$QSO_RST" ]; then
   echo "$ME: Falta argumento RST" 2>&1 | logger -i -t "$ME"
   exit 0
fi


echo "$ME: RADIO($1) Date($2-$3) Freq($4) Mode($5) RST($6) MSG($7)" 2>&1 | logger -i -t "$ME"

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)
IMAGE=$(python getJason.py sitedata.json image)

NAME=$(python getJason.py sitedata.json RadioQTH.name)
URL=$(python getJason.py sitedata.json RadioQTH.url)
NAME=$(python getJason.py sitedata.json RadioQTH.name)
ADDRESS=$(python getJason.py sitedata.json RadioQTH.address)
CITY=$(python getJason.py sitedata.json RadioQTH.city)
STATE=$(python getJason.py sitedata.json RadioQTH.state)
ZIP=$(python getJason.py sitedata.json RadioQTH.zip)
COUNTRY=$(python getJason.py sitedata.json RadioQTH.country)
GRID=$(python getJason.py sitedata.json RadioQTH.grid)

#*---- Format and send QSL creation request to RadioQTH

curl -k --location --request POST "https://www.radioqth.net/qslcards/WritePdf" \
--form 'CALLSIGN='"$CALL" \
--form 'FullName='"$NAME" \
--form 'QSOCall='"$CALL" \
--form 'AddressOne='"$ADDRESS" \
--form 'ADDRESSTWO=' \
--form 'CITY='"$CITY $STATE ($GRID)" \
--form 'STATE=OtherState' \
--form 'ZIPCODE='"$ZIP" \
--form 'COUNTRY='"$COUNTRY" \
--form 'ADDRESSLOCATION=Center' \
--form 'SLASHEDZEROS=No' \
--form 'ARRLLOGO=NoMembership' \
--form 'ARRLLOGOLOCATION=Center' \
--form 'CARDSPERPAGE=OneCard' \
--form 'BOXPENCOLOR=Red' \
--form 'BOXBRUSHCOLOR=Transparent' \
--form 'RADIO='"$QSO_RADIO" \
--form 'CONTACTDATE='"$QSO_DATE" \
--form 'UTC='"$QSO_UTC" \
--form 'MHZ='"$QSO_MHZ" \
--form 'MODE='"$QSO_MODE" \
--form 'RST='"$QSO_RST" \
--form 'MISC='"$QSO_MISC" \
--form 'BOTHCARDS=No' \
--form 'IMAGEASBACKGROUND=Yes' \
--form 'IMAGELOCATION=Center' \
--form 'HIGHLIGHTTEXTCOLOR=Red' \
--form 'MAINTEXTCOLOR=Black' \
--form 'BORDERCOLOR=Black' \
--form 'FORMTEXTCOLOR=Black' \
--form 'PLSQSLTNX=QSL PSE' \
--form 'ImageFile=@'"./$IMAGE"


