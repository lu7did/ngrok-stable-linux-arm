
#!/usr/bin/python
import subprocess
import sys
import psutil
import time
import os
from datetime import date
import datetime
import syslog
#*-------------------------------------------------------------------------------------
#* putLog
#*-------------------------------------------------------------------------------------
def putLog(m,printFlag):
    print m
    if printFlag:
       syslog.syslog(m)
#*-------------------------------------------------------------------------------------
#* Execute a process and return result with optional logging
#*-------------------------------------------------------------------------------------
def execProc(procName,printFlag):
   p = subprocess.Popen(procName, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
   t = p.stdout.read()
   putLog(t,printFlag);
#*-------------------------------------------------------------------------------------
#* Verify if process is running
#*-------------------------------------------------------------------------------------
def checkIfProcessRunning(processName):
    '''
    Check if there is any running process that contains the given name processName.
    '''
    #Iterate over the all the running process
    for proc in psutil.process_iter():
        try:
            # Check if process name contains the given name string.
            if processName.lower() in proc.name().lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False;

#*-----------------------------------------------------------------------------------------------------
#* Program initialization
#*-----------------------------------------------------------------------------------------------------
flagFirst=True
httpFirst=True
upLoad=False
today = date.today()
#*-----------------------------------------------------------------------------------------------------
#* Check if the process is already running, if not launch
#* If the process is running collect telemetry about the environment before ending
#*-----------------------------------------------------------------------------------------------------
   execProc("/home/pi/Downloads/ngrok-stable-linux-arm/setvnc.sh",True)
   sys.exit()

#*-----------------------------------------------------------------------------------------------------
#* Launch ngrok process (all tunnels enabled)
#*-----------------------------------------------------------------------------------------------------
process = subprocess.Popen(
    ["./ngrok","start","-all","-log=stdout"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
)

#*-----------------------------------------------------------------------------------------------------
#* Process token detection just once
#*-----------------------------------------------------------------------------------------------------
for line in iter(process.stdout.readline,''):
   print line.rstrip()
   p=line.rstrip().find("tcp:");
   if p>0 and flagFirst:
      url=line.rstrip()[p+6:]
      now = datetime.datetime.now()
      putLog("VNC Tunnel("+url+")",True)
      token_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/tucSPA/tucSPA_url.txt", "w")
      str= "tucSPA ngrok access URL generated\r\n"+now.strftime("%Y-%m-%d %H:%M:%S")+" URL tcp://"+url+"\r\n"
      n = token_file.write(str)
      token_file.close()
      flagFirst=False


   s=line.rstrip().find("https:")
   if s>0 and httpFirst:
      url=line.rstrip()[s:]
      putLog("HTTP Tunnel("+url+")",True)
      http_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/tucSPA/tucSPA.html", "w")
      n = http_file.write("<!DOCTYPE html>\n")
      n = http_file.write("<html>\n")
      n = http_file.write("  <head>\n")
      n = http_file.write("    <meta http-equiv=\"refresh\" content=\"2; url=\'"+url+"\'\" />\n")
      n = http_file.write("  </head>\n")
      n = http_file.write("  <body>\n")
      n = http_file.write("    <p>Please follow <a href=\""+url+"\">this link</a>.</p>\n")
      n = http_file.write("  </body>\n")
      n = http_file.write("</html>\n")
      http_file.close()
      httpFirst=False;

   if not httpFirst and not flagFirst and not upLoad:
      execProc("/home/pi/Downloads/ngrok-stable-linux-arm/rclone.sync",False)
      putLog("tucSPA access HTTP("+url+") updated at OneDrive",True)
      execProc("/home/pi/Downloads/ngrok-stable-linux-arm/html-upload.sh",False)
      putLog("tucSPA access HTTP("+url+") updated at ftp.qsl.net",True)
      upLoad=True
      
