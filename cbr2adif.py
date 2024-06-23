#*-------------------------------------------------------------------------------------------------------------------
#* cbr2adif
#* Converts a Cabrillo file (.cbr) into an ADIF file (.adi)
#* Converted file is listed thru standard output
#*
#* (c) Dr. Pedro E. Colla LU7DZ 2023
#*-------------------------------------------------------------------------------------------------------------------
import requests
import os
import dateutil
from datetime import datetime
import sys
import json
from subprocess import PIPE,Popen
import  adif_io
import syslog

#*-------------------------------------------------------------
#* Parse a space delimited file into individual tokens
#*-------------------------------------------------------------
def read_by_tokens(fileobj):
    for line in fileobj:
        for token in line.split():
            yield token

#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
#*                                              Main Program                                                        *
#*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=

#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
if len(sys.argv) < 2:
   print("%s: No ADIF file to process, terminating!\n" % pgm)
   sys.exit()
scriptname=  os.path.basename(sys.argv[0])
callsign= sys.argv[1]
cbrFile = sys.argv[2]     # First argument is the adifFile to process
dateTimeObj = datetime.now()
timestampStr = dateTimeObj.strftime("%Y%m%d %H%M")


#filename="ARRLDXCW2023_LT7D.cbr"

line=''
q=1
band="10m"
#*-----  Create and process the header
mycall=callsign
programid=scriptname
programversion="1.0.1"
programdate=timestampStr
print("ADIF Export")
print("<adif_ver:5>3.1.1")
print("<created_timestamp:%d>%s " % (len(programdate),programdate))
print("<programid:%d>%s" % (len(programid),programid))
print("<programversion:%d>%s" % (len(programversion),programversion))
print("<eoh>")

#*-------- Parse Cabrillo and create ADIF files

with open(cbrFile) as f:
	for token in read_by_tokens(f):
	
		if token == "QSO:":
			if to != "CONTEST:":
				datez=datez.replace('-', '')
				print("<call:%d>%s <mode:%d>%s <rst_sent:%d>%s <rst_rcvd:%d>%s <qso_date:%d>%s <time_on:%d>%s <qso_date_off:%d>%s <time_off:%d>%s <band:%d>%s <freq:%d>%s <station_callsign:%d>%s <eor>" \
				% \
				( \
				len(to),to, \
				len(mode),mode, \
				len(rsts),rsts, \
				len(rstr),rstr, \
				len(datez),datez, \
				len(timez),timez, \
				len(datez),datez, \
				len(timez),timez, \
				len(band),band, \
				len(freq),freq, \
				len(fm),fm))
				q=1			
				freq = ""
				mode = ""
				datez = ""
				timez = ""
				fm = ""
				rsts = ""
				qtcs = ""
				to = ""
				rstr = ""
				qtcr = ""
			else:
				q=1
		else:
				if q==1:
					freq = token
					q=q+1
				elif q == 2:
					mode=token
					q=q+1
				elif q == 3:
					datez=token
					q=q+1
				elif q == 4:
					timez=token
					q=q+1
				elif q == 5:
					fm=token
					q=q+1
				elif q == 6:
					rsts=token
					q=q+1
				elif q == 7:
					qtcs=token
					q=q+1
				elif q == 8:
					to=token
					q=q+1
				elif q == 9:
					rstr=token
					q=q+1
				elif q == 10:
					qtcr=token
					q=q+1
				else:
					st=token
					q=q+1
