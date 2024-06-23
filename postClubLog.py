
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* postClubLog.py
#* Request actions from ClubLog thru the API
#* mainly intended to implement an automated interface to upload QSL information
#*--------------------------------------------------------------------------------------------------*
import requests
import dateutil
from datetime import datetime
import sys
import json
from subprocess import PIPE,Popen
import  adif_io
import syslog
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python3.7', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].decode('UTF-8').replace("\n","").replace("\r","")
#*---------------------------------------------------*
#*  Access credentials                               *
#*---------------------------------------------------*
email=getToken("clublog.id")
pwd=getToken("clublog.pass")
api=getToken("clublog.api")
call=getToken("call")
url='https://clublog.org/putlogs.php/post' 
#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
if len(sys.argv) < 2:
   print("No ADIF file to process, terminating!\n")
   sys.exit()

adifFile = sys.argv[1]     # First argument is the adifFile to process
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
print("\n\rProcessing (%s) ADIF file\n\r" % (adifFile))


#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *
try:

	headers={'Content-Type' : 'application/x-www-form-urlencoded','enctype' : 'multipart/form-data','email':email,'callsign':call,'password':pwd,'api':api}
	print("Headers %s\nFile %s" % (headers,adifFile))
	with open(adifFile, 'rb') as f:
		file_dict={"file":f}
		z = requests.post(url,headers=headers,files=file_dict)
		#z=requests.post(url,headers=headers,data=adifFile)
		print("\n ClubLog Response\n\r %s" % (z.text))
    
except Exception as ex:
	template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
	message = template.format(type(ex).__name__, ex.args)
	print(message)

sys.exit()





