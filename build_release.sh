#!/usr/bin/env bash

odin build main_release -out:build/game_release.bin -strict-style -vet -no-bounds-check -o:speed
