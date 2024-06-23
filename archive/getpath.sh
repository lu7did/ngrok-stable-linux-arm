#!/bin/sh

CURR=$(pwd)
PWD=$(dirname $0)
echo "Executing from path $PWD"
chdir $PWD
cd $CURR
echo "returning to $(pwd)"
