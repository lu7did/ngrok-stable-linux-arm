#!/bin/sh
#*--- copy from file1.txt to file2.txt after the line containing xyz
sed '0,/xyz/d' file1.txt >file2.txt
