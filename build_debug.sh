#!/usr/bin/env bash

mkdir -p build

odin build main_release -out:build/game_debug.bin -strict-style -vet -debug
