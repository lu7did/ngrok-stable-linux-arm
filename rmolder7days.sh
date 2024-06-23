#!/bin/sh
cd /home/pi/Downloads/ngrok-stable-linux-arm
find ./tucSPA/cam  -type f -mtime +7 -name '*' -execdir rm -- '{}' \;
find ./tucSPA/logs  -type f -mtime +7 -name '*' -execdir rm -- '{}' \;
