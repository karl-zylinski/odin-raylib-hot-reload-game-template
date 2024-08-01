#!/usr/bin/env bash

# Uncomment these lines if you want to build an atlas from any aseprite files in a `textures` subfolder.
# odin build atlas_builder -use-separate-modules -out:atlas_builder.bin -strict-style -vet-using-stmt -vet-using-param -vet-semicolon -debug
# if [ ! $? -eq 0 ]; then
#     exit 1
# fi
# ./atlas_builder.bin
# if [ ! $? -eq 0 ]; then
#     exit 1
# fi
# chmod +rw atlas.odin

odin build main_release -out:game_release.bin -no-bounds-check -o:speed -strict-style -vet-unused -vet-using-stmt -vet-using-param -vet-style -vet-semicolon
