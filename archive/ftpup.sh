#!/bin/sh
FTPSITE="ftp.qsl.net"
USERID="lu7did"
PASSWD="cbn08sh7"
curl -T moveQueue.sh ftp://$FTPSITE --user $USERID:$PASSWD

