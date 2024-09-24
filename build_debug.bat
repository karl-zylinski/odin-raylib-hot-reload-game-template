@echo off

odin build main_release -define:RAYLIB_SHARED=false -out:game_debug.exe -subsystem:windows -strict-style -vet -debug
