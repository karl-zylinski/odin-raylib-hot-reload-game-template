@echo off

if "%~1"=="" (
    echo "Please specify the destination folder (release, debug, or dev)."
    exit /b 1
)

rem Set the destination folder based on the first argument
set "destination=./build/%~1"

rem Check if the destination directory exists, if not, create it
if not exist "%destination%" (
    mkdir "%destination%"
)

if not exist "%destination%/res" (
    mkdir "%destination%/res"
)

xcopy /s /e "./res" "%destination%/res" /D /Y