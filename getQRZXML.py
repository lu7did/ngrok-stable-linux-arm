#!/usr/bin/python
#*--------------------------------------------------------------------------------------
#*getQRZXML
#*Access QRZ.com data using the XML interface
#*--------------------------------------------------------------------------------------
import requests
import json
from subprocess import PIPE,Popen
import sys
import dateutil
from datetime import datetime
import adif_io
import syslog
#*--------------------------------------------------------------------------------------
#*Given a XML structure return a key value
#*--------------------------------------------------------------------------------------
def getXMLTag(start,end,XMLdata):
	resp=(XMLdata.split(start)[1]).split(end)[0]
	return resp

#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python3.7', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].decode('UTF-8').replace("\n","").replace("\r","")


#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
pgm="getQRZXML"
if len(sys.argv) < 2:
   print("%s: No ADIF file to process, terminating!\n" % pgm)
   sys.exit()

adifFile = sys.argv[1]     # First argument is the adifFile to process
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")

#*-------------------------------------------------------------------------------------
#* Process QSL list
#*-------------------------------------------------------------------------------------
url = getToken("qrz.com.key")
user= getToken("qrz.com.user")
pasw= getToken("qrz.com.pasw")


#*---------------------------------------------------*
#* Access the ADIF file and extract  pseudo XML data *
#*-------------------------------------------------- *
try:
   qso, adif_header = adif_io.read_from_file(adifFile)
except Exception as ex:
   pass
   #template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
   #message = template.format(type(ex).__name__, ex.args)
   #print("ReadADIF: "+message)
   #sys.exit()

#*---------------------------------------------------*
#* Obtain QRZ.com session key                        *
#*-------------------------------------------------- *
url=url+'?username='+user+';password='+pasw+';agent=q5.0'
r = requests.get(url) 
data=r.content
QRZkey=getXMLTag(b'<Key>',b'</Key>',r.content).decode("utf-8")


#*---------------------------------------------------*
#* Process the ADIF records                          *
#*-------------------------------------------------- *
n=0
try:
	for x in qso:
		try:
			sucall=x['CALL']
		except Exception as ex:
			print("Exception with CALL")
			sucall=""
		try:
			banda=x['BAND']
		except Exception as ex:
			print("Exception with BAND")
			banda=""
		try:
			modo=x['MODE']
		except Exception as ex:
			print("Exception with MODE")
			modo=""
		try:
			micall=x['STATION_CALLSIGN']
		except Exception as ex:
			print("Exception with STATION_CALLSIGN")
			micall=""
		try:
			fecha=x['QSO_DATE']
		except Exception as ex:
			print("Exception with QSO_DATE")
			fecha=""
		try:
			hora=x['TIME_OFF']
		except Exception as ex:
			print("Exception with TIME_OFF")
			hora=""
		try:
			freq=x['FREQ']
		except Exception as ex:
			print("Exception with FREQ")
			freq=""
		try:
			rst_sent=x['RST_SENT']
		except Exception as ex:
			print("Exception with RST_SENT")
			rst_sent=""
		try:
			rst_rcvd=x['RST_RCVD']
		except Exception as ex:
			print("Exception with RST_RCVD")
			rst_rcvd=""

		#sucall=x['CALL']
		#banda=x['BAND']
		#modo=x['MODE']
		#micall=x['STATION_CALLSIGN']
		#fecha=x['QSO_DATE']
		#hora=x['TIME_OFF']
		#freq=x['FREQ']
		#rst_sent=x['RST_SENT']
		#rst_rcvd=x['RST_RCVD']


		qurl="https://xmldata.qrz.com/xml/current/?s="+QRZkey+";callsign="+sucall
		r = requests.get(qurl) 
		data=r.content

		try:
			email=getXMLTag(b'<email>',b'</email>',data).decode("utf-8")
		except:
			email=""
		if n==0:
			print("\"MYCALL\",\"RADIO\",\"DATE\",\"TIME\",\"FREQ\",\"MODE\",\"RST\",\"EMAIL\"")
			n=n+1
		print("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"" % (micall,sucall,fecha,hora,banda,modo,rst_sent,email))

except Exception as ex:
     		template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
     		message = template.format(type(ex).__name__, ex.args)
     		print(message)


sys.exit(0)

