@echo off

set BUILD_PARAMS=-strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon

rem Uncomment these lines if you want to build an atlas from any aseprite files in a `textures` subfolder.
rem Run atlas builder, which outputs atlas.odin and atlas.png
rem odin run atlas_builder %BUILD_PARAMS%
rem IF %ERRORLEVEL% NEQ 0 exit /b 1

odin build main_release -define:RAYLIB_SHARED=false -out:game_release.exe -no-bounds-check -o:speed %BUILD_PARAMS% -subsystem:windows
