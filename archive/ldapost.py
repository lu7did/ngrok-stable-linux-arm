
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* ldapost.py
#* Request actions from Log de Argentina thru the API
#* mainly intended to implement an automated interface to upload QSL information
#*--------------------------------------------------------------------------------------------------*
import requests
import os
import dateutil
from datetime import datetime
import sys
import adif_io
import json
from subprocess import PIPE,Popen
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(j):
  t = Popen(['python3.7', 'getJason.py','sitedata.json',j],stdout=PIPE)
  return t.communicate()[0].decode('UTF-8').replace("\n","").replace("\r","")
#*---------------------------------------------------*
#*  Access credentials                               *
#*---------------------------------------------------* 
url = getToken("lda_url")
usr = getToken("lda_user")
pwd = getToken("lda_key")
#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
scriptname=  os.path.basename(sys.argv[0])
cmd = sys.argv[1]       # First argument is the command
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
i=2
s=""

while i < len(sys.argv):
  s=s+str(sys.argv[i])
  i=i+1

#*---------------------------------------------------*
#* First argument is the command (INSERT)            *
#* Second argument is the ADIF line to process       *
#*---------------------------------------------------* 
#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *

if cmd == "FILE" :  # STATUS requires no further argument
   try:
     qso, adif_header = adif_io.read_from_file(s)
   except Exception as ex:
     template = scriptname+" An exception of type {0} reading file occurred. Arguments:\n{1!r}"
     message = template.format(type(ex).__name__, ex.args)
     print(message)
     sys.exit()
else:
   if cmd == "INSERT" : # INSERT requires and adif formatted string
      try:
        qso, adif_header =  adif_io.read_from_string(s)
      except TypeError:
        print(scriptname+" TypeError: Check list of indices\n\r")
        sys.exit()
      except NameError:
        print(scriptname+" NameError: Exception in line\n\r")
        sys.exit()
   else:
      print(scriptname+': '+timestampStr+' LdA process command('+cmd+') not supported')
      sys.exit()      
n=0
for x in qso:
   try:
     sucall=x['CALL']
     banda=x['BAND']
     modo=x['MODE']
     micall=x['STATION_CALLSIGN']
     fecha=x['QSO_DATE']
     hora=x['TIME_OFF']
     rst=x['RST_SENT']
     x_qslMSG="Tnx fer QSO"
#*---------------------------------------------------*
#* Create get payload based on request               *
#*-------------------------------------------------- *
     payload={'user':usr,'pass':pwd,'micall':micall,'sucall':sucall,'banda':banda,'modo':modo,'fecha':fecha,'hora':hora,'rst':rst,'x_qslMSG':x_qslMSG}
     z=requests.get(url,params=payload)
     print(scriptname+": <%d> QSO(%s) LdA Response: %s" % (n,sucall,z.text.replace("\n","").replace("\r","")))
     n=n+1
   except Exception as ex:
     template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
     message = template.format(type(ex).__name__, ex.args)
     print(scriptname+": Exception while processing record %d , type(%s) args(%s) record ignored" % (n,type(ex).__name__, ex.args))

print(scriptname+": processed %d records" % (n))
