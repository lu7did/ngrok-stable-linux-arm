#!/bin/bash
#
# BASH script for quickly uploading new QSLs to:
# ARRL Logbook of the World, eQSL.cc and ClubLog.org
#
# Copyright 2020, Dave Slotter, W3DJS
#
#*--- Execution environment

SCRIPT_PATH=$(dirname "$0")
if [ "$SCRIPT_PATH" = "." ]; then
   SCRIPT_PATH=$(pwd)
fi

SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$(echo $SCRIPT_NAME | cut -f 1 -d ".")


ADIF_FILE="$1"

#*--- Retrieve site specific keys and parameters
CALLSIGN=$(python getJason.py sitedata.json call)
CLUBLOG_EMAIL=$(python getJason.py sitedata.json clublog.id)
CLUBLOG_PSWD=$(python getJason.py sitedata.json clublog.pass)
CLUBLOG_API=$(python getJason.py sitedata.json clublog.api)

#
# Read https://clublog.freshdesk.com/support/solutions/articles/54910-api-keys
# on how to get a ClubLog API Key
#

if [ ! -x /usr/bin/curl ]; then
  echo "$ME: CURL is required. Please install it."
  exit 1
fi

if [ ! -f "${ADIF_FILE}" ]; then
  echo "$ME: Cannot locate ADIF Logfile: ${ADIF_FILE}."
  exit 1
fi


# Upload to ClubLog
echo -e "$ME: Uploading to ClubLog..."
RESULT=$(curl -s -k  -F "email=${CLUBLOG_EMAIL}" -F "password=${CLUBLOG_PSWD}" -F "callsign=${CALLSIGN}" -F "api=${CLUBLOG_API}" -F "file=@${ADIF_FILE}" https://clublog.org/putlogs.php)
echo "$ME: $RESULT\n"
LINES=$(cat $ADIF_FILE | grep "<eor>" | wc -l)
echo "$ME: Records processed $LINES"


