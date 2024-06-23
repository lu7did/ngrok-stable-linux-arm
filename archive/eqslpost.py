
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* eqslpost.py
#* Request actions from eqsl.cc thru the API
#* mainly intended to implement an automated interface to upload QSL information
#*--------------------------------------------------------------------------------------------------*

import requests
import dateutil
from datetime import datetime
import sys
import json
import os
from subprocess import PIPE,Popen
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].replace("\n", "")

#*---------------------------------------------------*
#*  Access credentials                               *
#*---------------------------------------------------* 
url = getToken("eqsl_url")
user= getToken("eqsl_user")
pswd= getToken("eqsl_pswd")
#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
scriptname=  os.path.basename(sys.argv[0])
cmd = sys.argv[1]     # First argument is the command
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
i=2
s=""

while i < len(sys.argv):
  s=s+str(sys.argv[i])
  i=i+1
#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *

if cmd == "STATUS" :  # STATUS requires no further argument
   payload = {'KEY' : key, 'ACTION' : cmd}
else:
   if cmd == "INSERT" : # INSERT requires and adif formatted string
      payload = {'ADIFData': s, 'EQSL_USER' : user, 'EQSL_PSWD' : pswd}
   else:
      print(scriptname+": "+timestampStr+" Invalid request, ignored")
      sys.exit()      
x = requests.post(url, data = payload)
print(scriptname+": "+timestampStr+' eQSL Response('+x.text+')')
