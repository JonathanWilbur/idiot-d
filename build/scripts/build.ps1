@echo off
mkdir .\documentation 2>&1 | Out-Null
mkdir .\documentation\html 2>&1 | Out-Null
mkdir .\documentation\links 2>&1 | Out-Null
mkdir .\build 2>&1 | Out-Null
mkdir .\build\assemblies 2>&1 | Out-Null
mkdir .\build\executables 2>&1 | Out-Null
mkdir .\build\interfaces 2>&1 | Out-Null
mkdir .\build\libraries 2>&1 | Out-Null
mkdir .\build\logs 2>&1 | Out-Null
mkdir .\build\maps 2>&1 | Out-Null
mkdir .\build\objects 2>&1 | Out-Null
mkdir .\build\scripts 2>&1 | Out-Null

$version = "0.9.0"

Write-Host "Building the Idiot Library (static)... " -NoNewLine
dmd `
.\source\macros.ddoc `
.\source\idiot.d `
-Dd.\documentation\html `
-Hd.\build\interfaces `
-op `
-of..\libraries\idiot-%version%.lib `
-Xf.\documentation\idiot-%version%.json `
-lib `
-O `
-inline `
-release `
-d
Write-Host "Done." -ForegroundColor Green

Write-Host "Building the Idiot Library (shared / dynamic)... " -NoNewLine
dmd `
.\source\idiot.d `
-of.\build\libraries\idiot-%version%.dll `
-lib `
-shared `
-O `
-inline `
-release `
-d
Write-Host "Done." -ForegroundColor Green