#!/bin/sh
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

CALL=$(python getJason.py sitedata.json call)
PASS=$(python getJason.py sitedata.json lotw.pass)
f=$NGROK/LoTW.adi
tmpFile=$NGROK/LoTW.tmp

#*-----------------(Process LoTW using TQSL)-----------------------------------
#* Certificate of trust from ARRL must be availble for the CALL used
#*-----------------------------------------------------------------------------
  echo "$ME: LoTW Upload file($f) $(date) Result" 2>&1 | tee -a $tmpFile
  LINE=$(tqsl -c $CALL -d -u -q -a all -x -d -p $PASS  $f 2>&1)
  echo "$LINE" 2>&1 | tee -a  $tmpFile
  echo "$ME: LoTW Upload suspended because of ARRL issues" 2>&1 | tee -a $tmpFile
