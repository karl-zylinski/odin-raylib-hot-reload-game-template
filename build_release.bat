@echo off

rem Uncomment these lines if you want to build an atlas from any aseprite files in a `textures` subfolder.
rem odin build atlas_builder -use-separate-modules -out:atlas_builder.exe -strict-style -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug
rem IF %ERRORLEVEL% NEQ 0 exit /b 1
rem atlas_builder.exe
rem IF %ERRORLEVEL% NEQ 0 exit /b 1

odin build main_release -define:RAYLIB_SHARED=false -out:game_release.exe -no-bounds-check -o:speed -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -subsystem:windows
