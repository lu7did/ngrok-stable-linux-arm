
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* splitband.py
#* Split the ADIF file by band
#*--------------------------------------------------------------------------------------------------*

import requests
import dateutil
from datetime import datetime
import sys
import adif_io

#*---------------------------------------------------*
#* Process arguments                                 *
#*---------------------------------------------------*
inBand = sys.argv[1]
inFile = sys.argv[2]
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
try:
  qsos_raw, adif_header = adif_io.read_from_file(inFile)
  print ("Processing log %s\n" % (inFile))
except:
  print ("Exception while processing log %s, aborted\n" % (inFile))
  sys.exit(0)

qso=0
for x in qsos_raw:
  sucall=x['CALL']
  banda=x['BAND']
  modo=x['MODE']
#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *
  print("%s %s %s" % (sucall,banda,modo))
  #payload={'user':user,'pass':pswd,'micall':micall,'sucall':sucall,'banda':banda,'modo':modo,'fecha':fecha,'hora':hora,'rst':rst,'x_qslMSG':x_qslMSG}
  #z=requests.get(url,params=payload)
  #print("LdA processed QSO(%s) Band(%s) Mode(%s) Date(%s) Time(%s) RST(%s) Response(%s)" % (sucall,banda,modo,fecha,hora,rst,z.text.strip()))
  qso=qso+1
print("Processed %d QSO\n" % (qso));
