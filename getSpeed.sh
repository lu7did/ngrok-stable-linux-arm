#!/bin/sh

SPEEDTEST="/home/pi/Downloads/speedtest-cli"
rm -r $SPEEDTEST/speedtest.tmp 2> /dev/null
python $SPEEDTEST/speedtest.py 2>&1  > $SPEEDTEST/speedtest.tmp 

cat $SPEEDTEST/speedtest.tmp
UP=$(cat $SPEEDTEST/speedtest.tmp   | grep "Upload: "   | cut -f2- -d" " )
DOWN=$(cat $SPEEDTEST/speedtest.tmp | grep "Download: " | cut -f2- -d" " )
HOST=$(cat $SPEEDTEST/speedtest.tmp | grep "Hosted " | cut -f2- -d":" )
echo "$DOWN-$UP-$HOST"

