#!/bin/sh
#*-----------------------------------------------------------------------*
#* processIgnoreList                                                     *
#* Process all ADIF files (.ADI) on a given directory and extract        *
#* stations worked more than MAX times, generate a permIgnoreList parm   *
#* on the WSJT-X.ini file to exclude them from automatic contacts        *
#*-----------------------------------------------------------------------*
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD
export DISPLAY=:0.0
CONFIG=$2

#*--- Temporary files
ignoreFile="ignoreList"
tmpINI="tmpINI"
splitFile="splitFile"
tmpFile="tmpFile"
blockFile="/home/pi/Downloads/ngrok-stable-linux-arm/blockedList.txt"

#*--- Retrieve site specific keys and parameters
TO=$(python getJason.py sitedata.json  mail)
SITE=$(python getJason.py sitedata.json site)
CALL=$(python getJason.py sitedata.json call)
MAX=$(python getJason.py sitedata.json max)
BANDS=$(python getJason.py sitedata.json bands)

#*--- Get directory to scan for .ADI files (default to current if none informed)
if [ "$DIR" = "" ]; then
   DIR="."
fi

FILES=$(ls $DIR/*.log)

#*---- Process sequentially all log files
for b in $BANDS
do
    s=$(echo $splitFile"_"$b)
    rm -r ./$s 2>&1 > /dev/null
    touch ./$s 2>&1 > /dev/null

    for f in $FILES
    do
       python3.7 splitband.py $b $f | grep "$b" | cut -d " " -f 1 > ./$tmpFile
       z=$(cat $tmpFile | wc -l)
       echo "processIgnoreList.sh: extracting log($f) band($b) records($z)"
       cat ./$tmpFile >> ./$s
       rm -r $tmpFile 2>&1 >/dev/null
       touch $tmpFile 2>&1 >/dev/null
    done
    if [ -s ./$s ]; then
        # The file is not-empty.
        c=$(cat ./$s | wc -l)
        echo "processIgnoreList.sh: processing INI($CONFIG/"WSJT-X_"$b".new" for band($b) records($c)"
        i=$(echo $ignoreFile"_"$b)
        cat ./$s | sort | uniq -c | sort > $i
        INI=$(python3.7 countIgnore.py $MAX $i $CONFIG/"WSJT-X.ini" $CONFIG/"WSJT-X_"$b".new" $blockFile)
        cp $CONFIG/"WSJT-X_"$b".new" $CONFIG/"WSJT-X.ini" 
    fi
done
