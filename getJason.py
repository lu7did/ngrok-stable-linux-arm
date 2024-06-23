#!/usr/bin/python
import json
import sys

jsonfile=sys.argv[1]
jsonkey=sys.argv[2]

# read file
with open(jsonfile, 'r') as myfile:
    data=myfile.read()

# parse file
obj = json.loads(data)

# show values
print(str(obj[jsonkey]))
