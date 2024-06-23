import sys
max=int(sys.argv[1])
ignoreList=sys.argv[2]
iniFile=sys.argv[3]
outFile=sys.argv[4]
blockedList=sys.argv[5]
permIgnoreList=""
print("Processing blockedList(%s)\n\r" % blockedList)
with open(blockedList) as blockfile:
    for line in blockfile:
        line=line.rstrip().lstrip()
        if permIgnoreList != "":
           callsign=(repr("\n")+line).replace("'","")
           permIgnoreList=permIgnoreList+callsign
        else:
           permIgnoreList=line.replace("'","")
print("Processing max(%d) ignoreList(%s) iniFile(%s)\n\r" % (max,ignoreList,iniFile))
with open(ignoreList) as file:
    for line in file:
        line=line.rstrip().lstrip()
        token = line.split(' ')
        count = int(token[0])
        if count >= max:
           if permIgnoreList != "":
              callsign=(repr("\n")+token[1]).replace("'","")
              permIgnoreList=permIgnoreList+callsign
           else:
              permIgnoreList=token[1].replace("'","")
permIgnoreList=permIgnoreList.replace("\n\n","\n")
permIgnoreList="permIgnoreList="+repr(permIgnoreList)+"\n"
print(permIgnoreList+"\n\r")
out = open(outFile, "w")
with open(iniFile, 'r') as file:
   for line in file:
      count += 1
      if (line.find('permIgnoreList') != -1):
         out.write(permIgnoreList.replace("'","").replace("\\\\","\\"))
      else:
         out.write(line)
out.close()
