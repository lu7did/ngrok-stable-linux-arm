#!/usr/bin/python
import subprocess
import sys
import psutil
import time
import os
from datetime import date
import datetime
import syslog
from subprocess import PIPE,Popen
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].replace("\n", "")

#*-------------------------------------------------------------------------------------
#* putLog
#*-------------------------------------------------------------------------------------
def putLog(m,printFlag):
    print m
    if printFlag:
       syslog.syslog(m)
#*-------------------------------------------------------------------------------------
#* putLog
#*-------------------------------------------------------------------------------------
def find_nth_character(str1, substr, n):
    """find the index of the nth substr in string str1""" 
    k = 0
    for index, c in enumerate(str1):
        #print index, c, n  # test
        if c == substr:
            k += 1
            if k == n:
                return index
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
flagSSH=True
flagVNC=True
flagWEB=True
today = date.today()
#*-----------------------------------------------------------------------------------------------------
#* Check if the process is already running, if not launch
#* If the process is running collect telemetry about the environment before ending
#*-----------------------------------------------------------------------------------------------------
if not checkIfProcessRunning('ngrok'):
   putLog("Start processing",True);
   os.chdir("/home/pi/Downloads/ngrok-stable-linux-arm")
   putLog("Current directory is "+os.getcwd(),True)
else:
   execProc("/home/pi/Downloads/ngrok-stable-linux-arm/setTelemetry.sh",True)
   sys.exit()

node=getToken("site")
#*-----------------------------------------------------------------------------------------------------
#* Launch ngrok process
#*-----------------------------------------------------------------------------------------------------
process = subprocess.Popen(
    ["./ngrok","start","--all","--log=stdout"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
)

#*-----------------------------------------------------------------------------------------------------
#* Process token detection just once
#*-----------------------------------------------------------------------------------------------------
now = datetime.datetime.now()
token_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/"+node+"/"+node+"_url.txt", "w")
str= node+" ngrok access URL generated "+now.strftime("%Y-%m-%d %H:%M:%S")+"\r\n"
n = token_file.write(str)
token_file.close()

for line in iter(process.stdout.readline,''):

   p=line.rstrip().find("localhost:22")
   print line.rstrip()
   if p>0 and flagSSH:
      url=line.rstrip()[p+17:]
      putLog("ngrok new SSH URL="+url,True)
      flagSSH=False
      token_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/"+node+"/"+node+"_url.txt", "a")
      str= "ssh Port("+url+")\r\n"
      n = token_file.write(str)
      c = find_nth_character(url,":",2)
      if c>0:
         cmd="-----> ssh -p "+url[c+1:]+" pi@"+url[6:c]+"\n\r"
         token_file.write(cmd)
      token_file.close()
   p=line.rstrip().find("localhost:5900")
   if p>0 and flagVNC:
      url=line.rstrip()[p+19:]
      putLog("ngrok new VNC URL="+url,True)
      flagVNC=False
      token_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/"+node+"/"+node+"_url.txt", "a")
      str= "VNC Port("+url+")\r\n"
      n = token_file.write(str)
      token_file.close()
   p=line.rstrip().find("localhost:8081")
   if p>0 and flagWEB:
      url=line.rstrip()[p+24:]
      putLog("ngrok new HTTP URL=https:"+url,True)
      flagWEB=False
      token_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/"+node+"/"+node+"_url.txt", "a")
      str= "HTTP Port(https:"+url+")\r\n"
      n = token_file.write(str)
      token_file.close()
      http_file = open("/home/pi/Downloads/ngrok-stable-linux-arm/"+node+"/"+node+".html", "w")
      n = http_file.write("<!DOCTYPE html>\n")
      n = http_file.write("<html>\n")
#      n = http_file.write("  <head>\n")
#      n = http_file.write("    <meta http-equiv=\"refresh\" content=\"2; url=\'https:"+url+"\'\" />\n")
#      n = http_file.write("  </head>\n")
      n = http_file.write("  <body>\n")
      n = http_file.write("    <p>Please follow <a href=\"https:"+url+"\">this link to access ("+node+")</a>.</p>\n")
      n = http_file.write("  </body>\n")
      n = http_file.write("</html>\n")
      http_file.close()

   if not flagVNC and not flagWEB and flagFirst:
      execProc("/home/pi/Downloads/ngrok-stable-linux-arm/rclone.sync",False)
      putLog(node+" access data updated at OneDrive",True)

      execProc("/home/pi/Downloads/ngrok-stable-linux-arm/html-upload.sh",False)
      putLog(node+"  access HTTP("+url+") updated at ftp.qsl.net",True)

      flagFirst=False
