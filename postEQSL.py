
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* postEQSL
#* Request actions from eqsl.cc thru the API
#* mainly intended to implement an automated interface to upload QSL information
#*--------------------------------------------------------------------------------------------------*

import requests
import dateutil
from datetime import datetime
import sys
import json
from subprocess import PIPE,Popen
import adif_io
from html.parser import HTMLParser
import syslog
import os
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].decode('UTF-8').replace("\n","").replace("\r","")

#*-------------------------------------------------------------------------------------
#* removelines, strip \r\n from a string
#*-------------------------------------------------------------------------------------
def removelines(value):
    return value.replace('\n','')

class MyHTMLParser(HTMLParser):
    def handle_starttag(self, tag, attrs):
        z=tag.rstrip().find("body")
        if z>=0:
           bFirst=False

    def handle_endtag(self, tag):
        z=tag.rstrip().find("body")
        if z>=0:
           bFirst=True

    def handle_data(self, data):
        data=removelines(data)
        data=data.rstrip()
        if data:
           p=data.find("Warning:")
           if p>=0:
              return data.replace('\n','').replace('\r','')
           p=data.find("Information:")
           if p>=0:
              return data.replace('\n','').replace('\r','')

#*---------------------------------------------------*
#*  Access credentials                               *
#*---------------------------------------------------* 
url = getToken("eqsl_url")
usr = getToken("eqsl_user")
key = getToken("eqsl_pswd")
pgm = "postEQSL"
qsl = "eQSL"
#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
if len(sys.argv) < 2:
   print("%s: No ADIF file to process, terminating!\n" % pgm)
   sys.exit()

scriptname=  os.path.basename(sys.argv[0])
adifFile = sys.argv[1]     # First argument is the adifFile to process
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
print("%s: Processing (%s) ADIF file" % (scriptname,adifFile))

parser=MyHTMLParser()

#*---------------------------------------------------*
#* Access the ADIF file and extract  pseudo XML data *
#*-------------------------------------------------- *
try:
   qso, adif_header = adif_io.read_from_file(adifFile)
except Exception as ex:
   template = scriptname+": An exception of type {0} reading file occurred. Arguments:\n{1!r}"
   message = template.format(type(ex).__name__, ex.args)
   print(scriptname+": ReadADIF: "+message)
   sys.exit()

#*---------------------------------------------------*
#* Process the ADIF records                          *
#*-------------------------------------------------- *
n=0
bFirst=True 
msg=''
try:
   for x in qso:
     sucall=x['CALL']
     banda=x['BAND']
     modo=x['MODE']
     micall=x['STATION_CALLSIGN']
     fecha=x['QSO_DATE']
     hora=x['TIME_OFF']
     freq=x['FREQ']
     rst_sent=x['RST_SENT']
     rst_rcvd=x['RST_RCVD']
#*---------------------------------------------------*
#* Create get payload based on request               *
#*-------------------------------------------------- *

     s=""
     s=s+("<call:%d>%s " % (len(sucall),sucall))
     s=s+("<mode:%d>%s " % (len(modo),modo))
     s=s+("<rst_sent:%d>%s " % (len(rst_sent),rst_sent))
     s=s+("<rst_rcvd:%d>%s " % (len(rst_rcvd),rst_rcvd))
     s=s+("<qso_date:%d>%s " % (len(fecha),fecha))
     s=s+("<time_off:%d>%s " % (len(hora),hora))
     s=s+("<band:%d>%s " % (len(banda),banda))
     s=s+("<freq:%d>%s " % (len(freq),freq))
     s=s+("<station_callsign:%d>%s " % (len(micall),micall))

     try:
       qso_date_off=x['QSO_DATE_OFF']
       s=s+("<qso_date_off:%d>%s " % (len(qso_date_off),qso_date_off))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "QSO_DATE_OFF: "+message)
     try:
       time_on=x['TIME_ON']
       s=s+("<time_on:%d>%s " % (len(time_on),time_on))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "TIME_ON: "+message)

        
     try:
       grid=x['GRIDSQUARE']
       s=s+("<gridsquare:%d>%s " % (len(grid),grid))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "GRIDSQUARE: "+message)


     try:
       tx_pwr=x['TX_PWR']
       s=s+("<tx_pwr:%d>%s " % (len(tx_pwr),tx_pwr))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "TX_PWR: "+message)

     try:
       x_qslMSG=x['x_qslMSG']
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "qsl_MSG: "+message)
       x_qslMSG="Tnx fer QSO"
     s=s+("<comment:%d>%s " % (len(x_qslMSG),x_qslMSG))
     s=s+" <eor>\n"

#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *
     payload = {'ADIFData': s, 'EQSL_USER' : usr, 'EQSL_PSWD' : key}
     z = requests.post(url, data = payload)
     print("%s: <%d> QSO(%s) Mode(%s) Band(%s) %s Response %s" % (scriptname,n,sucall,modo,banda,qsl,parser.feed(z.text)))
     n=n+1
except Exception as ex:
     template = scriptname+": An exception of type {0} reading file occurred. Arguments:\n{1!r}"
     message = template.format(type(ex).__name__, ex.args)
     print(message)

print("%s: processed %d records\n" % (scriptname,n))
sys.exit()

