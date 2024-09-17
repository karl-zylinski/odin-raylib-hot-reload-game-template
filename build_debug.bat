@echo off

set BUILD_PARAMS=-strict-style -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug

odin build main_release -define:RAYLIB_SHARED=false -out:game_debug.exe -subsystem:windows %BUILD_PARAMS%
