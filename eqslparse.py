from html.parser import HTMLParser
import sys

bFirst=True 
msg=''

#*-------------------------------------------------------------------------------------
#* removelines, strip \r\n from a string
#*-------------------------------------------------------------------------------------
def removelines(value):
    return value.replace('\n','')


#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].replace("\n", "")

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


#*--- define mail receiver and message

htmlFile=sys.argv[1]
if not htmlFile:
   exit()

parser = MyHTMLParser()

try:
   with open(htmlFile, "r") as f:
        page = f.read()
except FileNotFoundError:
        print("eQSLParse: *ERROR* File("+htmlFile+") not found")
        exit()
else:
        parser.feed(page)

