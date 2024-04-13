@echo off

rem If game.exe already running: Then only compile game.dll so game can hot reload.
QPROCESS "game.exe">NUL
IF %ERRORLEVEL% EQU 0 build_game && exit

build_game && build_dev_main
