@echo off

rem Run atlas builder, which outputs game/atlas.odin and atlas.png
odin run atlas_builder -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

set BUILD_PARAMS=-strict-style -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug

odin build main_release -define:RAYLIB_SHARED=false -out:game_debug.exe -subsystem:windows %BUILD_PARAMS%
