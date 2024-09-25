@echo off

if not exist "build" (
    mkdir build
)

odin build main_release -out:build/game_debug.exe -strict-style -vet -debug
