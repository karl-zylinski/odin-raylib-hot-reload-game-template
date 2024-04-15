@echo off
odin build main_release -define:RAYLIB_SHARED=false -out:game_debug.exe -no-bounds-check -subsystem:windows -debug
