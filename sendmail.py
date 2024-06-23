
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
from pathlib import Path
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate
from email import encoders


#*-------------------------------------------------------------------------------------
#* Send a mail using SMTP with attachments
#*-------------------------------------------------------------------------------------
def send_mail(send_from, send_to, subject, message, files,server, port, username, password,use_tls):

#    Compose and send email with provided info and attachments.
#
#    Args:
#        send_from (str): from name
#        send_to (list[str]): to name(s)
#        subject (str): message title
#        message (str): message body
#        files (list[str]): list of file paths to be attached to email
#        server (str): mail server host name
#        port (int): port number
#        username (str): server auth username
#        password (str): server auth password
#        use_tls (bool): use TLS mode
	msg = MIMEMultipart()
	msg['From'] = send_from
	msg['To'] = send_to
	msg['Date'] = formatdate(localtime=True)
	msg['Subject'] = subject

	msg.attach(MIMEText(message))

	for path in files:
		part = MIMEBase('application', "octet-stream")
		with open(path, 'rb') as file:
			part.set_payload(file.read())
			encoders.encode_base64(part)
			part.add_header('Content-Disposition','attachment; filename={}'.format(Path(path).name))
			msg.attach(part)


	smtp = smtplib.SMTP(server, port)
	if use_tls:
		smtp.starttls()
	smtp.login(username, password)
	smtp.sendmail(send_from, send_to, msg.as_string())
	smtp.quit()

#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
	t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
	return t.communicate()[0].replace("\n", "")


#*--- define specific mail sender credentials
#password="vgoj oifr gdpe lnzb"
#sender_email="pedro.colla@gmail.com"
#site="aBrown"

sender_email=getToken("mail")
password=getToken("token")
site=getToken("site")

#*--- define mail receiver and message

receiver_email=sys.argv[1]
subject=sys.argv[2]
message=sys.argv[3]
filename=sys.argv[4]

n = len(sys.argv)
messageFile=False
if n>5:
	arg=(sys.argv[5]).upper()
	if arg == '-F':
		messageFile=True


server="smtp.gmail.com"
port=587
username=sender_email


# Create a multipart message and set headers
if not filename:
	pdfFile=[]
else:
	pdfFile=[filename]

if messageFile == True:
# The file is read and its data is stored
	fileName=message
	message = open(fileName, 'r').read()

send_mail(sender_email, receiver_email, subject, message, pdfFile, server, port, username, password, True)


