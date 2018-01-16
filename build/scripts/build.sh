#!/bin/sh
#
# NOTE:
# This script assumes that your terminal supports ANSI Escape Codes and colors.
# It should not fail if your terminal does not support it--the output will just
# look a bit garbled.
# 
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NOCOLOR='\033[0m'
TIMESTAMP=$(date '+%Y-%m-%d@%H:%M:%S')

# Unfortunately, because this is running in a shell script, brace expansion
# might not work, so I can't create all the necessary directories "the cool
# way." See this StackOverflow question that addresses my problem:
# https://stackoverflow.com/questions/40164660/bash-brace-expansion-not-working-on-dockerfile-run-command
mkdir -p ./documentation
mkdir -p ./documentation/html
mkdir -p ./documentation/links
mkdir -p ./build
mkdir -p ./build/assemblies
mkdir -p ./build/executables
mkdir -p ./build/interfaces
mkdir -p ./build/libraries
mkdir -p ./build/logs
mkdir -p ./build/maps
mkdir -p ./build/objects
mkdir -p ./build/scripts

echo -n "Building the Idiot Library (static)... "
if dmd \
 ./source/idiot.d \
 -Dd./documentation/html \
 -Hd./build/interfaces \
 -op \
 -of./build/libraries/idiot.lib \
 -Xf./documentation/idiot.json \
 -lib \
 -inline \
 -release \
 -O \
 -map \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo "${GREEN}Done.${NOCOLOR}"
else
    echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

echo -n "Building the Idiot Library (shared / dynamic)... "
if dmd \
 ./source/idiot.d \
 -of./build/libraries/idiot.so \
 -shared \
 -fPIC \
 -inline \
 -release \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo "${GREEN}Done.${NOCOLOR}"
else
    echo "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

# Delete object files that get created.
# Yes, I tried -o- already. It does not create the executable either.
rm -f ./build/executables/*.o
mv *.lst ./build/logs
# mv *.map ./build/maps