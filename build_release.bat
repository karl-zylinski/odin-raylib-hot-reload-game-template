@echo off

if not exist "./build/release" (
	mkdir "./build/release"
)

odin build src/main_release -define:RAYLIB_SHARED=false -out:build/release/game.exe -no-bounds-check -o:speed -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -subsystem:windows