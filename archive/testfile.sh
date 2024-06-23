#!/bin/sh

EXT="lck"
SCAN=$(ls -la *.$EXT 2> /dev/null | wc -l)
echo "Number of files ($SCAN)"
if [ "$SCAN" = "0" ]; then
   echo "No hay archivos"
else
   echo "hay $SCAN archivos"
fi
