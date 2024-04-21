@echo off

if not exist "./build/debug" (
	mkdir "./build/debug"
)

odin build src/main_release -define:RAYLIB_SHARED=false -out:build/debug/game.exe -no-bounds-check -subsystem:windows -debug
