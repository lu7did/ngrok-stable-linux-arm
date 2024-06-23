#!/usr/bin/python
import json
import sys

jsonfile=sys.argv[1]

# read file
with open(jsonfile, 'r') as myfile:
    data=myfile.read()

# parse file
obj = json.loads(data)

# show values
#print(str(obj[tunnels.[0].public_url]))
print (str(obj['public_url']))
