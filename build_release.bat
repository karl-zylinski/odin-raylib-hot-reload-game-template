@echo off

set OUT_DIR=build\release

if not exist %OUT_DIR% mkdir %OUT_DIR%

odin build main_release -out:%OUT_DIR%\game_release.exe -strict-style -vet -no-bounds-check -o:speed -subsystem:windows
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets
IF %ERRORLEVEL% NEQ 0 exit /b 1
