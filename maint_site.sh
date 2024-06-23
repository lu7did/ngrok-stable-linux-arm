#!/bin/sh
#*----------------------------------------------------------------------------------------------------------
#* Maintenance routine
#*----------------------------------------------------------------------------------------------------------
#*---- Retrieve execution environment
DIR=$1
CURR=$(pwd)
PWD=$(dirname $0)
chdir $PWD
SITE=$(python getJason.py sitedata.json site)
cat /var/log/syslog | grep "setngrok.py: T(" > $(pwd)/$SITE/logs/$SITE_telemetry_$(date +"%FT%H%M").log 2>&1  | logger -i -t "$SITE.TLM"
./cleanUp.sh
./rclone.sync
echo "Telemetry Log cycling and backup" 2>&1  | logger -i -t "SITE.TLM"
