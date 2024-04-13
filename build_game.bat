@echo off

odin build . -show-timings -use-separate-modules -define:RAYLIB_SHARED=true -build-mode:dll -out:game.dll -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon -debug