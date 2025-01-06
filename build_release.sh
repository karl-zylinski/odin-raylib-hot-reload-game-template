#!/usr/bin/env bash

OUT_DIR="build/release"
mkdir -p "$OUT_DIR"
odin build source/main_release -out:$OUT_DIR/game_release.bin -strict-style -vet -no-bounds-check -o:speed
cp -R assets $OUT_DIR
echo "Release build created in $OUT_DIR"