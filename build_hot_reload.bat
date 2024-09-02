@echo off

set BUILD_PARAMS=-strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug

rem Run atlas builder, which outputs game/atlas.odin and atlas.png
rem odin run atlas_builder %BUILD_PARAMS%
rem IF %ERRORLEVEL% NEQ 0 exit /b 1

rem Build game.dll, which is loaded by game.exe. The split of game.dll and game.exe is for hot reload reasons.
odin build game -show-timings -define:RAYLIB_SHARED=true -build-mode:dll -out:game.dll %BUILD_PARAMS%
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem If game.exe already running: Then only compile game.dll and exit cleanly
set EXE=game.exe
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% exit /b 1

rem Build game.exe, which starts the program and loads game.dll och does the logic for hot reloading.
odin build main_hot_reload -out:game.exe %BUILD_PARAMS%
IF %ERRORLEVEL% NEQ 0 exit /b 1

rem Warning about raylib DLL not existing and where to find it.
if not exist "raylib.dll" (
	echo "Please copy raylib.dll from <your_odin_compiler>/vendor/raylib/windows/raylib.dll to the same directory as game.exe"
	exit /b 1
)

exit /b 0
