
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* qrzpost.py
#* Request actions from qrz.com thru the API
#* mainly intended to implement an automated interface to upload QSL information
#*--------------------------------------------------------------------------------------------------*

import requests
import dateutil
from datetime import datetime
import sys
import json
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
url = getToken("qrz.com_url")
key = getToken("qrz.com_key")

#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
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
      payload = {'KEY': key, 'ACTION' : cmd, 'ADIF' : s}
   else:
      print("\n\r"+timestampStr+" Invalid request, ignored\n\r")
      sys.exit()      
x = requests.post(url, data = payload)
print("\n\r"+timestampStr+' QRZ Response('+x.text+')')
