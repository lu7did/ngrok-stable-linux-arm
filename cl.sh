#!/bin/bash


API='282eb04f8c5652a77dd903bd290388a5b33c1c1d'
PASS='lu7did00'
CALL='LU7DZ'
FILE='/home/pi/Downloads/ngrok-stable-linux-arm/clublog.adi'
EMAIL='pedro.colla@gmail.com'


curl -v -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode adif@$FILE -d email=$EMAIL -d callsign=$CALL -d password=$PASS -d api=$API https://clublog.org/realtime.php

