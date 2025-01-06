@echo off

:: This creates a build that is similar to a release build, but it's debuggable.
:: There is no hot reloading and no separate game library.

set OUT_DIR=build\debug

if not exist %OUT_DIR% mkdir %OUT_DIR%

odin build source\main_release -out:%OUT_DIR%\game_debug.exe -strict-style -vet -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Debug build created in %OUT_DIR%