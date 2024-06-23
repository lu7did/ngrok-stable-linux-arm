#!/usr/bin/python
#*---------------------------------------------------------------
#* sendmail
#* send a mail message
#*---------------------------------------------------------------
import smtplib
import sys
import os
import syslog
import subprocess
from subprocess import PIPE,Popen
from email.mime.text import MIMEText

#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].replace("\n", "")

#*--- Parse arguments 
msg=''
for i, arg in enumerate(sys.argv):
    #print("argument received["+str(i)+"] ->"+arg)
    if i>3:
       msg=msg+" "+arg

#*--- define specific mail sender credentials

userid=getToken("mail")
password=getToken("token")

#*--- define mail receiver and message

userTo=sys.argv[1]
callsign=sys.argv[2]
subj=sys.argv[3]

#*--- send mail

fromx = userid
to  = userTo
msg = MIMEText(msg)
msg['Subject'] = subj
msg['From'] = userid
msg['To'] = userTo

server = smtplib.SMTP('smtp.gmail.com:587')
server.starttls()
server.ehlo()
server.login(userid,password)
server.sendmail(fromx, to, msg.as_string())
server.quit()

print("%s sent mail to(%s) subject(%s)\n" % (sys.argv[0],userTo,subj))
