from subprocess import PIPE,Popen
#*-------------------------------------------------------------------------------------
#* getToken from sitedata JSON 
#*-------------------------------------------------------------------------------------
def getToken(token):
  t = Popen(['python', 'getJason.py','sitedata.json',token],stdout=PIPE)
  return t.communicate()[0].replace("\n", "")

print(getToken("mail"))
print(getToken("token"))
print(getToken("site"))
