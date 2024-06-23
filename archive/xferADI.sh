#!/bin/sh
echo "Transfering ADI export from root to local"
clear
CURR=$(pwd)
PWD=$(dirname $0)
ADI=/root/.local/share/WSJT-X/wsjtx_log.adi
LCK=$PWD/ADIF/processQSL.lck
echo "Current($CURR) PWD($PWD) ADIF($ADI)\n"
TMP=wsjtx_log.adi.root
cd $PWD

sudo cp $ADI $TMP
cat wsjtx_log.adi.root >> /home/pi/.local/share/WSJT-X/wsjtx_log.adi
sudo rm -r wsjtx_log.adi.root

