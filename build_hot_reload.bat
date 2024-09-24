@echo off

set BUILD_PARAMS=-strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug

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
if exist "raylib.dll" (
	exit /b 0
)

rem Don't name this one ODIN_ROOT as the odin exe will start using that one then.
set "ODIN_PATH="

for /f "delims=" %%i in ('odin root') do (
    set "ODIN_PATH=%%i"
)

if exist "%ODIN_PATH%vendor\raylib\windows\raylib.dll" (
	echo raylib.dll not found in current directory. Copying from %ODIN_PATH%vendor\raylib\windows\raylib.dll
	copy "%ODIN_PATH%vendor\raylib\windows\raylib.dll" .
	exit /b 0
)

echo "Please copy raylib.dll from <your_odin_compiler>/vendor/raylib/windows/raylib.dll to the same directory as game.exe"
exit /b 1