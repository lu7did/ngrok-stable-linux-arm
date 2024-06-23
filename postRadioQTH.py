
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* postRadioQTH
#* Send form data to build a QSL card and recover a pdf file with the actual QSL card
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
              print(data)
           p=data.find("Information:")
           if p>=0:
              print(data)




#*---------------------------------------------------*
#*  Access credentials                               *
#*---------------------------------------------------* 
url = getToken("radioQTH.url")
usr = getToken("radioQTH.user")
key = getToken("radioQTH.pswd")
pgm = "postRadioQTH"
qsl = "RadioQTH"
#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
if len(sys.argv) < 8:
   print("%s: Insufficient parameters to process QSL, terminating!\n" % pgm)
   sys.exit()

QSLFile = sys.argv[1]     # First argument is the QSL background file to process
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%d-%b-%Y (%H:%M:%S.%f)")
print("\r\n%s: Processing (%s) QSL file\r\n" % (pgm,QSLFile))

QSLRadio=sys.argv[2]
QSLDate=sys.argv[3]
QSLUTC=sys.argv[4]
QSLMHz=sys.argv[5]
QSLMode=sys.argv[6]
QSLRST=sys.argv[7]
QSLMisc=sys.argv[8]
print("\r\n%s: QSL Radio(%s) Date(%s) Time UTC(%s) QRG(%s) Moe(%s) RST(%s) Misc(%s) File(%s)\r\n" % (pgm,QSLRadio,QSLDate,QSLUTC,QSLMHz,QSLMode,QSLRST,QSLMisc,QSLFile))

form_data = {'QSOCall': 'LU7DZ',
      'Callsign': 'LU7DZ',
      'FullName' : 'Dr. Pedro E. Colla',
      'Address One' : 'Jorge 1029',
      'Address Two' : '',
      'City':'Adrogue',
      'State':'OtherState',
      'OtherState':'Buenos Aires',
      'ZipCode':'1846',
      'Country':'Argentina',
      'AddressLocation':'Center',
      'SlashedZeros':'No',
      'ARRLLogo':'NoMembership',
      'ARRLLogoLocation':'Center',
      'CardsPerPage':'OneCard',
      'BoxPenColor':'Red',
      'BoxBrushColor':'Transparent',
      'Radio':'LU2EIC',
      'ContactDate':'20-Oct-2023',
      'UTC':'01:00Z',
      'MHz':'28',
      'Mode':'FT8',
      'RST':'-15dB',
      'Misc':'QSL via Bureau',
      'BothCards':'No',
      'ImageAsBackground':'No',
      'ImageLocation':'Center',
      'HighlightTextColor':'Red',
      'MainTextColor':'Black',
      'BorderColor':'Black',
      'FormTextColor':'Black',
      'PlsQslTnx':'Pls QSL Tnx',
      'ImageFile': ''
}
url=url+'/WritePdf'
#headers = {'Content-type': 'application/json', 'User-Agent':'postRadioQTH'}
headers = {'Content-type': 'application/json','enctype': 'multipart/form-data'}

sess = requests.Session()
files=[]

server = sess.post(url, headers=headers, json=form_data, files=files)
#server = requests.post(url, json=form_data,headers=headers)
output = server.text
pdf_file_name = 'pepe.pdf'
print("Status Code %s\n" % (server.status_code))

if server.status_code == 200:
# Save in current working directory
	filepath = os.path.join(os.getcwd(), pdf_file_name)
	with open(filepath, 'wb') as pdf_object:
		pdf_object.write(server.content)
		print(f'{pdf_file_name} was successfully saved!')
		sys.exit()
else:
	print(f'Uh oh! Could not download {pdf_file_name},')
	print(f'HTTP response status code: {server.status_code}')
	sys.exit()

sys.exit()


soup = BeautifulSoup(server.text, 'html.parser')
 
# Find all hyperlinks present on webpage
links = soup.find_all('a')
 
i = 0
 
# From all links check for pdf link and
# if present download file
for link in links:
    if ('.pdf' in link.get('href', [])):
        i += 1
        print("Downloading file: ", i)
 
        # Get response object for link
        response = requests.get(link.get('href'))
 
        # Write content in pdf file
        pdf = open("pdf"+str(i)+".pdf", 'wb')
        pdf.write(server.content)
        pdf.close()
        print("File ", i, " downloaded")
 
print("All PDF files downloaded")








sys.exit()

#parser=MyHTMLParser()


#*---------------------------------------------------*
#* Access the ADIF file and extract  pseudo XML data *
#*-------------------------------------------------- *
try:
   qso, adif_header = adif_io.read_from_file(adifFile)
except Exception as ex:
   template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
   message = template.format(type(ex).__name__, ex.args)
   print("ReadADIF: "+message)
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
       #print("QSO_DATE_OFF: "+message)
       syslog.syslog(syslog.LOG_ERR, "QSO_DATE_OFF: "+message)
     try:
       time_on=x['TIME_ON']
       s=s+("<time_on:%d>%s " % (len(time_on),time_on))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "TIME_ON: "+message)
       #print("TIME_ON: "+message)

        
     try:
       grid=x['GRIDSQUARE']
       s=s+("<gridsquare:%d>%s " % (len(grid),grid))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "GRIDSQUARE: "+message)
       #print("GRIDSQUARE: "+message)


     try:
       tx_pwr=x['TX_PWR']
       s=s+("<tx_pwr:%d>%s " % (len(tx_pwr),tx_pwr))
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "TX_PWR: "+message)
       #print("TX_PWR: "+message)

     try:
       x_qslMSG=x['x_qslMSG']
     except Exception as ex:
       template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
       message = template.format(type(ex).__name__, ex.args)
       syslog.syslog(syslog.LOG_ERR, "qsl_MSG: "+message)
       #print(message)
       x_qslMSG="Tnx fer QSO"
     s=s+("<comment:%d>%s " % (len(x_qslMSG),x_qslMSG))
     s=s+" <eor>\n"

#*---------------------------------------------------*
#* Create post payload based on request              *
#*-------------------------------------------------- *
     payload = {'ADIFData': s, 'EQSL_USER' : usr, 'EQSL_PSWD' : key}
     z = requests.post(url, data = payload)
     print("\n\r<%d> QSO(%s) Mode(%s) Band(%s) %s Response\n\r" % (n,sucall,modo,banda,qsl))
     parser.feed(z.text)
     print("\n\r")
     n=n+1
except Exception as ex:
     template = "An exception of type {0} reading file occurred. Arguments:\n{1!r}"
     message = template.format(type(ex).__name__, ex.args)
     print(message)

print("\n\r%s: processed %d records\n\r" % (pgm,n))
sys.exit()

