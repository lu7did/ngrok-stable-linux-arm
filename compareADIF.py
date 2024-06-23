
#!/usr/bin/python
#*--------------------------------------------------------------------------------------------------*
#* compareADIF.py
#* Compare a {new} ADIF file against an {old} ADIF file and list the records not present in the old
#*--------------------------------------------------------------------------------------------------*
import sys
import syslog
#*--------------------------------------------------------------------------------------------------*
#* this procedure has been written by chatGPT
#* Read two files, a new and an old one. Return all records in the new which aren't on the old
#*--------------------------------------------------------------------------------------------------*
def leerArchivos(new, old):
  nuevo = set()
  viejo = set()
  with open(new,encoding="ISO-8859-1") as f:
    for line in f:
      nuevo.add(line)
  with open(old,encoding="ISO-8859-1") as f:
    for line in f:
      viejo.add(line)
  return nuevo - viejo

#*---------------------------------------------------*
#* Process arguments and format the query to qrz.com *
#*---------------------------------------------------*
if len(sys.argv) < 3:
   print("%s: No ADIF file to process, terminating!\n" % pgm)
   sys.exit()

newFile= sys.argv[1]     # First argument is the adifFile to process
oldFile=sys.argv[2]
#*---------------------------------------------------*
#* Access the ADIF file and extract  pseudo XML data *
#*-------------------------------------------------- *
registros = leerArchivos(newFile, oldFile)

for adifRecord in registros:
  #adifRecord.encode('utf-8').strip()
  #adifStr=str(adifRecord, 'UTF-8')
  print(adifRecord.replace('\n', '').replace('\d',''))

sys.exit()





