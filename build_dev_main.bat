@echo off
odin build main_hot_reload -use-separate-modules -define:RAYLIB_SHARED=true -out:game.exe -strict-style -debug
copy c:\programs\odin\vendor\raylib\windows\raylib.dll .