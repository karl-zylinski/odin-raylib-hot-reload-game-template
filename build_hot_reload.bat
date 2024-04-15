@echo off

rem Build game.dll
odin build . -show-timings -use-separate-modules -define:RAYLIB_SHARED=true -build-mode:dll -out:game.dll -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem If game.exe already running: Then only compile game.dll and exit cleanly
QPROCESS "game.exe">NUL
IF %ERRORLEVEL% EQU 0 exit /b 0

rem build game.exe
odin build main_hot_reload -use-separate-modules -define:RAYLIB_SHARED=true -out:game.exe -strict-style -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem copy raylib.dll from odin folder to here
if not exist "raylib.dll" (
	copy c:\programs\odin\vendor\raylib\windows\raylib.dll .
	IF %ERRORLEVEL% NEQ 0 exit /b 1
)

exit /b 0
