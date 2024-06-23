#!/bin/sh
## Delete files from ftp server
HOST="ftp.qsl.net"
USER="lu7did"
PWD="cbn08sh7"
YM=$(date +'%Y%m')
YM=$(( $YM-3 ))
echo YearMonth $YM
ftp -p -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PWD
prompt
cd /tucSPA/images
delete $1
quit
END_SCRIPT
exit 0
