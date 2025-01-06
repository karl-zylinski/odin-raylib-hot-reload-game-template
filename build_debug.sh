#!/usr/bin/env bash

OUT_DIR="build/debug"
mkdir -p "$OUT_DIR"
odin build source/main_release -out:$OUT_DIR/game_debug.bin -strict-style -vet -debug
cp -R assets $OUT_DIR
