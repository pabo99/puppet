#!/bin/bash

mkdir -p "$1"/{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}{0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f}
chown -R "$2:$3" "$1"
chmod -R "$4" "$1"
