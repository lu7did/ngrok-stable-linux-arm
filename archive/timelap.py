#!/usr/bin/python
import os
import time
import sys

inicio = 0
final = 20

print ("Inicio de capturas.")
while inicio < final:   
    print ("Captura.")
    os.system("fswebcam -i 0 -d /dev/video0 -r 640x480 -q --title @raspberry  /home/pi/webcam/snap/%d%m%y_%H%M%S.jpg")
    inicio = inicio + 1
    time.sleep(10)

print ("Se han capturado las 20 imagenes. Estan en ./snap.")
sys.exit()			
