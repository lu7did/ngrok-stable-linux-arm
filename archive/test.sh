#!/bin/sh
wget -q --output-document - http://localhost:4040/api/tunnels/vnc_tucSPA > test.tmp
cat test.tmp

