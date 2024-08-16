@echo off

rem Uncomment these lines if you want to build an atlas from any aseprite files in a `textures` subfolder.
rem Run atlas builder, which outputs atlas.odin and atlas.png
rem odin run atlas_builder -debug
rem IF %ERRORLEVEL% NEQ 0 exit /b 1

odin build main_release -define:RAYLIB_SHARED=false -out:game_debug.exe -subsystem:windows -debug
