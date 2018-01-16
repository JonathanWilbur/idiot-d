@echo off
mkdir .\documentation > nul 2>&1
mkdir .\documentation\html > nul 2>&1
mkdir .\documentation\links > nul 2>&1
mkdir .\build > nul 2>&1
mkdir .\build\assemblies > nul 2>&1
mkdir .\build\executables > nul 2>&1
mkdir .\build\interfaces > nul 2>&1
mkdir .\build\libraries > nul 2>&1
mkdir .\build\logs > nul 2>&1
mkdir .\build\maps > nul 2>&1
mkdir .\build\objects > nul 2>&1
mkdir .\build\scripts > nul 2>&1

set version="0.9.0"

echo|set /p="Building the Idiot Library (static)... "
dmd ^
.\source\macros.ddoc ^
.\source\idiot.d ^
-Dd.\documentation\html ^
-Hd.\build\interfaces ^
-op ^
-of..\libraries\idiot-%version%.lib ^
-Xf.\documentation\idiot-%version%.json ^
-lib ^
-O ^
-inline ^
-release ^
-d
echo Done.

echo|set /p="Building the Idiot Library (shared / dynamic)... "
dmd ^
.\source\idiot.d ^
-of.\build\libraries\idiot-%version%.dll ^
-lib ^
-shared ^
-O ^
-inline ^
-release ^
-d
echo Done.