@echo off

QPROCESS "game.exe">NUL
IF %ERRORLEVEL% EQU 0 build_game && exit

build_game && build_dev_main
