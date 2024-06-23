#!/bin/bash
#*------------------------------------------------------------------------------------------------------*
#* postClubLog
#* Post an ADIF file given as a parameter to ClubLog
#* Template provided by ClubLog
#*
#*   API='282eb04f8c5652a77dd903bd290388a5b33c1c1d'
#*   PASS='lu7did00'
#*   CALL='LU7DZ'
#*   FILE='/home/pi/Downloads/ngrok-stable-linux-arm/clublog.adi'
#*   EMAIL='pedro.colla@gmail.com'
#*   curl -v -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode adif@$FILE -d email=$EMAIL -d callsign=$CALL -d password=$PASS -d api=$API https://clublog.org/realtime.php
#*------------------------------------------------------------------------------------------------------*
FILE=$1

#*--- Retrieve site specific keys and parameters
CALL=$(python getJason.py sitedata.json call)
EMAIL=$(python getJason.py sitedata.json clublog.id)
PASS=$(python getJason.py sitedata.json clublog.pass)
API=$(python getJason.py sitedata.json clublog.api)

#*--- Execute ClubLog POST Form
echo "Posting ClubLog ID($EMAIL) PASS($PASS) CALL($CALL) API($API) FILE($FILE)" 
echo " "
echo 'curl -v -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode -d @$FILE -d enctype=multipart/form-data -d email=$EMAIL -d callsign=$CALL -d password=$PASS -d api=$API https://clublog.org/putlogs.php'
curl -v -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode adif@test.adi -file=test.adi -d enctype='multipart/form-data' -d email=$EMAIL -d callsign=$CALL -d password=$PASS -d api=$API https://clublog.org/putlogs.php
#*--- End of Script
