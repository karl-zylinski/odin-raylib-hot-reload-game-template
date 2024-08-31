@echo off

set BUILD_PARAMS=-strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon

rem Run atlas builder, which outputs game/atlas.odin and atlas.png
odin run atlas_builder %BUILD_PARAMS%
IF %ERRORLEVEL% NEQ 0 exit /b 1

odin build main_release -define:RAYLIB_SHARED=false -out:game_release.exe -no-bounds-check -o:speed %BUILD_PARAMS% -subsystem:windows
