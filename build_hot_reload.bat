@echo off

if not exist "./build/dev" (
	mkdir "./build/dev"
)

rem Build game.dll
odin build src/game -show-timings -use-separate-modules -define:RAYLIB_SHARED=true -build-mode:dll -out:build/dev/game.dll -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem If game_hot_reload.exe already running: Then only compile game.dll and exit cleanly
QPROCESS "game_hot_reload.exe">NUL
IF %ERRORLEVEL% EQU 0 exit /b 1

rem build game_hot_reload.exe
odin build src/main_hot_reload -use-separate-modules -out:build/dev/game_hot_reload.exe -strict-style -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem copy raylib.dll from odin folder to here
if not exist "build/dev/raylib.dll" (
	echo "Please copy raylib.dll from <your_odin_compiler>/vendor/raylib/windows/raylib.dll to the same directory as game_hot_reload.exe"
	exit /b 1
)

exit /b 0
