@echo off

odin build main_release -strict-style -vet -define:RAYLIB_SHARED=false -out:game_release.exe -no-bounds-check -o:speed -subsystem:windows
