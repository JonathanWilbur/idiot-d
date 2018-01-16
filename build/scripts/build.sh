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
VERSION="0.9.0"

if [ "$(uname)" == "Darwin" ]; then
	ECHOFLAGS=""
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	ECHOFLAGS="-e"
fi

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

echo $ECHOFLAGS "Building the Idiot Library (static)... \c"
if dmd \
 ./source/macros.ddoc \
 ./source/idiot.d \
 -Dd./documentation/html \
 -Hd./build/interfaces \
 -od./build/objects \
 -of../libraries/idiot-${VERSION}.a \
 -Xf./documentation/idiot-${VERSION}.json \
 -lib \
 -inline \
 -release \
 -O \
 -map \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

echo $ECHOFLAGS "Building the Idiot Library (shared / dynamic)... \c"
if dmd \
 ./source/idiot.d \
 -of./build/libraries/idiot-${VERSION}.so \
 -od./build/objects \
 -shared \
 -fPIC \
 -inline \
 -release \
 -O \
 -v >> ./build/logs/${TIMESTAMP}.log 2>&1; then
    echo $ECHOFLAGS "${GREEN}Done.${NOCOLOR}"
else
    echo $ECHOFLAGS "${RED}Failed. See ./build/logs.${NOCOLOR}"
fi

mv *.lst ./build/logs 2>/dev/null
mv *.map ./build/maps 2>/dev/null