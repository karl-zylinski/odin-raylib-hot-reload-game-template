#!/usr/bin/env bash

odin build main_release -out:game_release.bin -strict-style -vet -no-bounds-check -o:speed
